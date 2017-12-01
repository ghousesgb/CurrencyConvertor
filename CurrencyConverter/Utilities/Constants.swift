//
//  Constants.swift
//  CurrencyConverter
//
//  Created by Ghouse Basha Shaik on 30/11/17.
//

import Foundation

#if RELEASE
    let BASE_URL =  "http://api.evp.lt/currency/commercial/exchange/"
#else
    let BASE_URL =  "http://api.evp.lt/currency/commercial/exchange/"
#endif

let NO_INTERNET_CONNECTION = "Please check your device settings to ensure you have a working internet connection."
