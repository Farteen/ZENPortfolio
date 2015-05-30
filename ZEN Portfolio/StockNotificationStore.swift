//
//  StockNotificationStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import CloudKit

@objc(ZENLocalNotificationStore) class StockNotificationStore {
    // Need to reference the old Obj-C class name to retrieve the archive

    
    // MARK: Singleton
    static let sharedStore = StockNotificationStore()
    
    // MARK: Properties
    var allNotifications = [StockNotification]()
    
    
    // MARK: Initializer
    init () {
        // If iCloud is activated, we first load data from cache on disk, and then refresh local data with the iCloud data
        if CloudManager.sharedManager.cloudActivated {
            loadDataFromLocalPath(cachePath)
            loadDataFromCloud({ loadingError -> () in
                if loadingError != nil {
                    println(loadingError!.localizedDescription)
                }
            })
        } else {
            // Load data from data on disk
            loadDataFromLocalPath(localArchivePath)
        }
    }
        
    
    // MARK: Methods for stock notification management

    /** Creates a new notification item and adds it to the "allNotifications" array */
    func createNotification(#type: StockNotificationType, forStockIdentifier stockIdentifier: String, withTarget target: Double, compareAscending :Bool) -> StockNotification {
        var notification = StockNotification(type: type, stockIdentifier: stockIdentifier, target: target, compareAscending: compareAscending)
        
        
        allNotifications.append(notification)
        
        // sort array by stock symbol descending
        sort(&allNotifications) { $0.stock?.symbol < $1.stock?.symbol }
        
        
        // Track event in Analytics
        if let tracker = GAI.sharedInstance().defaultTracker {
            let event = GAIDictionaryBuilder.createEventWithCategory("Stock management", action: "New Notification", label: notification.stock?.symbol, value: notification.type.rawValue).build() as [NSObject : AnyObject]
            tracker.send(event)
        }


        return notification
    }
    
    /** Remove a given notification from the Notification store */
    func removeNotification(notificationToRemove: StockNotification) {
        
        if let index = find(allNotifications, notificationToRemove) {
            allNotifications.removeAtIndex(index)
            
            if notificationToRemove.stock != nil {
                println("Removing notification: symbol=\(notificationToRemove.stock!.symbol) numberOfShares=\(notificationToRemove.stock!.numberOfShares) type=\(notificationToRemove.type.description) target=\(notificationToRemove.target)")
            }
        }
    }
    
    /** Removes all notifications from the NotificationStore */
    func removeAllNotifications() {
        
        allNotifications.removeAll()
    }
    
    /** Filter notifications by stock name */
    func notificationsFilteredByStockName(filterName: String) -> Array<StockNotification> {
        return allNotifications.filter { $0.stock?.name == filterName }
    }
    
    
    
    // MARK: - Persistence management
    private let FileName = "notifications.archive"
    
    
    // MARK: Saving / loading data from local storage
    var localArchivePath: String {
        var documentDirectories: Array = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        // Get the only document directory from that list
        let documentDirectory: AnyObject = documentDirectories.first!
        return documentDirectory.stringByAppendingPathComponent(FileName)
    }
    
    var cachePath: String {
        var documentDirectories: Array = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        
        // Get the only document directory from that list
        let documentDirectory: AnyObject = documentDirectories.first!
        return documentDirectory.stringByAppendingPathComponent(FileName)
    }
    
    
    func loadDataFromLocalPath(path: String) {
        if let salesArray = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [StockNotification] {
            allNotifications = salesArray
        }
    }
    
    /** Save the allNotifications array to an archived file on disk */
    func saveDataToLocalPath(path: String) -> Bool {
        return NSKeyedArchiver.archiveRootObject(allNotifications, toFile:path)
    }
    
    
    /** Move archive file from Documents to Caches folder */
    func moveDataFromLocalArchiveToCache() {
        
        let fileManager = NSFileManager.defaultManager()
        
        // Delete cache file, in case it exists, because that would make the move operation fail
        deleteCache()
        
        // If there is not yet a local archive path, save the sales locally
        if !NSFileManager.defaultManager().fileExistsAtPath(localArchivePath) {
            saveDataToLocalPath(localArchivePath)
        }
        var error: NSError?
        NSFileManager.defaultManager().moveItemAtPath(localArchivePath, toPath: cachePath, error: &error)
        
        if error != nil {
            println("NotificationStore: Error moving data from Documents to Cache : \(error!.localizedDescription)")
        }
    }
    
    
    func deleteCache() {
        let fileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(cachePath) {
            var error: NSError?
            fileManager.removeItemAtPath(cachePath, error: &error)
            
            if error != nil {
                println("NotificationStore: Error deleting Cache : \(error!.localizedDescription)")
            }
        }
        
    }

    
    
