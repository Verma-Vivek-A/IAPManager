//
//  IAPConstants.swift
//  IAPHelper
//
//  Created by PC on 30/09/24.
//

import StoreKit

enum IAPProduct: String, CaseIterable {
    case sixtyUC = "com.60unknowncash"
    case limited360UC = "com.limited360unknowncash"
    case monthly = "com.monthlysubscription"
    case yearly = "com.yearlysubscription"
}

enum IAPError: Error {
    case disabled
    case failed
    case error(String)
    
    var localizedDescription: String {
        switch self {
        case .disabled:
            return "Purchases are disabled in your device!"
        case .failed:
            return "Could not complete purchase process.\nPlease try again."
        case .error(let string):
            return string
        }
    }
}

protocol IAPManagerProtocol {
    func didRestored()
    func didFetched(all products: [SKProduct])
    func didPurchased(with productId: String)
    func didFailed(with error: Error)
}
