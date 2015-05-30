//
//  Stock.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


@objc(ZENStock) class Stock: NSObject, NSCoding, Equatable, Printable {
    // Need to reference the old Obj-C class name to retrieve the archive
    
    
    // MARK: Properties
    
    // Stored properties
    let name: String
    let symbol: String
    var currency: String = "USD" // must be variable to deal with change from GBX to GBP
    var market: String
    
    var numberOfShares = 0
    var purchaseSharePrice = 0.0
    var currentSharePrice = 0.0
    var intradayEvolutionValue = 0.0
    var intradayEvolutionPercentage = 0.0
    var purchaseCurrencyRate = 1.0
    var currentCurrencyRate = 1.0
    var purchaseDate: NSDate?
    /** Last trading date recorded for this stock */
    var lastTradeDate: NSDate?
    /** Unique identifier for this stock, used to let the notifications (alerts) get a pointer to the stock. */
    var uniqueIdentifier: String! = NSUUID().UUIDString
    
    // Computed properties
    /** Calculated as: numberOfShares * purchaseSharePrice */
    var costInLocalCurrency: Double { return Double(numberOfShares) * purchaseSharePrice}
    /** Calculated as: currentSharePrice * numberOfShares */
    var valueInLocalCurrency: Double { return Double(numberOfShares) * currentSharePrice}
    
    /** Purchase cost in portfolio currency (EUR) = cost in local currency (USD) / purchase currency rate (EURUSD=X)
    Calculated as: costInLocalCurrency / purchaseCurrencyRate.
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
    
    /** Value in portfolio currency (EUR) = value in local currency (USD) / current currency rate (EURUSD=X).
    Calculated as: valueInLocalCurrency / currentCurrencyRate
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
    
    // Printable protocol
    override var description: String {
        return "\(symbol) : \(uniqueIdentifier)"
    }
    
    
    // Designated Initializer
    init (symbol: String, name: String, market: String, currency: String) {
        self.symbol = symbol
        self.name = name
        self.market = market
        self.currency = currency
    }

    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObjectForKey("name") as! String
        symbol = aDecoder.decodeObjectForKey("symbol") as! String
        currency = aDecoder.decodeObjectForKey("currency") as! String
        market = aDecoder.decodeObjectForKey("market") as! String
        
        numberOfShares = aDecoder.decodeIntegerForKey("numberOfShares")
        
        purchaseSharePrice = aDecoder.decodeDoubleForKey("purchaseSharePrice")
        currentSharePrice = aDecoder.decodeDoubleForKey("currentSharePrice")
        intradayEvolutionValue = aDecoder.decodeDoubleForKey("intradayEvolutionValue")
        intradayEvolutionPercentage = aDecoder.decodeDoubleForKey("intradayEvolutionPercentage")
        purchaseCurrencyRate = aDecoder.decodeDoubleForKey("purchaseCurrencyRate")
        currentCurrencyRate = aDecoder.decodeDoubleForKey("currentCurrencyRate")
        
        lastTradeDate = aDecoder.decodeObjectForKey("lastTradeDate") as? NSDate
        purchaseDate = aDecoder.decodeObjectForKey("purchaseDate") as? NSDate
        
        uniqueIdentifier = aDecoder.decodeObjectForKey("uniqueIdentifier") as? String
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
        
        if lastTradeDate != nil {
            aCoder.encodeObject(lastTradeDate!, forKey:"lastTradeDate")
        }
        if purchaseDate != nil {
            aCoder.encodeObject(purchaseDate!, forKey:"purchaseDate")
        }
        if uniqueIdentifier != nil {
            aCoder.encodeObject(uniqueIdentifier, forKey:"uniqueIdentifier")
        }
        
    }
    
}

// MARK: - Conversion from and to CKRecord
import CloudKit
extension Stock {
    
    /** Turns a CloudKit record into a Stock object */
    class func stockFromCloudRecord(record: CKRecord) -> Stock {
        
        let name = record.objectForKey("name") as! String
        let symbol = record.objectForKey("symbol") as! String
        let currency = record.objectForKey("currency") as! String
        let market = record.objectForKey("market") as! String
        
        var stock = Stock(symbol: symbol, name: name, market: market, currency: currency)
        stock.numberOfShares = record.objectForKey("numberOfShares") as! Int
        stock.purchaseSharePrice = record.objectForKey("purchaseSharePrice") as! Double
        stock.currentSharePrice = record.objectForKey("currentSharePrice") as! Double
        stock.intradayEvolutionValue = record.objectForKey("intradayEvolutionValue") as! Double
        stock.intradayEvolutionPercentage = record.objectForKey("intradayEvolutionPercentage") as! Double
        stock.purchaseCurrencyRate = record.objectForKey("purchaseCurrencyRate") as! Double
        stock.currentCurrencyRate = record.objectForKey("currentCurrencyRate") as! Double
        
        if let purchaseDate = record.objectForKey("purchaseDate") as? NSDate {
            stock.purchaseDate = purchaseDate
        }
        if let lastTradeDate = record.objectForKey("lastTradeDate") as? NSDate {
            stock.lastTradeDate = lastTradeDate
        }
        
        // As we gave a uniqueIdentifier when uploading to the iCloud server,
        // we are assured to get one when downloading from the server
        stock.uniqueIdentifier = record.recordID.recordName
        
        return stock
    }
    
    
    /** Turns a Stock object into a CloudKit record */
    class func cloudRecordFromStock(stock: Stock) -> CKRecord {
        
        // If the stock does not have a unique identifier yet, give it one on the fly
        if stock.uniqueIdentifier == nil {
            stock.uniqueIdentifier = NSUUID().UUIDString
        }
        
        // Create a CKRecord for the stock, using the stock uniqueIdentifier as the recordID's recordName
        let recordID = CKRecordID(recordName: stock.uniqueIdentifier)
        var stockRecord = CKRecord(recordType: CloudManager.Constants.RecordTypeStock, recordID: recordID)
        
        // NB: values must conform to CKRecordValue protocol!
        stockRecord.setObject(stock.name as NSString, forKey: "name")
        stockRecord.setObject(stock.symbol as NSString, forKey: "symbol")
        stockRecord.setObject(stock.currency as NSString, forKey: "currency")
        stockRecord.setObject(stock.market as NSString, forKey: "market")
        
        stockRecord.setObject(stock.numberOfShares as NSNumber, forKey: "numberOfShares")
        stockRecord.setObject(stock.purchaseSharePrice as NSNumber, forKey: "purchaseSharePrice")
        stockRecord.setObject(stock.currentSharePrice as NSNumber, forKey: "currentSharePrice")
        stockRecord.setObject(stock.intradayEvolutionValue as NSNumber, forKey: "intradayEvolutionValue")
        stockRecord.setObject(stock.intradayEvolutionPercentage as NSNumber, forKey: "intradayEvolutionPercentage")
        stockRecord.setObject(stock.purchaseCurrencyRate as NSNumber, forKey: "purchaseCurrencyRate")
        stockRecord.setObject(stock.currentCurrencyRate as NSNumber, forKey: "currentCurrencyRate")
        
        
        if stock.purchaseDate != nil {
            stockRecord.setObject(stock.purchaseDate! as NSDate, forKey: "purchaseDate")
        }
        if stock.lastTradeDate != nil  {
            stockRecord.setObject(stock.lastTradeDate! as NSDate, forKey: "lastTradeDate")
        }
        
        return stockRecord
    }
    
}


// Global function to have Stock class conform to the Equatable protocol
func ==(lhs: Stock, rhs: Stock) -> Bool {
    return lhs === rhs
}
