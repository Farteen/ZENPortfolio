//
//  StockAlertStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class StockAlertStore {
    
    // MARK: Singleton
    class func sharedStore() -> StockAlertStore! {
        struct Static {
            static var instance: StockAlertStore?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = StockAlertStore()
        }
        
        return Static.instance!
    }
    
    
    // MARK: Properties
    var allAlerts = [StockAlert]()
    
    
    init () {
        // TODO: check if this is correct ...
        if let notificationsArray: AnyObject = NSKeyedUnarchiver.unarchiveObjectWithFile(alertArchivePath) {
            allAlerts = notificationsArray as [StockAlert]
        }
    }
    
    
    // MARK: Methods for notification management

    /** Creates a new stock item and adds it to the "allStocks" array */
    func createNotification(#type: StockAlertType, forStock stock: Stock, withTarget target: Double, compareAscending :Bool) -> StockAlert {
        var alert = StockAlert(type: type, stock: stock, target: target, compareAscending: compareAscending)
        allAlerts += alert
        
        // sort array by item symbol descending
        // TODO !
        
        return alert
    }
    
    /** Remove a given stock from the Local notification store */
    func removeAlert(alertToRemove: StockAlert) {
        
        for (index, alert) in enumerate(allAlerts) {
            if alert === alertToRemove {
                allAlerts.removeAtIndex(index)
                println("Removing alert: symbol=\(alert.stock.symbol) numberOfShares=\(alert.stock.numberOfShares) type=\(alert.type) target=\(alert.target)")
            }
        }
    }
    
    /** Removes all stocks from the Stock store */
    func removeAllAlerts() {
        allAlerts.removeAll()
    }
    
    /** Filter notifications by stock name */
    func alertsFilteredByStockName(filterName: String) -> Array<StockAlert> {
        return allAlerts.filter { $0.stock.name == filterName }
    }
    
    
    
    // MARK: Archiving notifications in Notification Store
    var alertArchivePath: String { // Archive path
    var documentDirectories: Array = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        // Get the only document directory from that list
        let documentDirectory: AnyObject = documentDirectories.firstElement
        
        return documentDirectory.stringByAppendingPathComponent("notificationStore.archive")
    }
    
    func saveChanges()-> Bool
    {
        // return success or failure
        return NSKeyedArchiver.archiveRootObject(allAlerts, toFile:alertArchivePath)
    }
}