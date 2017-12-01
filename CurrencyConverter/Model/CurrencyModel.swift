//
//  CurrencyModel.swift
//  CurrencyConverter
//
//  Created by Ghouse Basha Shaik on 30/11/17.
//

import Foundation
import UIKit

class  CurrencyModel: NSObject, NSCoding {
    var currencyName : String
    var currencyAmt  : Float
    
    init(currencyName: String, currencyAmt: Float) {
        self.currencyName = currencyName
        self.currencyAmt  = currencyAmt
    }
    
    required init?(coder decoder: NSCoder) {
        self.currencyName      =  decoder.decodeObject(forKey: "currencyName") as? String ?? ""
        self.currencyAmt       =  decoder.decodeFloat(forKey: "currencyAmt")
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(currencyName, forKey: "currencyName")
        coder.encode(currencyAmt,  forKey: "currencyAmt")
    }
}
