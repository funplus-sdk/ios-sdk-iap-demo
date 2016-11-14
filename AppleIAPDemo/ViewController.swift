//
//  ViewController.swift
//  HelloAppleIAP
//
//  Created by Yuankun Zhang on 6/22/16.
//  Copyright © 2016 funplus. All rights reserved.
//

import UIKit
import StoreKit
import FunPlusAppleIAP

class ViewController: UIViewController {
    
    let VALID_PRODUCT_ID1   = "com.funplus.sdk.product1"    // consumable
    let VALID_PRODUCT_ID2   = "com.funplus.sdk.product3"    // non-consumable
    let INVALID_PRODUCT_ID1 = "com.funplus.sdk.invalidproduct1"
    let INVALID_PRODUCT_ID2 = "com.funplus.sdk.invalidproduct2"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getProductInfo1() {
        queryProductInfo([VALID_PRODUCT_ID1])
    }
    
    @IBAction func getProductInfo2() {
        queryProductInfo([VALID_PRODUCT_ID2])
    }
    
    @IBAction func purchaseProduct1() {
        purchaseProduct(VALID_PRODUCT_ID1)
    }
    
    @IBAction func purchaseProduct2() {
        purchaseProduct(VALID_PRODUCT_ID2)
    } 
    
    @IBAction func purchaseInvalidProduct() {
        purchaseProduct(INVALID_PRODUCT_ID1)
    }
    
    @IBAction func verifyPurchase1() {
        verifyPurchase(VALID_PRODUCT_ID1)
    }
    
    @IBAction func verifyPurchase2() {
        verifyPurchase(VALID_PRODUCT_ID2)
    }
    
    @IBAction func verifyReceipt() {
        NetworkActivityIndicatorManager.networkOperationStarted()
        
        FunPlusAppleIAP.verifyReceipt(receiptVerifyURL: .SandboxURL) { result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            self.alertForVerifyReceipt(result)
        }
    }
    
    @IBAction func restoreTransactions() {
        NetworkActivityIndicatorManager.networkOperationStarted()
        FunPlusAppleIAP.restoreCompletedTransactions { (result) in
            NetworkActivityIndicatorManager.networkOperationFinished()
            self.showAlert(self.alertForRestorePurchases(result))
        }
    }

    func queryProductInfo(_ productIdentifiers: [String]) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        
        FunPlusAppleIAP.queryProducts(productIdentifiers) { (result) in
            NetworkActivityIndicatorManager.networkOperationFinished()
            self.showAlert(self.alertForProductInfo(result))
        }
    }
    
    func purchaseProduct(_ productIdentifier: String) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        
        FunPlusAppleIAP.purchaseProduct(productIdentifier) { (result) in
            NetworkActivityIndicatorManager.networkOperationFinished()
            print(result)
//            self.showAlert(self.alertForPurchaseResult(result))
        }
    }
    
    func verifyPurchase(_ productIdentifier: String) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        
        FunPlusAppleIAP.verifyReceipt(receiptVerifyURL: .SandboxURL) { result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            switch result {
            case .success(let receipt):
                let purchaseResult = FunPlusAppleIAP.verifyPurchase(productIdentifer: productIdentifier, inReceipt: receipt)
                self.showAlert(self.alertForVerifyPurchase(purchaseResult))
                
            case .failed(let error):
                self.showAlert(self.alertForVerifyReceipt(result))
                if case .noReceiptData = error {
                    self.refreshReceipt()
                }
            }
        }
    }
    
    func refreshReceipt() {
        NetworkActivityIndicatorManager.networkOperationStarted()
        
        FunPlusAppleIAP.refreshReceipt().complete() { result in
            self.alertForRefreshReceipt(result)
        }
    }
}

extension ViewController {
    
    func showAlert(_ alert: UIAlertController) {
        guard let _ = self.presentedViewController else {
            self.present(alert, animated: true, completion: nil)
            return
        }
    }

    func alertWithTitle(_ title: String, message: String) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        return alert
    }
    
    func alertForProductInfo(_ result: ProductQueryResult) -> UIAlertController {
        switch result {
        case .success(let products, let invalidProductIdentifiers):
            if let product = products.first {
                let priceString = NumberFormatter.localizedString(from: product.price, number: .currencyISOCode)
                return alertWithTitle(product.localizedTitle, message: "\(product.localizedDescription) - \(priceString)")
            }
            else if let invalidProductId = invalidProductIdentifiers.first {
                return alertWithTitle("Could not retrieve product info", message: "Invalid product identifier: \(invalidProductId)")
            }
            else {
                return alertWithTitle("Unknown error", message: "Unknown error")
            }
        case .failed(let error):
            return alertWithTitle("Could not retrieve product info", message: "\(error)")
        }
    }
    
    func alertForPurchaseResult(_ result: ProductPurchaseResult) -> UIAlertController {
        switch result {
        case .success(let transaction):
            print("Purchase success: \(transaction.payment.productIdentifier)")
            return alertWithTitle("Thank You", message: "Purchase completed")
        case .failed(let error):
            print("Purchase failed: \(error)")
            switch error {
            case .unknownFatalError:
                return alertWithTitle("Purchase failed", message: "Unknown error. Please contact support")
            case .paymentNotAllowed:
                return alertWithTitle("Payments not enabled", message: "You are not allowed to make payments")
            case .emptyProductIdentifier:
                return alertWithTitle("Purchase failed", message: "Empty product identifier")
            case .invalidProductIdentifier:
                return alertWithTitle("Purchase failed", message: "Invalid product identifier")
            case .productQueryFailed:
                return alertWithTitle("Purchase failed", message: "Failed to query product information")
            case .purchaseError(let error):
                return alertWithTitle("Purchase failed", message: "\(error)")
            }
        }
    }
    
    func alertForRestorePurchases(_ result: TransactionRestoreResult) -> UIAlertController {
        switch result {
        case .success(let transactions):
            if transactions.count > 0 {
                return alertWithTitle("Purchases restored", message: "\(transactions)")
            } else {
                return alertWithTitle("Nothing to restore", message: "No previous non-consumable purchases found")
            }
        case .failed(let error):
            return alertWithTitle("Restore failed", message: "\(error)")
        }
    }
    
    func alertForVerifyReceipt(_ result: ReceiptVerifyResult) -> UIAlertController {
        
        switch result {
        case .success(let receipt):
            print("Verify receipt Success: \(receipt)")
            return alertWithTitle("Receipt verified", message: "Receipt verified remotly")
        case .failed(let error):
            print("Verify receipt Failed: \(error)")
            switch (error) {
            case .noReceiptData :
                return alertWithTitle("Receipt verification", message: "No receipt data, application will try to get a new one. Try again.")
            default:
                return alertWithTitle("Receipt verification", message: "Receipt verification failed")
            }
        }
    }
    
    func alertForVerifyPurchase(_ result: PurchaseVerifyResult) -> UIAlertController {
        switch result {
        case .purchased:
            print("Product is purchased")
            return alertWithTitle("Product is purchased", message: "Product will not expire")
        case .notPurchased:
            print("This product has never been purchased")
            return alertWithTitle("Not purchased", message: "This product has never been purchased")
        }
    }
    
    func alertForRefreshReceipt(_ result: ReceiptRefreshResult) -> UIAlertController {
        switch result {
        case .success:
            print("Receipt refresh Success")
            return self.alertWithTitle("Receipt refreshed", message: "Receipt refreshed successfully")
        case .failed(let error):
            print("Receipt refresh Failed: \(error)")
            return self.alertWithTitle("Receipt refresh failed", message: "Receipt refresh failed")
        }
    }
}