    // MARK: Saving / loading data from the Cloud
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
    var notificationStoreRecord: CKRecord!

    
    /** Load the allNotifications array from the CKRecords in iCloud */
    func loadDataFromCloud(completionHandler: (loadingError: NSError!) -> ()) {
        
        // Get the CKRecord corresponding to the NotificationStore
        // Check if there is already a NotificationStore CKRecord
        var query = CKQuery(recordType: CloudManager.Constants.RecordTypeNotificationStore, predicate: NSPredicate(value: true))
        privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (records, queryError) in
            if queryError != nil {
                println("NotificationStore: Error fetching the NotificationStore: \(queryError.localizedDescription)")
                completionHandler(loadingError: queryError)
                
            } else {
                if records.count > 0 {
                    let notificationStoreRecord = records.first as! CKRecord
                    
                    // Get a hold on the NotificationStore CKRecord
                    self.notificationStoreRecord = notificationStoreRecord

                    // Define the NotificationStore record as a reference for the Notification records
                    let reference = CKReference(record: notificationStoreRecord, action: .DeleteSelf)
                    
                    // Get all records corresponding to notifications
                    let predicate = NSPredicate(format: "%K == %@", CloudManager.Constants.RecordTypeNotificationStore, reference)
                    var query = CKQuery(recordType: CloudManager.Constants.RecordTypeNotification, predicate: predicate)
                    self.privateDatabase.performQuery(query, inZoneWithID: nil) { (notificationRecords, error) in
                        if error != nil {
                            // Handle error
                            println("NotificationStore: Error loading records: \(error.localizedDescription)")
                            completionHandler(loadingError: error)
                            
                        } else {
                            if let salesRecords = notificationRecords as? [CKRecord] {
                                var notificationsArray = salesRecords.map { StockNotification.notificationFromCloudRecord($0) }

                                // Recreate the allNotifications array
                                if notificationsArray.count > 0 {
                                    // sort array by stock symbol descending
                                    sort(&notificationsArray) { $0.stock?.symbol < $1.stock?.symbol }

                                    self.allNotifications = notificationsArray
                                }
                            }
                            println("NotificationStore: notifications loaded from iCloud")
                            completionHandler(loadingError: nil)
                        }
                    }
                } else { // No NotificationStore
                    println("No NotificationStore found!")
                    completionHandler(loadingError: nil)
                }
            }
        })
    }
    
    
    
    /** Copy all Notifications to iCloud */
    func copyDataToCloud(completionHandler: (copyError: NSError!) -> ()) {
        
        // Create a New NotificationStore CKRecord
        var notificationStoreRecord = CKRecord(recordType: CloudManager.Constants.RecordTypeNotificationStore)
        notificationStoreRecord.setObject(CloudManager.Constants.RecordTypeNotificationStore, forKey: "name")
        
        // Define the NotificationStore record as a reference for the Notification records
        let reference = CKReference(record: notificationStoreRecord, action: .DeleteSelf)
        
        // Create the Notification CKRecords
        let notificationRecords = self.allNotifications.map { StockNotification.cloudRecordFromNotification($0) }
        for notificationRecord in notificationRecords {
            notificationRecord.setObject(reference, forKey: CloudManager.Constants.RecordTypeNotificationStore)
        }
        
        // Save NotificationStore Record to the DB
        privateDatabase.saveRecord(notificationStoreRecord, completionHandler: { (notificationStoreRecord, saveError) in
            
            if saveError != nil {
                println("NotificationStore: Error saving NotificationStore: \(saveError.localizedDescription)")
                completionHandler(copyError: saveError)
                
            } else {
                // Get a hold on the NotificationStore CKRecord
                self.notificationStoreRecord = notificationStoreRecord
                
                // Copy sales to iCloud
                if notificationRecords.count > 0 {
                    // Create an operation to save all the Notification CKRecords to the DB
                    var uploadOperation = CKModifyRecordsOperation(recordsToSave: notificationRecords, recordIDsToDelete: nil)
                    uploadOperation.savePolicy = .IfServerRecordUnchanged // default
                    uploadOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
                        
                        if error != nil {
                            println("NotificationStore: Error saving records: \(error.localizedDescription)")
                            completionHandler(copyError: error)
                            
                        } else {
                            println("NotificationStore: Successfully saved records")
                            completionHandler(copyError: nil)
                        }
                    }
                    
                    self.privateDatabase.addOperation(uploadOperation)
                    
                } else { // No notification to move
                    println("NotificationStore: no notification to save")
                    completionHandler(copyError: nil)
                }
                
            }
        })
        
    }
    
    
    /** Add a CKRecord to iCloud */
    func addRecordToCloud(notification: StockNotification) {
        if CloudManager.sharedManager.cloudActivated {
            
            let notificationRecord = StockNotification.cloudRecordFromNotification(notification)
            let reference = CKReference(record: self.notificationStoreRecord, action: .DeleteSelf)
            notificationRecord.setObject(reference, forKey: CloudManager.Constants.RecordTypeNotificationStore)
            
            // Save the CKRecord in the DB for this sale
            privateDatabase.saveRecord(notificationRecord, completionHandler: { (record, error) in
                if error != nil {
                    println("NotificationStore: could not add CKRecord")
                } else {
                    println("NotificationStore: CKRecord added")
                }
            })
        }
        
    }
    
    
    
    /** Remove the record for a given notification from the iCloud NotificationStore */
    func removeRecordFromCloud(notificationToRemove: StockNotification) {
        if CloudManager.sharedManager.cloudActivated {
            // The record to remove has a recordName corresponding to the sale uniqueIdentifier
            if let recordName = notificationToRemove.cloudIdentifier {
                
                // Remove the CKRecord for this stock
                privateDatabase.deleteRecordWithID(CKRecordID(recordName: recordName), completionHandler: { (recordID, error) in
                    if error != nil {
                        println("NotificationStore: could not remove record")
                    } else {
                        println("NotificationStore: CKRecord removed")
                    }
                })
            }
        }
    }
    
    
    /** Removes all notification records from the NotificationStore (without removing the NotificationStore CKRecord itself) */
    func removeAllNotificationRecordsFromCloud() {
        
        if CloudManager.sharedManager.cloudActivated {
            // Remove all notification CKRecords from iCloud
            var query = CKQuery(recordType: CloudManager.Constants.RecordTypeNotification, predicate: NSPredicate(value: true))
            privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (notificationRecords, error) -> Void in
                if error != nil {
                    println("NotificationStore : Could not query the notification records")
                } else {
                    if notificationRecords.count > 0 {
                        let recordsIDsToDeleteArray = notificationRecords.map { $0.recordID }
                        
                        
                        // Create an operation to remove all the Notification CKRecords from the DB
                        var deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsIDsToDeleteArray)
                        deleteOperation.savePolicy = .IfServerRecordUnchanged // default
                        deleteOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
                            
                            if error != nil {
                                println("NotificationStore: Error deleting records: \(error.localizedDescription)")
                                
                            } else {
                                println("NotificationStore: Successfully deleted records")
                            }
                        }
                        
                        self.privateDatabase.addOperation(deleteOperation)
                    }
                }
            })
        }
    }
    
    
    
    /** Delete the NotificationStore and all notification records form iCloud */
    func deleteAllRecordsFromCloud(completionHandler: (deletionError: NSError!) -> ()) {
        
        // Delete the CKRecord corresponding to the NotificationStore
        // As a consequence, all notifications CKRecords will be deleted in chain
        
        // Check if there is already a NotificationStore CKRecord
        var query = CKQuery(recordType: CloudManager.Constants.RecordTypeNotificationStore, predicate: NSPredicate(value: true))
        privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (records, error) in
            if error != nil {
                println("Error fetching NotificationStore: \(error.localizedDescription)")
                completionHandler(deletionError: error)
                
            } else {
                if records.count > 0 {
                    let notificationStoreRecord = records.first as! CKRecord
                    let notificationStoreRecordID = notificationStoreRecord.recordID
                    
                    
                    self.privateDatabase.deleteRecordWithID(notificationStoreRecordID, completionHandler: { (notificationStoreRecordID, deleteError) in
                        if deleteError != nil {
                            println("NotificationStore: Error deleting the NotificationStore: \(deleteError.localizedDescription)")
                            completionHandler(deletionError: deleteError)
                        } else {
                            println("NotificationStore: Successfully deleted the NotificationStore and all corresponding notifications")
                            // Re-init store record property
                            self.notificationStoreRecord = nil
                            completionHandler(deletionError: nil)
                        }
                    })
                } else { // No NotificationStore
                    completionHandler(deletionError: nil)
                }
            }
        })
    }

    
    // MARK: CKSubscriptions
    func addStockNotificationFromNotification(record: CKRecord) {
        let record = CKRecord(recordType: CloudManager.Constants.RecordTypeNotification, recordID: record.recordID)
        let notif = StockNotification.notificationFromCloudRecord(record)
        
        allNotifications.append(notif)
        
        // sort array by stock symbol descending
        sort(&allNotifications) { $0.stock?.symbol < $1.stock?.symbol }
    }
    
    
    
    /** Retrieve the stockNotification in the allNotifications array corresponding to a given recordID */
    func itemMatching(recordID: CKRecordID) -> (item: StockNotification!, index: Int) {
        
        var index = NSNotFound
        var notification: StockNotification!
        for (idx, item) in enumerate(allNotifications) {
            if item.cloudIdentifier == recordID.recordName {
                index = idx
                notification = item
                break
            }
        }
        return (notification, index: index)
    }
    
    
    func removeStockNotificationFromNotification(recordID: CKRecordID) {
        // Identify stockNotification from recordID.recordName = notification.cloudIdentifier
        var (notification, index) = self.itemMatching(recordID)
        if index == NSNotFound {
            return
        }
        
        allNotifications.removeAtIndex(index)
    }
    
}