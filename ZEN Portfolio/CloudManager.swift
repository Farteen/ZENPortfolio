//
//  CloudManager.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 05/03/2015.
//  Copyright (c) 2015 Frédéric ADDA. All rights reserved.
//

import CloudKit


/**
This class is a singleton used as a manager for all activities related to Cloud storage / data retrieval (mainly CloudKit)
It namely coordinates activities from the 3 data stores: StockStore, SalesJournal and StockNotificationStore.
*/
class CloudManager {
    
    // MARK: Singleton
    static let sharedManager = CloudManager()
    
    struct CloudKeys {
        static let ActivatedKey                 = "ZENPortfolioiCloudActivatedKey"
        static let PromptedKey                  = "ZENPortfolioiCloudPromptedKey"
    }
    

    // iCloud properties
    
    var cloudActivated: Bool {
        get {
            // Point to NSUserDefaults to know if the user activated iCloud in the app
            return NSUserDefaults.standardUserDefaults().boolForKey(CloudKeys.ActivatedKey)
        }
        set {
            // Store the current iCloud activation state in the app as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: CloudKeys.ActivatedKey)
            println("Saved iCloud activation = \(newValue) as NSUserDefaults")
        }
    }
    
    
    var cloudPrompted: Bool {
        get {
            // Point to NSUserDefaults to know if we already proposed te user to use iCloud
            return NSUserDefaults.standardUserDefaults().boolForKey(CloudKeys.PromptedKey)
        }
        set {
            // Store the current iCloud prompted state in the app as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: CloudKeys.PromptedKey)
            println("Saved iCloud prompted = \(newValue) as NSUserDefaults")
        }
    }
    
    var subscribed = false // Bool to determine whether the app is subscribed to CKRecord changes
    
    // MARK: CloudKit
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase

    struct Constants {
        static let RecordTypeStockStore             = "StockStore"
        static let RecordTypeStock                  = "Stock"
        static let RecordTypeSalesJournal           = "SalesJournal"
        static let RecordTypeSale                   = "Sale"
        static let RecordTypeNotificationStore      = "NotificationStore"
        static let RecordTypeNotification           = "Notification"

        static let SubscriptionForStocks            = "SubscriptionForStocks"
        static let SubscriptionForSales             = "SubscriptionForSales"
        static let SubscriptionForNotifications     = "SubscriptionForNotifications"
    }
    
    
    init() {
        // Subscribe to CKRecords changes
        subscribe()
        
        // Get outstanding notifications
        getOutstandingNotifications()

    }
    
    func listenToBecomeActive() {
        // NOTIFICATION CENTER
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
            self.getOutstandingNotifications()
        }
    }
    
    // MARK: CloudKit migrations
    
    /** Migrate archive files between local storage and Cloud storage */
    func copyDataToCloud(completionHandler: (copyError: NSError!) -> ()) {
        // Copy Stocks to iCloud
        StockStore.sharedStore.copyDataToCloud({ copyError in
            if copyError != nil {
                completionHandler(copyError: copyError)
                
            } else {
                // Copy Sales to iCloud
                SalesJournal.sharedStore.copyDataToCloud({ copyError in
                    if copyError != nil {
                        completionHandler(copyError: copyError)
                        
                    } else {
                        // Copy Notifications to iCloud
                        StockNotificationStore.sharedStore.copyDataToCloud({ copyError in
                            if copyError != nil {
                                completionHandler(copyError: copyError)
                                
                            } else {
                                completionHandler(copyError: nil)
                            }
                        })
                    }
                })
            }
        })
    }
    
    
    /** Migrate archive files between Cloud Storage and local storage */
    func loadDataFromCloud(completionHandler: (loadingError: NSError!) -> ()) {
        // Load Stocks from iCloud
        StockStore.sharedStore.loadDataFromCloud ({ loadingError in
            if loadingError != nil {
                completionHandler(loadingError: loadingError)
                
            } else {
                // Load Sales from iCloud
                SalesJournal.sharedStore.loadDataFromCloud ({ loadingError in
                    if loadingError != nil {
                        completionHandler(loadingError: loadingError)
                        
                    } else {
                        // Load Notifications from iCloud
                        StockNotificationStore.sharedStore.loadDataFromCloud ({ loadingError in
                            if loadingError != nil {
                                completionHandler(loadingError: loadingError)
                                
                            } else {
                                completionHandler(loadingError: nil)
                            }
                        })
                    }
                })
            }
        })
    }
    
    
    /** Delete all records from iCloud */
    func deleteAllRecordsFromCloud(completionHandler: (deletionError: NSError!) -> ()) {
        // Delete records from StockStore
        StockStore.sharedStore.deleteAllRecordsFromCloud ({ deletionError in
            if deletionError != nil {
                completionHandler(deletionError: deletionError)
                
            } else {
                // Delete records from SalesJournal
                SalesJournal.sharedStore.deleteAllRecordsFromCloud ({ deletionError in
                    if deletionError != nil {
                        completionHandler(deletionError: deletionError)
                        
                    } else {
                        // Delete records from NotificationStore
                        StockNotificationStore.sharedStore.deleteAllRecordsFromCloud ({ deletionError in
                            if deletionError != nil {
                                completionHandler(deletionError: deletionError)
                            } else {
                                completionHandler(deletionError: nil)
                            }
                        })
                    }
                })
            }
        })
    }
    
    
    /** Move data from Documents Directory to Caches */
    func moveDataFromLocalArchiveToCache() {
        StockStore.sharedStore.moveDataFromLocalArchiveToCache()
        SalesJournal.sharedStore.moveDataFromLocalArchiveToCache()
        StockNotificationStore.sharedStore.moveDataFromLocalArchiveToCache()
    }
    
    
    /** Save data to local Archive path */
    func saveDataToLocalArchivePath() {
        StockStore.sharedStore.saveDataToLocalPath(StockStore.sharedStore.localArchivePath)
        SalesJournal.sharedStore.saveDataToLocalPath(SalesJournal.sharedStore.localArchivePath)
        StockNotificationStore.sharedStore.saveDataToLocalPath(StockNotificationStore.sharedStore.localArchivePath)
    }
    
    /** Delete cache */
    func deleteCache() {
        StockStore.sharedStore.deleteCache()
        SalesJournal.sharedStore.deleteCache()
        StockNotificationStore.sharedStore.deleteCache()
    }
    
    
    
    // MARK: CloudKit Subscriptions
    
    /** Subscribe to CKRecord updates */
    func subscribe() {

        if subscribed { return }
        
        let options = CKSubscriptionOptions.FiresOnRecordCreation | CKSubscriptionOptions.FiresOnRecordUpdate | CKSubscriptionOptions.FiresOnRecordDeletion
        let subscriptionForStocks = CKSubscription(recordType: Constants.RecordTypeStock, predicate: NSPredicate(value: true), subscriptionID: Constants.SubscriptionForStocks, options: options)
        subscriptionForStocks.notificationInfo = CKNotificationInfo()
        subscriptionForStocks.notificationInfo.alertBody = ""
        
        let subscriptionForSales = CKSubscription(recordType: Constants.RecordTypeSale, predicate: NSPredicate(value: true), subscriptionID: Constants.SubscriptionForSales, options: options)
        subscriptionForSales.notificationInfo = CKNotificationInfo()
        subscriptionForSales.notificationInfo.alertBody = ""
        
        let subscriptionForNotifications = CKSubscription(recordType: Constants.RecordTypeNotification, predicate: NSPredicate(value: true), subscriptionID: Constants.SubscriptionForNotifications, options: options)
        subscriptionForNotifications.notificationInfo = CKNotificationInfo()
        subscriptionForNotifications.notificationInfo.alertBody = ""

        let subscriptionOperation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscriptionForStocks, subscriptionForSales, subscriptionForNotifications], subscriptionIDsToDelete: nil)
        subscriptionOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptionIDs, error in
            
            if error != nil {
                println("CloudManager: Error subscribing: \(error.localizedDescription)")
                
            } else {
                self.subscribed = true
                self.listenToBecomeActive()
                println("CloudManager: Successfully subscribed")
            }
        }
        privateDatabase.addOperation(subscriptionOperation)
        
    }
    
    
