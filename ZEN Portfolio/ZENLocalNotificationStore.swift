//
//  ZENLocalNotificationStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENLocalNotificationStore {
    
    // MARK: Singleton
    class func sharedStore() -> ZENLocalNotificationStore! {
        struct Static {
            static var instance: ZENLocalNotificationStore?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ZENLocalNotificationStore()
        }
        
        return Static.instance!
    }
    
    
    // MARK: Properties
    var allNotifications = ZENLocalNotification[]()
    
    
    // MARK: Methods for notification management
    init () {
        // TODO: check if this is correct ...
        if let notificationsArray: AnyObject = NSKeyedUnarchiver.unarchiveObjectWithFile(notificationArchivePath) {
            allNotifications = notificationsArray as ZENLocalNotification[]
        }
    }
    
    
    /** Creates a new stock item and adds it to the "allItems" array */
    func createNotification(#type: ZENPortfolioNotificationType, forStock stock: ZENStock, withTarget target: Double, compareAscending :Bool) -> ZENLocalNotification {
        var notification = ZENLocalNotification(notificationType: type, stock: stock, target: target, compareAscending: compareAscending)
        allNotifications += notification
        
        // sort array by item symbol descending
        
        
        return notification
    }
    
    /** Remove a given stock from the Local notification store */
    func removeNotification(notificationToRemove: ZENLocalNotification) {
        
        for (index, notification) in enumerate(allNotifications) {
            if notification === notificationToRemove {
                allNotifications.removeAtIndex(index)
                println("Removing notification: symbol=\(notification.stock.symbol) numberOfShares=\(notification.stock.numberOfShares) notificationType=\(notification.notificationType) target=\(notification.target)")
            }
        }
    }
    
    /** Removes all stocks from the Stock store */
    func removeAllNotifications() {
        allNotifications.removeAll()
    }
    
    /** Filter notifications by stock name */
    func notificationsFilteredByStockName(filterName: String) -> Array<ZENLocalNotification> {
        return allNotifications.filter { $0.stock.name == filterName }
    }
    
    
    
    // MARK: Archiving notifications in Notification Store
    var notificationArchivePath: String { // Archive path
    var documentDirectories: Array = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        // Get the only document directory from that list
        let documentDirectory: AnyObject = documentDirectories[0]
        
        return documentDirectory.stringByAppendingPathComponent("notificationStore.archive")
    }
    
    func saveChanges()-> Bool
    {
        // return success or failure
        return NSKeyedArchiver.archiveRootObject(allNotifications, toFile:notificationArchivePath)
    }
}