//
//  IAPManager.swift
//  IAPHelper
//
//  Created by PC on 27/09/24.
//

import StoreKit

final class IAPManager: NSObject {
    
    static let shared = IAPManager()
    
    private var iapProducts = [SKProduct]()
    private var pendingFetchProduct: String!
    private var productsRequest = SKProductsRequest()
    
    private let receiptValidator = IAPReceiptValidator()
    
    var delegate: IAPManagerProtocol?
            
    private override init() {
        super.init()
        self.initialize()
        self.receiptValidator.delegate = self
    }
    
    private func initialize() {
        self.fetchAvailableProducts()
    }
    
    private func fetchAvailableProducts(){
        self.productsRequest.cancel()
        let productIdentifiers = Set(IAPProduct.allCases.map{ $0.rawValue })
        
        self.productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        self.productsRequest.delegate = self
        self.productsRequest.start()
    }
    
    private func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
 
    func purchaseProduct(productIdentifier: String) {
        if self.iapProducts.isEmpty {
            self.pendingFetchProduct = productIdentifier
            self.fetchAvailableProducts()
            return
        }
        
        if self.canMakePurchases() {
            for product in self.iapProducts {
                if product.productIdentifier == productIdentifier {
                    let payment = SKPayment(product: product)
                    SKPaymentQueue.default().add(self)
                    SKPaymentQueue.default().add(payment)
                    return
                }
            }
        } else {
            self.delegate?.didFailed(with: IAPError.disabled)
        }
    }
    
    func restorePurchase(){
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
}

extension IAPManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request:SKProductsRequest, didReceive response:SKProductsResponse) {
        if response.products.count > 0 {
            self.iapProducts = response.products
            self.delegate?.didFetched(all: response.products)
            
            if let product = self.pendingFetchProduct {
                self.purchaseProduct(productIdentifier: product)
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.delegate?.didFailed(with: error)
    }
    
}

extension IAPManager: SKPaymentTransactionObserver {
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        self.delegate?.didRestored()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        self.didFailed(with: error)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    if let transaction = transaction as? SKPaymentTransaction {
                        SKPaymentQueue.default().finishTransaction(transaction)
                        self.delegate?.didPurchased(with: transaction.payment.productIdentifier)
                        self.receiptValidator.validateReceipt()
                    }
                case .failed:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    self.delegate?.didFailed(with: IAPError.failed)
                case .restored:
                    if let transaction = transaction as? SKPaymentTransaction {
                        SKPaymentQueue.default().finishTransaction(transaction)
                    }
                default: break
                }
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            return true
        } else {
            return false
        }
    }
    
}

extension IAPManager: IAPReceiptDelegate {
    
    func didValidate(for latestReceipt: NSDictionary) {
        print(latestReceipt)
    }
    
    func didFailed(with error: any Error) {
        self.delegate?.didFailed(with: IAPError.error("Receipt validation failed with: \(error)"))
    }
   
}
