//
//  IAPReceiptValidator.swift
//  IAPHelper
//
//  Created by PC on 27/09/24.
//

import Foundation

protocol IAPReceiptDelegate {
    func didValidate(for latestReceipt: NSDictionary)
    func didFailed(with error: Error)
}

final class IAPReceiptValidator {
    
    enum ReceiptError: Error {
        case noData
        case invalidUrl
        case httpResponse
        case badResponse(Int)
        case invalidStatus(Int)
        case error(Error)
    }
    
    var delegate: IAPReceiptDelegate?
    
    public enum ReceiptStatus: Int {
        // Not decodable status
        case unknown = -2
        // No status returned
        case none = -1
        // valid statu
        case valid = 0
        // The App Store could not read the JSON object you provided.
        case jsonNotReadable = 21000
        // The data in the receipt-data property was malformed or missing.
        case malformedOrMissingData = 21002
        // The receipt could not be authenticated.
        case receiptCouldNotBeAuthenticated = 21003
        // The shared secret you provided does not match the shared secret on file for your account.
        case secretNotMatching = 21004
        // The receipt server is not currently available.
        case receiptServerUnavailable = 21005
        // This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response.
        case subscriptionExpired = 21006
        //  This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
        case testReceipt = 21007
        // This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.
        case productionEnvironment = 21008

        var isValid: Bool { return self == .valid}
    }
    
    private func getReceiptInformation() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return nil }
        do {
            let receiptData = try Data(contentsOf: receiptURL, options: .alwaysMapped)
            let receiptString = receiptData.base64EncodedString(options: [])
            return receiptString
        } catch let error {
            self.delegate?.didFailed(with: error)
        }
        return nil
    }
    
    func validateReceipt() {
        guard let receiptString = self.getReceiptInformation() else { return }
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return }
        
        guard let password = ProcessInfo.processInfo.environment["SHARED_SECRET"] else { return }
        let appleServer = receiptURL.lastPathComponent == "sandboxReceipt" ? "sandbox" : "buy"
        let urlString = "https://\(appleServer).itunes.apple.com/verifyReceipt"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = ["receipt-data": receiptString, "password": password, "exclude-old-transactions": true]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else { return }
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.delegate?.didFailed(with: error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.delegate?.didFailed(with: ReceiptError.httpResponse)
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                self.delegate?.didFailed(with: ReceiptError.badResponse(httpResponse.statusCode))
                return
            }
            
            guard let data = data else {
                self.delegate?.didFailed(with: ReceiptError.noData)
                return
            }
            
            do {
                let appReceiptJSON = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                
                guard let status = appReceiptJSON["status"] as? Int else { return }
                let receiptStatus = ReceiptStatus(rawValue: status) ?? ReceiptStatus.unknown
                
                guard receiptStatus.isValid else {
                    self.delegate?.didFailed(with: ReceiptError.invalidStatus(receiptStatus.rawValue))
                    return
                }
                  
                if let receiptInfo: NSArray = appReceiptJSON["latest_receipt_info"] as? NSArray,
                   let lastReceipt = receiptInfo.lastObject as? NSDictionary {
                    self.delegate?.didValidate(for: lastReceipt)
                }
            } catch let error {
                self.delegate?.didFailed(with: error)
            }
        }
        task.resume()
    }
    
}
