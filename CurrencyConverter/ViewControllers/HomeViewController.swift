//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Ghouse Basha Shaik on 29/11/17.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var fromDropDown: UIButton!
    @IBOutlet weak var toDropDown: UIButton!
    @IBOutlet weak var fromTextField: UITextField!
    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var currencyNamePickerView: UIPickerView!
    
    var summaryDictionary = [CurrencyModel]()
    var currencyKeys = [String]()
    var buttonActionString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let summaryDict = UserDefaults.standard.data(forKey: "SUMMARY_CONVERSION") {
            summaryDictionary = (NSKeyedUnarchiver.unarchiveObject(with: summaryDict) as? [CurrencyModel])!
        }else {
            
            summaryDictionary = [CurrencyModel(currencyName: "EUR", currencyAmt: 1000.00),
                                 CurrencyModel(currencyName: "USD", currencyAmt:  0.00),
                                 CurrencyModel(currencyName: "JPY", currencyAmt:  0.00),
                                 CurrencyModel(currencyName: "Commission", currencyAmt:  0.00)]
            let encodedData = NSKeyedArchiver.archivedData(withRootObject: summaryDictionary)
            UserDefaults.standard.set(encodedData, forKey: "SUMMARY_CONVERSION")
            UserDefaults.standard.set(0, forKey: "CONVERSION_COUNT")
        }
        for keys in summaryDictionary {
            if keys.currencyName != "Commission" {
                currencyKeys.append(keys.currencyName)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func conversionButtonAction(_ sender: UIButton) {
        if let fromTF = fromTextField.text, fromTF.isEmpty {
            let alert = Global.showAlertWithTitle("Alert", okTitle: "OK", cancelTitle: "", message: "Kindly Provide the amount", isCancel: false, okHandler: {action in
                })
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        return
        }
        if validateConversionAmountIsHigher() {
            return
        }
        let fromCurrency = fromDropDown.titleLabel!.text! as String
        let toCurrency   = toDropDown.titleLabel!.text! as String
        let amtValue     = fromTextField.text! as String
        
        let url = BASE_URL + "\(amtValue)-\(fromCurrency)/\(toCurrency)/latest"
        WebServices.sharedInstance.performApiCallWithURLString(url, methodName: "GET", headers: [:], parameters: nil, httpBody:nil, withMessage: "", alertMessage: "Please check your device settings to ensure you have a working internet connection.", fromView: self.view, successHandler: {[weak self] json, response in
            guard json != nil else {
             return
            }
            if response?.statusCode == 200 {
                if let result = json as? Dictionary<String , String> {
                   self?.calculationConversion(result: result)
                }
            } else if response!.statusCode == 400 {
                
            }
            else if response!.statusCode == 401 {
                let alert = Global.showAlertWithTitle("Problem",okTitle:"OK",cancelTitle:"Cancel",message:"Un authorised request",isCancel:false, okHandler: {action in
                    return
                })
                self?.present(alert, animated: true, completion: nil)
            }
            }, failureHandler: { [unowned self] response, error in
                if let response = response, response.statusCode == 500 {
                    let alert = Global.showAlertWithTitle("Problem",okTitle:"OK",cancelTitle:"Cancel",message:"Internal server error occured",isCancel:false, okHandler: {action in
                        return
                    })
                    self.present(alert, animated: true, completion: nil)
                }
        })
    }
    
    func calculationConversion(result : Dictionary<String , String>) {
        
        var conversionCount = UserDefaults.standard.integer(forKey: "CONVERSION_COUNT") as Int
        conversionCount += 1
        UserDefaults.standard.set(conversionCount, forKey: "CONVERSION_COUNT")
        var commision = false
        if conversionCount == 5 {
            showAlertWithMessage(message:"Your Free 5 conversion completed. conversion commision will be charged with 0.7% commission fee")
        }
        if conversionCount >= 6 {
            commision = true
        }
        
        let fromCurrency = fromDropDown.titleLabel!.text! as String
        let toCurrency   = toDropDown.titleLabel!.text! as String
        
        if fromCurrency == toCurrency {
            showAlertWithMessage(message:"Source and Target conversion types can't be same")
            return
        }
        
        let amtValue     =  (fromTextField.text! as NSString).floatValue
        let indexOfFrom  = summaryDictionary.index { (summModel) -> Bool in
            summModel.currencyName == fromCurrency
        }
        let indexOfTo    = summaryDictionary.index { (summModel) -> Bool in
            summModel.currencyName == toCurrency
        }
        let fromCurrencyAmount = summaryDictionary[indexOfFrom!].currencyAmt
        let toCurrencyAmount   = summaryDictionary[indexOfTo!].currencyAmt
        
        var balanceAmountFrom:Float = 0.0
        let balanceAmountTo   = toCurrencyAmount   + (result["amount"]! as NSString).floatValue
        
        if commision {
            balanceAmountFrom = fromCurrencyAmount - amtValue - (amtValue * 0.007)
            let commissionTotal = summaryDictionary.last?.currencyAmt
            summaryDictionary.last?.currencyAmt = commissionTotal! + (amtValue * 0.007)
        }else {
            balanceAmountFrom = fromCurrencyAmount - amtValue
        }
        
        if balanceAmountFrom < 0 {
            showAlertWithMessage(message:"Cannot proceed conversion as your balance amount could be negative")
            return
        }
        
        toTextField.text      = result["amount"]!
        summaryDictionary[indexOfFrom!].currencyAmt = balanceAmountFrom
        summaryDictionary[indexOfTo!].currencyAmt   = balanceAmountTo
        
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: summaryDictionary)
        UserDefaults.standard.set(encodedData, forKey: "SUMMARY_CONVERSION")
        summaryTableView.reloadData()
    }
    func validateConversionAmountIsHigher() -> Bool {
        let fromCurrency = fromDropDown.titleLabel!.text! as String
         let amtValue     =  (fromTextField.text! as NSString).floatValue
        
        let indexOfFrom  = summaryDictionary.index { (summModel) -> Bool in
            summModel.currencyName == fromCurrency
        }
        let fromCurrencyAmount = summaryDictionary[indexOfFrom!].currencyAmt
        let balanceAmountFrom = fromCurrencyAmount - amtValue
        
        if balanceAmountFrom < 0 {
            showAlertWithMessage(message:"Cannot proceed conversion as your balance amount could be negative")
            return true
        }
    return false
    }
    func showAlertWithMessage(message : String)  {
        let alert = Global.showAlertWithTitle("Alert", okTitle: "OK", cancelTitle: "", message: message, isCancel: false, okHandler: {action in
        })
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func fromButtonAction(_ sender: UIButton) {
        currencyNamePickerView.isHidden = false
        buttonActionString = "from"
    }
    @IBAction func toButtonAction(_ sender: UIButton) {
        currencyNamePickerView.isHidden = false
        buttonActionString = "to"
    }
    
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return summaryDictionary.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "summaryCell", for: indexPath)
        let singleCurrencyModel = summaryDictionary[indexPath.row] as CurrencyModel
        cell.textLabel?.text = singleCurrencyModel.currencyName
        cell.detailTextLabel?.text = String(singleCurrencyModel.currencyAmt)
        return cell
    }
}

extension HomeViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencyKeys.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let value = currencyKeys[row]
        return value
    }
}

extension HomeViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if buttonActionString == "from" {
            fromDropDown.setTitle(currencyKeys[row], for: .normal)
        }else {
            toDropDown.setTitle(currencyKeys[row], for: .normal)
        }
        currencyNamePickerView.isHidden = true
    }
}
