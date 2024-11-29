//
//  SKProduct+Extension.swift
//  IAPHelper
//
//  Created by PC on 30/09/24.
//

import StoreKit

extension SKProduct {
    var localizedCurrencyPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)!
    }
}
