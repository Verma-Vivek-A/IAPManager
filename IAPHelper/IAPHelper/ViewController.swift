//
//  ViewController.swift
//  IAPHelper
//
//  Created by PC on 27/09/24.
//

import UIKit
import StoreKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IAPManager.shared.delegate = self
    }
    
    @IBAction func purchase60UC(_ sender: Any) {
        IAPManager.shared.purchaseProduct(productIdentifier: IAPProduct.sixtyUC.rawValue)
    }

    @IBAction func limited360UC(_ sender: Any) {
        IAPManager.shared.purchaseProduct(productIdentifier: IAPProduct.limited360UC.rawValue)
    }
    
    @IBAction func monthly(_ sender: Any) {
        IAPManager.shared.purchaseProduct(productIdentifier: IAPProduct.monthly.rawValue)
    }
    
    @IBAction func yearly(_ sender: Any) {
        IAPManager.shared.purchaseProduct(productIdentifier: IAPProduct.yearly.rawValue)
    }
    
}
 
extension ViewController: IAPManagerProtocol {
 
    func didRestored() {
        print("Restored")
    }
    
    func didFetched(all products: [SKProduct]) {
        print(products)
    }
    
    func didPurchased(with productId: String) {
        print(productId)
    }
    
    func didFailed(with error: any Error) {
        print(error.localizedDescription)
    }
    
}
