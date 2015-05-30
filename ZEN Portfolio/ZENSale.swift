//
//  Sales.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 13/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENSale: NSCoding {
    
    // Stored properties
    let symbol: String
    let currency: String
    let saleDate = NSDate()
    
    var numberOfSharesSold = 0
    var purchaseSharePrice = 0.0
    var sellingSharePrice = 0.0
    var purchaseCurrencyRate = 1.0
    var sellingCurrencyRate = 1.0
    
    // Computed properties
    // In portfolio currency (i.e. the currency in which the user chooses to display the values)
        
    /** (number of shares sold * purchase share price) / purchase currency rate */
    var purchaseValue: Double {
    // Purchase value in portfolio currency (EUR) = purchase value in local currency (USD) / purchase currency rate (EURUSD=X)
    //                                            = (number of shares sold * purchase share price) / purchase currency rate
    // NB : currency rates must be expressed as :  1 portfolio currency for n local currency (e.g. EUR/USD = n)
    
    // Special case for GBX (0,01 GBP)
        if currency == "GBX" {
            return (Double(numberOfSharesSold) * purchaseSharePrice / 100.0) / purchaseCurrencyRate
        }
    
        return Double(numberOfSharesSold) * purchaseSharePrice / purchaseCurrencyRate
    }
    
    /** (number of shares sold * selling share price) / selling currency rate */
    var sellingValue: Double {
    // Selling value in portfolio currency (EUR) = selling value in local currency (USD) / selling currency rate (EURUSD=X)
    //                                           = (number of shares sold * selling share price) / selling currency rate
    // NB : currency rates must be expressed as :  1 portfolio currency for n local currency (e.g. EUR/USD = n)
    
    // Special case for GBX (0,01 GBP)
        if currency == "GBX" {
            return (Double(numberOfSharesSold) * self.sellingSharePrice / 100.0) / self.sellingCurrencyRate
        }
        
        return Double(numberOfSharesSold) * self.sellingSharePrice / self.sellingCurrencyRate
    }
    
    /** selling value - purchase value */
    var gainOrLossValue: Double {
        return sellingValue - purchaseValue
    }
    
    /** (selling value - purchase value) / purchaseValue */
    var gainOrLossPercentage: Double {
        return (purchaseValue == 0.0 ? 0.0 : (sellingValue - purchaseValue) / purchaseValue)
    }

   
    
    // Designated initializer
    init(symbol: String, currency: String, saleDate:NSDate) {
        self.symbol = symbol
        self.currency = currency
        self.saleDate = saleDate
        
    }
    
    
    // MARK: NSCoding
    init(coder aDecoder: NSCoder) {
        symbol = aDecoder.decodeObjectForKey("symbol") as String
        currency = aDecoder.decodeObjectForKey("currency") as String
        saleDate = aDecoder.decodeObjectForKey("saleDate") as NSDate
        
        numberOfSharesSold = aDecoder.decodeIntegerForKey("numberOfSharesSold")
        
        purchaseSharePrice = aDecoder.decodeDoubleForKey("purchaseSharePrice")
        sellingSharePrice = aDecoder.decodeDoubleForKey("sellingSharePrice")
        purchaseCurrencyRate = aDecoder.decodeDoubleForKey("purchaseCurrencyRate")
        sellingCurrencyRate = aDecoder.decodeDoubleForKey("sellingCurrencyRate")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(symbol, forKey:"symbol")
        aCoder.encodeObject(currency, forKey:"currency")
        aCoder.encodeObject(saleDate, forKey:"saleDate")
        
        aCoder.encodeInteger(numberOfSharesSold, forKey:"numberOfSharesSold")
        
        aCoder.encodeDouble(purchaseSharePrice, forKey:"purchaseSharePrice")
        aCoder.encodeDouble(sellingSharePrice, forKey:"sellingSharePrice")
        aCoder.encodeDouble(purchaseCurrencyRate, forKey:"purchaseCurrencyRate")
        aCoder.encodeDouble(sellingCurrencyRate, forKey:"sellingCurrencyRate")
    }
}