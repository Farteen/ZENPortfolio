//
//  ZENStockStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENStockStore {
    
    // MARK: Singleton
    class func sharedStore() -> ZENStockStore! {
        struct Static {
            static var instance: ZENStockStore?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ZENStockStore()
        }
        
        return Static.instance!
    }
//    TODO: class var sharedStore = ZENStockStore()
        
    // MARK: Properties
    // Stored properties
    var allItems = ZENStock[]()
    
    // Computed properties
    var portfolioNumberOfShares: Int {
    var numberOfShares = 0
        for stock in allItems {
            numberOfShares += stock.numberOfShares
        }
        return numberOfShares;
    }
    
    var portfolioTotalCost: Double {
    var portfolioCost = 0.0
        for stock in allItems {
            portfolioCost += round(stock.costInPortfolioCurrency * 100.0) / 100.0
        }
        return portfolioCost
    }
    
    var portfolioTotalValue: Double {
    var portfolioValue = 0.0
        for stock in allItems {
            portfolioValue += round(stock.valueInPortfolioCurrency * 100.0) / 100.0
        }
        return portfolioValue
    }
    
    var portfolioGainOrLossValue: Double {
    var portfolioTotalGainValue = 0.0
        for stock in allItems {
            portfolioTotalGainValue += round(stock.gainOrLossValue * 100.0) / 100.0
        }
        return portfolioTotalGainValue
        
    }
    
    var portfolioGainOrLossPercentage: Double {
    if portfolioTotalCost == 0.0 {
        return 0.0
        }
        return portfolioGainOrLossValue / portfolioTotalCost
    }
    
    
    init () {
        // TODO: check if this is correct ...
        if let itemsArray: AnyObject = NSKeyedUnarchiver.unarchiveObjectWithFile(stockArchivePath) {
            allItems = itemsArray as ZENStock[]
        }
    }
    
    
    
    // MARK: Methods for stocks management
    /** Creates a new stock item and adds it to the "allItems" array */
    func createStock(#symbol: String, name: String, market: String, currency:String) -> ZENStock {
        var stock = ZENStock(symbol:symbol, name:name, market:market, currency:currency)
        allItems += stock
        
        return stock
    }
    
    /** Remove a given stock from the Stock store */
    func removeStock(stockToRemove: ZENStock) {
        
        // Remove corresponding notifications from Notification Store
        
        // Create a copy of the array to avoid mutating while enumerating (Swift creates a copy automatically as soon as the array length is modified)
        var allNotificationsCopy = ZENLocalNotificationStore.sharedStore().allNotifications
        
        for notification in allNotificationsCopy {
            if notification.stock === stockToRemove {
                ZENLocalNotificationStore.sharedStore().removeNotification(notification)
            }
        }
        
        // Then remove item
        var allItemsCopy = ZENLocalNotificationStore.sharedStore().allNotifications
        for (index, stock) in enumerate(allItemsCopy) {
            if stock === stockToRemove {
                allItems.removeAtIndex(index)
            }
        }
    }
    
    /** Removes all stocks from the Stock store */
    func removeAllItems() {
        
        // Remove all notifications from notificationStore
        ZENLocalNotificationStore.sharedStore().removeAllNotifications();
        
        allItems.removeAll()
    }
    
    /** Moves a stock item from one index to another in the "allItems" array */
    func moveItemsFromIndex(fromIndex: Int, toIndex: Int) {
        //    [_allItems exchangeObjectAtIndex:to withObjectAtIndex:from];
        
        if fromIndex == toIndex {
            return
        }
        
        // Get pointer to object being moved so we can re-insert it
        let stock = allItems[fromIndex];
        
        // Remove p from array
        allItems.removeAtIndex(fromIndex)
        
        // Insert p in array at new location
        allItems.insert(stock, atIndex:toIndex)
    }
    
    
    // MARK: Archiving items in Stocks Store
    var stockArchivePath: String { // Archive path
    var documentDirectories: Array = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        // Get the only document directory from that list
        let documentDirectory: AnyObject = documentDirectories[0]
        
        return documentDirectory.stringByAppendingPathComponent("stocks.archive")
    }
    
    func saveChanges()-> Bool
    {
        // return success or failure
        return NSKeyedArchiver.archiveRootObject(allItems, toFile:stockArchivePath)
    }
}