//    /** Unsubscribe from CKRecord updates - deletes previous subscriptions*/
//    func unsubscribe() {
//        
//        privateDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions, error) in
//            if error != nil {
//                println("CloudManager: Error fetching subscriptions: \(error.localizedDescription)")
//            } else {
//                if subscriptions.count > 0 {
//                    let deleteSubscriptionsOperation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subscriptions)
//                    deleteSubscriptionsOperation.modifySubscriptionsCompletionBlock = { savedSubscriptions, deletedSubscriptionIDs, error in
//                        
//                        if error != nil {
//                            println("CloudManager: Error unsubscribing: \(error.localizedDescription)")
//                            
//                        } else {
//                            println("CloudManager: Successfully unsubscribed")
//                        }
//                    }
//                    self.privateDatabase.addOperation(deleteSubscriptionsOperation)
//                }
//                
//            }
//        }
//    }
    
    /** Handle notification received via subscriptions (direct them to the corresponding Store) */
    func handleNotification(notification: CKQueryNotification) {
        
        if CloudManager.sharedManager.cloudActivated {
            let recordID = notification.recordID
            privateDatabase.fetchRecordWithID(recordID, completionHandler: { (record, error) in
                if error != nil {
                    println("CloudManager: Error fetching record from notification: \(error.localizedDescription)")
                } else {
                    switch record.recordType {
                    case Constants.RecordTypeStock:
                        switch notification.queryNotificationReason {
                        case .RecordCreated: StockStore.sharedStore.addStockFromNotification(record)
                        case .RecordUpdated: StockStore.sharedStore.updateStockFromNotification(recordID)
                        case .RecordDeleted: StockStore.sharedStore.removeStockFromNotification(recordID)
                        }
                    case Constants.RecordTypeSale:
                        switch notification.queryNotificationReason {
                        case .RecordCreated: SalesJournal.sharedStore.addSaleFromNotification(record)
                        case .RecordDeleted: SalesJournal.sharedStore.removeSaleFromNotification(recordID)
                        default: break
                        }
                    case Constants.RecordTypeNotification:
                        switch notification.queryNotificationReason {
                        case .RecordCreated: StockNotificationStore.sharedStore.addStockNotificationFromNotification(record)
                        case .RecordDeleted: StockNotificationStore.sharedStore.removeStockNotificationFromNotification(recordID)
                        default: break
                        }
                    default: break
                    }
                }
            })
            markNotificationsAsRead([notification.notificationID])
        }
    }
    
    /** Mark notifications received via subscriptions as read (notifications marked as read aren’t sent back to the client in a notification fetch) */
    func markNotificationsAsRead(notificationIDs: [CKNotificationID]) {
        let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationIDs)
        CKContainer.defaultContainer().addOperation(markOperation)
    }
    
    
    /** Get outstanding notifications (notification collection) */
    func getOutstandingNotifications() {
        let operation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)
        operation.notificationChangedBlock = { notification in
            if let cKnotification = notification as? CKQueryNotification {
                self.handleNotification(cKnotification)
            }
        }
        operation.fetchNotificationChangesCompletionBlock = { (serverChangeToken, error) in
            if error != nil {
                println("Error fetching notifications: \(error)")
            }
        }
        CKContainer.defaultContainer().addOperation(operation)
    }
}
