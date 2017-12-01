//
//  Global.swift
//  CurrencyConverter
//
//  Created by Ghouse Basha Shaik on 30/11/17.
//

import Foundation
import UIKit

class Global: NSObject {
    class  func showAlertWithTitle(_ title: String?,okTitle: String?, cancelTitle: String?, message: String,isCancel:Bool, okHandler:((UIAlertAction) -> Void)?)  -> UIAlertController  {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: okTitle, style: .default) { (action) in
            okHandler!(action)
        }
        if isCancel {
            let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { (action) in
                return
            }
            alertController.addAction(cancelAction)
        }
        alertController.addAction(OKAction)
        return alertController
    }
}
