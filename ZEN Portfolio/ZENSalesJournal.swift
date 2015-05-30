//
//  ZENSalesJournal.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 13/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENSalesJournal {
    
    // MARK: Singleton
    class func sharedStore() -> ZENSalesJournal! {
    struct Static {
        static var instance: ZENSalesJournal?
        static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ZENSalesJournal()
        }
        
        return Static.instance!
    }
    
    
    // MARK: Properties
    var allEntries = ZENSale[]()
    
    
    // MARK: Methods for sales management
    /** Creates a new sales entry and adds it to the "allEntries" array */
    func createSale(#symbol: String, currency: String, saleDate:NSDate, numberOfSharesSold: Int, purchaseSharePrice : Double, sellingSharePrice: Double, purchaseCurrencyRate: Double, sellingCurrencyRate: Double) -> ZENSale {
        var sale = ZENSale(symbol: symbol, currency: currency, saleDate: saleDate)
        sale.numberOfSharesSold = numberOfSharesSold
        sale.purchaseSharePrice = purchaseSharePrice
        sale.sellingSharePrice = sellingSharePrice
        sale.purchaseCurrencyRate = purchaseCurrencyRate
        sale.sellingCurrencyRate = sellingCurrencyRate
        
        allEntries += sale
        
        // sort array by saleDate descending
        sort(allEntries) { $0.saleDate.compare($1.saleDate) == NSComparisonResult.OrderedDescending}
        
        return sale
    }
    
    /** Remove a given stock from the Sales journal */
    func removeEntry(saleToRemove: ZENSale) {
        for (index, sale) in enumerate(allEntries) {
            if sale === saleToRemove {
                allEntries.removeAtIndex(index)
            }
        }
    }
    
    /** Removes all stocks from the Stock store */
    func removeAllEntries() {
        allEntries.removeAll()
    }
    
    
    // MARK: Archiving items in Stocks Store
    var salesJournalArchivePath: String { // Archive path
    var documentDirectories: Array = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        // Get the only document directory from that list
        let documentDirectory: AnyObject = documentDirectories[0]
        
        return documentDirectory.stringByAppendingPathComponent("salesJournal.archive")
    }
    
    func saveChanges()-> Bool
    {
        // return success or failure
        return NSKeyedArchiver.archiveRootObject(allEntries, toFile:salesJournalArchivePath)
    }
}