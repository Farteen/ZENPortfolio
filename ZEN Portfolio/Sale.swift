//
//  Sales.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 13/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



@objc(ZENSale) class Sale: NSObject, NSCoding {
    // Need to reference the old Obj-C class name to retrieve the archive

    // Stored properties
    let symbol: String
    let name: String? // Name was not activated on the previous versions of the app
    let currency: String
    let saleDate: NSDate
    
    var numberOfSharesSold = 0
    var purchaseSharePrice = 0.0
    var sellingSharePrice = 0.0
    var purchaseCurrencyRate = 1.0
    var sellingCurrencyRate = 1.0
    var purchaseDate: NSDate? // Purchase date was not activated on the previous versions of the app
    
    /** Unique identifier for this sale, used to keep unicity with the corresponding CKRecord */
    var cloudIdentifier: String!

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
            return (Double(numberOfSharesSold) * sellingSharePrice / 100.0) / sellingCurrencyRate
        }
        return Double(numberOfSharesSold) * sellingSharePrice / sellingCurrencyRate
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
    init(symbol: String, name: String, currency: String, saleDate:NSDate, numberOfSharesSold: Int, purchaseSharePrice : Double, sellingSharePrice: Double, purchaseCurrencyRate: Double, sellingCurrencyRate: Double) {
        self.symbol = symbol
        self.name = name
        self.currency = currency
        self.saleDate = saleDate
        self.numberOfSharesSold = numberOfSharesSold
        self.purchaseSharePrice = purchaseSharePrice
        self.sellingSharePrice = sellingSharePrice
        self.purchaseCurrencyRate = purchaseCurrencyRate
        self.sellingCurrencyRate = sellingCurrencyRate
    }
    
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        symbol = aDecoder.decodeObjectForKey("symbol") as! String
        name = aDecoder.decodeObjectForKey("name") as? String
        currency = aDecoder.decodeObjectForKey("currency") as! String
        saleDate = aDecoder.decodeObjectForKey("saleDate") as! NSDate

        numberOfSharesSold = aDecoder.decodeIntegerForKey("numberOfSharesSold")
        purchaseSharePrice = aDecoder.decodeDoubleForKey("purchaseSharePrice")
        sellingSharePrice = aDecoder.decodeDoubleForKey("sellingSharePrice")
        purchaseCurrencyRate = aDecoder.decodeDoubleForKey("purchaseCurrencyRate")
        sellingCurrencyRate = aDecoder.decodeDoubleForKey("sellingCurrencyRate")
        
        purchaseDate = aDecoder.decodeObjectForKey("purchaseDate") as? NSDate

        cloudIdentifier = aDecoder.decodeObjectForKey("cloudIdentifier") as? String

    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(symbol, forKey:"symbol")
        
        if name != nil {
            aCoder.encodeObject(name!, forKey:"name")
        }
        
        aCoder.encodeObject(currency, forKey:"currency")
        aCoder.encodeObject(saleDate, forKey:"saleDate")

        aCoder.encodeInteger(numberOfSharesSold, forKey:"numberOfSharesSold")
        aCoder.encodeDouble(purchaseSharePrice, forKey:"purchaseSharePrice")
        aCoder.encodeDouble(sellingSharePrice, forKey:"sellingSharePrice")
        aCoder.encodeDouble(purchaseCurrencyRate, forKey:"purchaseCurrencyRate")
        aCoder.encodeDouble(sellingCurrencyRate, forKey:"sellingCurrencyRate")
        
        if purchaseDate != nil {
            aCoder.encodeObject(purchaseDate!, forKey:"purchaseDate")
        }
        
        if cloudIdentifier != nil {
            aCoder.encodeObject(cloudIdentifier, forKey:"cloudIdentifier")
        }
    }
}

// MARK: - Conversion from and to CKRecord
import CloudKit
extension Sale {
    
    /** Turns a CloudKit record into a Sale object */
    class func saleFromCloudRecord(record: CKRecord) -> Sale {
        
        let symbol = record.objectForKey("symbol") as! String
        
        // As we gave a name when uploading to the iCloud server,
        // we are assured to get one when downloading from the server
        let name = record.objectForKey("name") as! String
        
        let currency = record.objectForKey("currency") as! String
        let saleDate = record.objectForKey("saleDate") as! NSDate
        
        let numberOfSharesSold = record.objectForKey("numberOfSharesSold") as! Int
        let purchaseSharePrice = record.objectForKey("purchaseSharePrice") as! Double
        let sellingSharePrice = record.objectForKey("sellingSharePrice") as! Double
        let purchaseCurrencyRate = record.objectForKey("purchaseCurrencyRate") as! Double
        let sellingCurrencyRate = record.objectForKey("sellingCurrencyRate") as! Double

        var sale = Sale(symbol: symbol, name: name, currency: currency, saleDate: saleDate, numberOfSharesSold: numberOfSharesSold, purchaseSharePrice: purchaseSharePrice, sellingSharePrice: sellingSharePrice, purchaseCurrencyRate: purchaseCurrencyRate, sellingCurrencyRate: sellingCurrencyRate)
    
        sale.purchaseDate = record.objectForKey("purchaseDate") as? NSDate
        sale.cloudIdentifier = record.recordID.recordName
        return sale
    }
    
    
    /** Turns a Sale object into a CloudKit record */
    class func cloudRecordFromSale(sale: Sale) -> CKRecord {
        
        // Create a CKRecord for the sale, using the uniqueIdentifier as the recordID's recordName
        var saleRecord = CKRecord(recordType: CloudManager.Constants.RecordTypeSale)
        sale.cloudIdentifier = saleRecord.recordID.recordName
        
        // NB: values must conform to CKRecordValue protocol!
        saleRecord.setObject(sale.symbol as NSString, forKey: "symbol")
        
        // If the sale does not have a name for its stock yet, give it the symbol of the stock
        let saleName = (sale.name == nil) ? sale.symbol : sale.name!
        saleRecord.setObject(sale.symbol as NSString, forKey: "name")

        saleRecord.setObject(sale.currency as NSString, forKey: "currency")
        saleRecord.setObject(sale.saleDate as NSDate, forKey: "saleDate")

        saleRecord.setObject(sale.numberOfSharesSold as NSNumber, forKey: "numberOfSharesSold")
        saleRecord.setObject(sale.purchaseSharePrice as NSNumber, forKey: "purchaseSharePrice")
        saleRecord.setObject(sale.sellingSharePrice as NSNumber, forKey: "sellingSharePrice")
        saleRecord.setObject(sale.purchaseCurrencyRate as NSNumber, forKey: "purchaseCurrencyRate")
        saleRecord.setObject(sale.sellingCurrencyRate as NSNumber, forKey: "sellingCurrencyRate")
        
        if sale.purchaseDate != nil {
            saleRecord.setObject(sale.purchaseDate! as NSDate, forKey: "purchaseDate")
        }
        
        return saleRecord
    }
    
}

