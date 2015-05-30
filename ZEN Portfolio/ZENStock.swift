//
//  ZENStock.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENStock: NSCoding {
    
    // MARK: Properties
    
    // Stored properties
    let name: String
    let symbol: String
    var currency: String = "USD" // must be variable to deal with change from GBX to GBP
    let market: String
    
    var numberOfShares = 0
    var purchaseSharePrice = 0.0
    var currentSharePrice = 0.0
    var intradayEvolutionValue = 0.0
    var intradayEvolutionPercentage = 0.0
    var purchaseCurrencyRate = 1.0
    var currentCurrencyRate = 1.0
    /** Last trading date recorded for this stock */
    var lastTradeDate = NSDate()
    
    // Computed properties
    /** Calculated as: numberOfShares * purchaseSharePrice */
    var costInLocalCurrency: Double { return Double(numberOfShares) * purchaseSharePrice}
    /** Calculated as: currentSharePrice * numberOfShares */
    var valueInLocalCurrency: Double { return Double(numberOfShares) * currentSharePrice}
    
    // Purchase cost in portfolio currency (EUR) = cost in local currency (USD) / purchase currency rate (EURUSD=X)
    /** Calculated as: costInLocalCurrency / purchaseCurrencyRate.
    NB: currency rates must be expressed as :  1 portfolio currency for n local currency (e.g. EUR/USD = n)
    */
    var costInPortfolioCurrency: Double {
        if purchaseCurrencyRate == 0.0 {
            return costInLocalCurrency
        }
        
        if currency == "GBX" { // Special case for GBX (0,01 GBP)
            return (costInLocalCurrency / purchaseCurrencyRate) / 100.0
        } else {
            return costInLocalCurrency / purchaseCurrencyRate
        }
    }
    
    // Value in portfolio currency (EUR) = value in local currency (USD) / current currency rate (EURUSD=X)
    /** Calculated as: valueInLocalCurrency / currentCurrencyRate
    NB: currency rates must be expressed as :  1 portfolio currency for n local currency (e.g. EUR/USD = n)
    */
    var valueInPortfolioCurrency: Double {
        if currentCurrencyRate == 0.0 {
            return valueInLocalCurrency
        }
            
        if currency == "GBX" { // Special case for GBX (0,01 GBP)
            return (valueInLocalCurrency / currentCurrencyRate) / 100.0
        } else {
            return valueInLocalCurrency / currentCurrencyRate
        }
    }

    /** valueInPortfolioCurrency - costInPortfolioCurrency */
    var gainOrLossValue: Double { return valueInPortfolioCurrency - costInPortfolioCurrency }
    /** (valueInPortfolioCurrency - costInPortfolioCurrency) / costInPortfolioCurrency */
    var gainOrLossPercentage: Double {
        if costInPortfolioCurrency == 0.0 {
            return 0.0
        }
            
        return (valueInPortfolioCurrency - costInPortfolioCurrency) / costInPortfolioCurrency
    }
    
    // Designated Initializer
    init (symbol: String, name: String, market: String, currency: String) {
        self.symbol = symbol
        self.name = name
        self.market = market
        self.currency = currency
    }

    
    // MARK: NSCoding
    
    init(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObjectForKey("name") as String
        symbol = aDecoder.decodeObjectForKey("symbol") as String
        currency = aDecoder.decodeObjectForKey("currency") as String
        market = aDecoder.decodeObjectForKey("market") as String
        
        numberOfShares = aDecoder.decodeIntegerForKey("numberOfShares")
        
        purchaseSharePrice = aDecoder.decodeDoubleForKey("purchaseSharePrice")
        currentSharePrice = aDecoder.decodeDoubleForKey("currentSharePrice")
        intradayEvolutionValue = aDecoder.decodeDoubleForKey("intradayEvolutionValue")
        intradayEvolutionPercentage = aDecoder.decodeDoubleForKey("intradayEvolutionPercentage")
        purchaseCurrencyRate = aDecoder.decodeDoubleForKey("purchaseCurrencyRate")
        currentCurrencyRate = aDecoder.decodeDoubleForKey("currentCurrencyRate")
        
        lastTradeDate = aDecoder.decodeObjectForKey("lastTradeDate") as NSDate
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey:"name")
        aCoder.encodeObject(symbol, forKey:"symbol")
        aCoder.encodeObject(currency, forKey:"currency")
        aCoder.encodeObject(market, forKey:"market")
        
        aCoder.encodeInteger(numberOfShares, forKey:"numberOfShares")
        
        aCoder.encodeDouble(purchaseSharePrice, forKey:"purchaseSharePrice")
        aCoder.encodeDouble(currentSharePrice, forKey:"currentSharePrice")
        aCoder.encodeDouble(intradayEvolutionValue, forKey:"intradayEvolutionValue")
        aCoder.encodeDouble(intradayEvolutionPercentage, forKey:"intradayEvolutionPercentage")
        aCoder.encodeDouble(purchaseCurrencyRate, forKey:"purchaseCurrencyRate")
        aCoder.encodeDouble(currentCurrencyRate, forKey:"currentCurrencyRate")
        
        aCoder.encodeObject(lastTradeDate, forKey:"lastTradeDate")
    }
}