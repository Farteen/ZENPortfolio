//
//  JSONStockDetailRootObject.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 17/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


class JSONStockDetailRootObject: JSONSerializableProtocol {
    
    // MARK: Public properties
    var items = [Stock]()
    lazy var fetchDate = NSDate()

    
    // MARK: JSON parsing methods
        
    func readFromJSONDictionary(dictionary: NSDictionary) {

        // The top-level object contains a "query" object
        let query = dictionary["query"] as! NSDictionary
        let dateString = query["created"] as! String
        
        // The query has a "created" property, expressed in GMT time
        var gmtFormatter = NSDateFormatter()
        gmtFormatter.locale = NSLocale(localeIdentifier:"en_US_POSIX")
        gmtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        gmtFormatter.timeZone = NSTimeZone(abbreviation:"GMT")
        if let createdDate = gmtFormatter.dateFromString(dateString) {
         fetchDate = createdDate
        }
        
        // The format of the JSON file changes whether the "count" property is 1 or more
        let count = query["count"] as! Int

        if count == 0 {
            println("Array of stocks is empty")
        
        } else if count == 1 {
            let results = query["results"] as! NSDictionary
            
            // If there is only 1 stock, "row" is a dictionary
            let row = results["row"] as! NSDictionary
            getStockInfoFromJSONDictionary(row)
            
        } else if count > 1 {
            let results = query["results"] as! NSDictionary
            
            // If there is more than 1 stock, "row" is an array of dictionaries
            let row = results["row"] as! NSArray
            
            for quote: AnyObject in row {
                getStockInfoFromJSONDictionary(quote as! NSDictionary)
            }
        }
    }
    
    
    // MARK: helper method
    func getStockInfoFromJSONDictionary(quote: NSDictionary) {
        
        
        let symbol: String = quote["symbol"] as! String
        
        // If stock is in fact a currency rate
        if symbol.hasSuffix("=X") {
            
            if let fetchedRate = quote["price"] as? NSString  where fetchedRate.doubleValue != 0.0 {
                    CurrencyRateStore.sharedStore[symbol] = fetchedRate.doubleValue
                    println("CurrencyRateStore dictionary : \(CurrencyRateStore.sharedStore.dictionary)")
            }
            
        } else {
            // If stock is a "real" market stock
            let filteredArrayOfStocks = StockStore.sharedStore.allStocks.filter { $0.symbol == symbol as String }
            
            if filteredArrayOfStocks.count > 0 {
                for selectedStock in filteredArrayOfStocks {
                    
                    // Update CURRENT SHARE PRICE
                    if let currentPrice = quote["price"] as? NSString where currentPrice.doubleValue != 0.0 {
                            selectedStock.currentSharePrice = currentPrice.doubleValue
                            println("Current share price updated for \(selectedStock.symbol): \(selectedStock.currentSharePrice) \(selectedStock.currency)")
                    }
                    
                    // Update INTRADAY EVOLUTION (VALUE)
                    if let changeValue = quote["changeValue"] as? NSString {
                        selectedStock.intradayEvolutionValue = changeValue.doubleValue
                        println("Intraday change value updated for \(selectedStock.symbol): \(selectedStock.intradayEvolutionValue) \(selectedStock.currency)")
                    }
                    
                    // Update INTRADAY EVOLUTION (PERCENTAGE)
                    if let changePercentage = quote["changePercentage"] as? NSString {
                        selectedStock.intradayEvolutionPercentage = changePercentage.doubleValue / 100.0;
                        println("Intraday change percentage updated for \(selectedStock.symbol): \(selectedStock.intradayEvolutionPercentage * 100.0) %")
                    }
                    
                    // Update CURRENT CURRENCY RATE with the refreshed currency rates
                    // Currency rate update only make sense if the stock currency is different from the portfolio currency (chosen in Preferences)
                    
                    var currency = selectedStock.currency
                    // Special case for GBX (0,01 GBP)
                    if currency == "GBX" { currency = "GBP" }
                    
                    if currency != GlobalSettings.sharedStore.portfolioCurrency {
                        
                        // In the CurrencyRateStore, get the currency rate for the stock currency
                        
                        if GlobalSettings.sharedStore.portfolioCurrency == "USD" {
                            // currency rate with USD must always feature USD as the base unit
                            // Yahoo does not have combinations like USDEUR=X, only EURUSD=X
                            let combination = currency + GlobalSettings.sharedStore.portfolioCurrency + "=X"
                            if let currentRate = CurrencyRateStore.sharedStore[combination] {
                                selectedStock.currentCurrencyRate = 1.0 / currentRate
                            }
                        } else {
                            let combination = GlobalSettings.sharedStore.portfolioCurrency + currency + "=X"
                            if let currentRate = CurrencyRateStore.sharedStore[combination] {
                                selectedStock.currentCurrencyRate = currentRate
                            }
                        }
                        println("Currency rate updated for share \(selectedStock.symbol) : \(selectedStock.currentCurrencyRate)")
                        
                    } else { // currency for the selected stock is equal to the portfolio currency
                        // Force the exchange rate to 1
                        selectedStock.currentCurrencyRate = 1.0000
                    }
                    
                    // Update LAST TRADE DATE
                    // The stock has a "LastTradeDate" and a "LastTradeTime" property, expressed in EST time
                    var estFormatter = NSDateFormatter()
                    estFormatter.locale = NSLocale(localeIdentifier:"en_US_POSIX")
                    estFormatter.dateFormat = "MM/dd/yyyy hh:mma"
                    estFormatter.timeZone = NSTimeZone(abbreviation: "EST")
                    let dateString = quote["date"] as! String
                    let timeString = quote["time"] as! String
                    
                    let quotationDateString =  dateString + " " + timeString
                    if let lastQuotationDate = estFormatter.dateFromString(quotationDateString) {
                        selectedStock.lastTradeDate = lastQuotationDate
                    }
                    
                    items.append(selectedStock)
                }
            }
        }
    }
}