//
//  NetworkManager.swift
//  CurrencyConverter
//
//  Created by Ghouse Basha Shaik on 30/11/17.
//

import Foundation
import MBProgressHUD
import ReachabilitySwift
import SystemConfiguration


class WebServices {
    
    static let sharedInstance = WebServices()
    
    func performApiCallWithURLString(_ urlString: String, methodName method: String, headers: [String : AnyObject]?, parameters: AnyObject?, httpBody: Data?, withMessage message: String?, alertMessage: String?, fromView: UIView?, successHandler:@escaping (AnyObject?, HTTPURLResponse?) -> Void, failureHandler:@escaping (HTTPURLResponse?, Error?) -> Void) {
        
        if !isInternetAvailable() {
            DispatchQueue.main.async {
                if let view = fromView {
                    WebServices.sharedInstance.hideProgressHUD(for: view)
                }
            }
            WebServices.sharedInstance.showAlertMessageWithNoInternetWithMessage(message: NO_INTERNET_CONNECTION, viewController: UIApplication.topViewController())
            successHandler(nil, nil)
            return
        }
        
        if let message = message, let view = fromView, message.characters.count > 1 {
            showProgressHUDWithStatus(message, fromView: view)
        }
        //        let config = URLSessionConfiguration.default
        let config = URLSessionConfiguration.ephemeral
        if let headers = headers {
            config.httpAdditionalHeaders = headers
        }
        let session = URLSession(configuration: config)
        var url: NSURL?
        url = NSURL(string: urlString)
        let request = NSMutableURLRequest(url: url! as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60.0)
        request.httpMethod = method
        if let httpBody = httpBody {
            request.httpBody = httpBody as Data//httpBody.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        if let parameters = parameters {
            do {
                let json = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                request.httpBody = json
            } catch {
                
            }
        }
        
        session.dataTask(with: request as URLRequest, completionHandler: {
            ( data, response, error) in
            DispatchQueue.main.async {
                if let view = fromView {
                    WebServices.sharedInstance.hideProgressHUD(for: view)
                }
                if let alertBody = error?.localizedDescription{
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NoInternet"), object: alertBody)
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    guard error == nil else {
                        failureHandler(httpResponse, error)
                        return
                    }
                    if let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                            successHandler(json as AnyObject?, httpResponse)
                        } catch let error as NSError  {
                            failureHandler(httpResponse, error)
                        }
                    } else {
                        failureHandler(httpResponse, error)
                    }
                }
            }
        }).resume()
    }
    
    //helper method to check for network reachabilty.
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    func checkForReachability() -> Bool {
        var isReachable: Bool = false
        var value : String?
        let reachability = Reachability()
        value = reachability?.currentReachabilityStatus.description ?? "nil"
        if value == "No Connection" {
            isReachable = false
        } else {
            isReachable = true
        }
        return isReachable
    }
    
    func makeAPICall(url : String, httpBody: Data?, completion: @escaping (String)->())  {
        var config                              :URLSessionConfiguration!
        var urlSession                          :URLSession!
        
        config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config)
        
        let HTTPHeaderField_ContentType         = "Content-Type"
        let ContentType_ApplicationJson         = "application/json"
        let HTTPMethod_Get                      = "POST"
        
        let callURL = URL.init(string: url)
        var request = URLRequest.init(url: callURL!)
        request.timeoutInterval = 60.0 // TimeoutInterval in Second
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        request.addValue(ContentType_ApplicationJson, forHTTPHeaderField: HTTPHeaderField_ContentType)
        request.httpMethod = HTTPMethod_Get
        if let httpBody = httpBody {
            request.httpBody = httpBody as Data//httpBody.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        let dataTask = urlSession.dataTask(with: request) { (data,response,error) in
            if error != nil{
                return
            }
            if let datastring = String(data: data!, encoding: String.Encoding.utf8) {
                
                var newString = datastring.replacingOccurrences(of: "\"", with: "")
                newString = datastring.replacingOccurrences(of: "\\", with: "\"")
                completion(newString)
            }
        }
        dataTask.resume()
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    //MARK: - Global Functions - MBProgressHUD
    func showProgressHUDWithStatus(_ status: String, fromView view: UIView) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        
        hud.label.text = status
        hud.bezelView.color = UIColor.black.withAlphaComponent(0.5)
        // Change the background view style and color.
        //hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.1)
    }
    
    func hideProgressHUD(for view: UIView) {
        MBProgressHUD.hide(for: view, animated: true)
    }
    
    func showAlertMessageWithNoInternetWithMessage(message : String, viewController : UIViewController?) {
        if viewController?.presentedViewController == nil {
            let alert = Global.showAlertWithTitle("Internet Unavailable", okTitle: "OK", cancelTitle: nil, message: message, isCancel: false, okHandler: { (UIAlertAction) in
                
            })
            viewController?.present(alert, animated: true, completion:nil)
        }
    }
}
