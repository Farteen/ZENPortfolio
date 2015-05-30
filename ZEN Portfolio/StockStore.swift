//
//  StockStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import CloudKit

@objc(ZENStockStore) class StockStore {
    // Need to reference the old Obj-C class name to retrieve the archive
    
    
    // MARK: Singleton
    static let sharedStore = StockStore()
    
    
    // MARK: Properties
    // Stored properties
    var allStocks = [Stock]()
    
    
    // Computed properties
    var portfolioNumberOfShares: Int {
        var numberOfShares = 0
        for stock in allStocks {
            numberOfShares += stock.numberOfShares
        }
        return numberOfShares;
    }
    
    var portfolioTotalCost: Double {
        var portfolioCost = 0.0
        for stock in allStocks {
            portfolioCost += round(stock.costInPortfolioCurrency * 100.0) / 100.0
        }
        return portfolioCost
    }
    
    var portfolioTotalValue: Double {
        var portfolioValue = 0.0
        for stock in allStocks {
            portfolioValue += round(stock.valueInPortfolioCurrency * 100.0) / 100.0
        }
        return portfolioValue
    }
    
    var portfolioGainOrLossValue: Double {
        var portfolioTotalGainValue = 0.0
        for stock in allStocks {
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
    
    
    
    // MARK: Initializer
    init () {
        
        // If iCloud is activated, we first load data from cache on disk, and then refresh local data with the iCloud data
        if CloudManager.sharedManager.cloudActivated {
            loadDataFromLocalPath(cachePath)
            loadDataFromCloud({ loadingError -> () in
                if loadingError != nil {
                    println(loadingError!.localizedDescription)
                } else {
                    // Reload StockListTVC
                    NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockStore_LoadedStocksFromCloud, object: nil)
                }
            })
            
        } else {
            // Load data from data on disk
            loadDataFromLocalPath(localArchivePath)
        }
        
        // NOTIFICATION CENTER
        
        if CloudManager.sharedManager.cloudActivated {
            
            // When stock quotes are updated, update CKRecords with the updated properties of the stocks (currentSharePrice, intradayEvolutionValue, intradayEvolutionPercentage, currentCurrencyRate, lastTradeDate)
            NSNotificationCenter.defaultCenter().addObserverForName(NotificationCenterKeys.StockListVC_DidUpdateStockQuotesNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
                
                // Create the Stock CKRecords
                let stockRecords = self.allStocks.map { Stock.cloudRecordFromStock($0) }
                
                if stockRecords.count > 0 {
                    // Create an operation to update all the Stock CKRecords to the DB
                    var uploadOperation = CKModifyRecordsOperation(recordsToSave: stockRecords, recordIDsToDelete: nil)
                    uploadOperation.savePolicy = .ChangedKeys
                    uploadOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
                        
                        if error != nil {
                            println("StockStore: Error updating records: \(error.localizedDescription)")
                        } else {
                            println("StockStore: Successfully updated records")
                        }
                    }
                    
                    self.privateDatabase.addOperation(uploadOperation)
                }
            }
            
            // Observer for the case of a partial sale : update remaining stock quantity
            NSNotificationCenter.defaultCenter().addObserverForName(NotificationCenterKeys.StockSellVC_DidSellSharePartiallyNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
                
                if let stockIdentifier = notification.userInfo?["stockIdentifier"] as? String, let remainingNumberOfShares = notification.userInfo?["remainingNumberOfShares"] as? Int {
                    let recordID = CKRecordID(recordName: stockIdentifier)
                    self.privateDatabase.fetchRecordWithID(recordID, completionHandler: { (record, error) in
                        if error != nil {
                            println("Could not find the CKRecord for the partially sold stock")
                        } else {
                            record.setObject(remainingNumberOfShares, forKey: "numberOfShares")
                            
                            // Save the record
                            self.privateDatabase.saveRecord(record, completionHandler: { (record, saveError) in
                                if saveError != nil {
                                    println("Error saving the updated stock CKRecord")
                                } else {
                                    println("Successfully updated the stock CKRecord")
                                }
                            })
                        }
                    })
                }
            }
        }
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: Stocks management
    /** Create a new stock item and adds it to the "allStocks" array */
    func createStock(#symbol: String, name: String, market: String, currency: String) -> Stock {
        var stock = Stock(symbol: symbol, name: name, market: market, currency: currency)
        addStock(stock)
        addRecordToCloud(stock)
        
        return stock
    }
    
    
    /** Add an existing stock item to the "allStocks" array */
    func addStock(stock: Stock) {
        
        allStocks.append(stock)
        
        // Track event in Analytics
        if let tracker = GAI.sharedInstance().defaultTracker {
            let event = GAIDictionaryBuilder.createEventWithCategory("Stock management", action: "New Stock", label: stock.symbol, value: nil).build() as [NSObject : AnyObject]
            tracker.send(event)
        }
    }
    
    
    /** Remove a given stock from the StockStore */
    func removeStock(stockToRemove: Stock) {
        
        // Remove corresponding notifications from Stock Notification Store
        let notificationsToRemove = StockNotificationStore.sharedStore.allNotifications.filter { $0.stock == stockToRemove }
        for notificationToRemove in notificationsToRemove {
            StockNotificationStore.sharedStore.removeNotification(notificationToRemove)
            StockNotificationStore.sharedStore.removeRecordFromCloud(notificationToRemove)
        }
        
        // Then remove item
        if let index = find(allStocks, stockToRemove) {
            allStocks.removeAtIndex(index)
        }
        
    }
    
    /** Remove all stocks from the Stock store */
    func removeAllStocks() {
        
        // Remove all notifications from the StockNotificationStore
        StockNotificationStore.sharedStore.removeAllNotifications()
        // Remove all notifications from iCloud
        StockNotificationStore.sharedStore.removeAllNotificationRecordsFromCloud()

        allStocks.removeAll()
        
    }
    
    /** Move a stock item from one index to another in the "allStocks" array */
    func moveStockFromIndex(fromIndex: Int, toIndex: Int) {
        //    [_allStocks exchangeObjectAtIndex:to withObjectAtIndex:from];
        
        
        if fromIndex == toIndex {
            return
        }
        
        // Get pointer to object being moved so we can re-insert it
        let stock = allStocks[fromIndex]
        
        // Remove stock from array
        allStocks.removeAtIndex(fromIndex)
        
        // Insert stock in array at new location
        allStocks.insert(stock, atIndex:toIndex)
    }
    
    
    
    // MARK: - Persistence management
    private let FileName = "stocks.archive"
    private struct Constants {
        static let StockIdentifiers = "stockIdentifiers"
    }
    
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
    
    
    
    // MARK: Saving / loading data from local storage
    /** Load the allStocks array from the archived file on disk */
    func loadDataFromLocalPath(path: String) {
        if let itemsArray = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [Stock] {
            allStocks = itemsArray
            println("Stocks loaded from local (documents or cache)")
        }
    }
    
    
    /** Save the allStocks array to an archived file on disk */
    func saveDataToLocalPath(path: String) -> Bool {
        return NSKeyedArchiver.archiveRootObject(allStocks, toFile:path)
    }
    
    /** Move archive file from Documents to Caches folder */
    func moveDataFromLocalArchiveToCache() {
        
        let fileManager = NSFileManager.defaultManager()
        
        // Delete cache file, in case it exists, because that would make the move operation fail
        deleteCache()
        
        // If there is not yet a local archive path, save the stocks locally
        if !NSFileManager.defaultManager().fileExistsAtPath(localArchivePath) {
            saveDataToLocalPath(localArchivePath)
        }
        var error: NSError?
        NSFileManager.defaultManager().moveItemAtPath(localArchivePath, toPath: cachePath, error: &error)
        
        if error != nil {
            println("StockStore: Error moving data from Documents to Cache : \(error!.localizedDescription)")
        }
    }
    
    
    func deleteCache() {
        let fileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(cachePath) {
            var error: NSError?
            fileManager.removeItemAtPath(cachePath, error: &error)
            
            if error != nil {
                println("StockStore: Error deleting Cache : \(error!.localizedDescription)")
            }
        }
        
    }
    
    
    // MARK: Saving / loading data from the Cloud
    
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
    var stockStoreRecord: CKRecord!
    
    /** Load the allStocks array from the CKRecords in iCloud */
    func loadDataFromCloud(completionHandler: (loadingError: NSError!) -> ()) {
        
        // Get the CKRecord corresponding to the StockStore
        // Check if there is already a StockStore CKRecord
        var query = CKQuery(recordType: CloudManager.Constants.RecordTypeStockStore, predicate: NSPredicate(value: true))
        self.privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (records, queryError) in
            if queryError != nil {
                println("StockStore: Error fetching the StockStore: \(queryError.localizedDescription)")
                completionHandler(loadingError: queryError)
                
            } else {
                if records.count > 0 {
                    let stockStoreRecord = records.first as! CKRecord
                    
                    // Get a hold on the NotificationStore CKRecord
                    self.stockStoreRecord = stockStoreRecord

                    // Retrieve the array giving the correct order for the Stock entries
                    let identifierArray = stockStoreRecord.objectForKey(Constants.StockIdentifiers) as! [String]
                    
                    // Define the stockStore record as a reference for the Stock records
                    let reference = CKReference(record: stockStoreRecord, action: .DeleteSelf)
                    
                    // Get all records corresponding to stocks
                    let predicate = NSPredicate(format: "%K == %@", CloudManager.Constants.RecordTypeStockStore, reference)
                    var query = CKQuery(recordType: CloudManager.Constants.RecordTypeStock, predicate: predicate)
                    self.privateDatabase.performQuery(query, inZoneWithID: nil) { (stockRecords, error) in
                        if error != nil {
                            // Handle error
                            println("StockStore: Error loading records: \(error.localizedDescription)")
                            completionHandler(loadingError: error)
                            
                        } else {
                            var stockArray = [Stock]()
                            if let stockRecords = stockRecords as? [CKRecord] {
                                for identifier in identifierArray {
                                    if let record = filter(stockRecords, { $0.recordID.recordName == identifier }).first {
                                        stockArray.append(Stock.stockFromCloudRecord(record))
                                    }
                                }
                                
                                // Recreate the allStocks array
                                if stockArray.count > 0 {
                                    self.allStocks = stockArray
                                    println(stockArray)
                                }
                            }
                            println("StockStore: Stocks loaded from iCloud")
                            completionHandler(loadingError: nil)
                        }
                    }
                } else { // No StockStore
                    println("No StockStore found!")
                    completionHandler(loadingError: nil)
                }
            }
        })
    }
    
    
    
    /** Copy all Stocks to iCloud */
    func copyDataToCloud(completionHandler: (copyError: NSError!) -> ()) {
        
        // Create a New StockStore CKRecord
        var stockStoreRecord = CKRecord(recordType: CloudManager.Constants.RecordTypeStockStore)
        stockStoreRecord.setObject(CloudManager.Constants.RecordTypeStockStore, forKey: "name")
        
        // Define the StockStore record as a reference for the Stock records
        let reference = CKReference(record: stockStoreRecord, action: .DeleteSelf)
        
        // Create the Stock CKRecords
        let stockRecords = self.allStocks.map { Stock.cloudRecordFromStock($0) }
        for stockRecord in stockRecords {
            stockRecord.setObject(reference, forKey: CloudManager.Constants.RecordTypeStockStore)
        }
        
        // Keep track of the order of the stocks array in the StockStore record
        let identifierArray = stockRecords.map { $0.recordID.recordName }
        stockStoreRecord.setObject(identifierArray, forKey: Constants.StockIdentifiers)
        
        // Save StockStore Record to the DB
        privateDatabase.saveRecord(stockStoreRecord, completionHandler: { (stockStoreRecord, saveError) in
            
            if saveError != nil {
                println("StockStore: Error saving stockStore: \(saveError.localizedDescription)")
                self.stockStoreRecord = nil
                completionHandler(copyError: saveError)
                
            } else {
                // Get a hold on the NotificationStore CKRecord
                self.stockStoreRecord = stockStoreRecord

                // Copy stocks to iCloud
                if stockRecords.count > 0 {
                    // Create an operation to save all the Stock CKRecords to the DB
                    var uploadOperation = CKModifyRecordsOperation(recordsToSave: stockRecords, recordIDsToDelete: nil)
                    uploadOperation.savePolicy = .IfServerRecordUnchanged // default
                    uploadOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
                        
                        if error != nil {
                            println("StockStore: Error saving records: \(error.localizedDescription)")
                            completionHandler(copyError: error)
                            
                        } else {
                            println("StockStore: Successfully saved records")
                            completionHandler(copyError: nil)
                        }
                    }
                    
                    self.privateDatabase.addOperation(uploadOperation)
                    
                } else { // No stocks to move
                    println("StockStore: no stocks to save")
                    completionHandler(copyError: nil)
                }
            }
        })
        
    }
    
    
    /** Add a CKRecord to iCloud */
    func addRecordToCloud(stock: Stock) {
        if CloudManager.sharedManager.cloudActivated {
            
            // Check that the stockStoreRecord property is not nil (to use it as a reference)
            if stockStoreRecord != nil {
                
                let stockRecord = Stock.cloudRecordFromStock(stock)
                let reference = CKReference(record: stockStoreRecord, action: .DeleteSelf)
                stockRecord.setObject(reference, forKey: CloudManager.Constants.RecordTypeStockStore)
                
                // Save the CKRecord in the DB for this stock
                privateDatabase.saveRecord(stockRecord, completionHandler: { (record, error) in
                    if error != nil {
                        println("StockStore: could not add record")
                    } else {
                        // Update the stockIdentifiers of the stockStore CKRecord accordingly
                        if var stockIdentifiers = self.stockStoreRecord.objectForKey(Constants.StockIdentifiers) as? [String] {
                            stockIdentifiers.append(record.recordID.recordName)
                            self.stockStoreRecord.setObject(stockIdentifiers, forKey: Constants.StockIdentifiers)
                            
                            self.privateDatabase.saveRecord(self.stockStoreRecord, completionHandler: { (stockStoreRecord, error) in
                                if error != nil {
                                    println("StockStore: could not save StockStore")
                                } else {
                                    println("StockStore: CKRecord added")
                                }
                            })
                        }
                    }
                })
            }
        }
    }
    
    
    /** Move a record identifier from one index to another in the iCloud  StocStore "stockIdentifiers" array */
    func moveRecordInCloudFromIndex(fromIndex: Int, toIndex: Int) {
        
        // If iCloud is activated, update the StockStore CKRecord "stockIdentifiers" attribute, in order to retain the order of stocks chosen by the user.
        if CloudManager.sharedManager.cloudActivated {
            if var stockIdentifiers = stockStoreRecord.objectForKey(Constants.StockIdentifiers) as? [String] {
                // Get pointer to object being moved so we can re-insert it
                let stockID = stockIdentifiers[fromIndex]
                // Remove stockID from array
                stockIdentifiers.removeAtIndex(fromIndex)
                // Insert stockID in array at new location
                stockIdentifiers.insert(stockID, atIndex:toIndex)
                self.stockStoreRecord.setObject(stockIdentifiers, forKey: Constants.StockIdentifiers)
                
                self.privateDatabase.saveRecord(self.stockStoreRecord, completionHandler: { (stockStoreRecord, error) in
                    if error != nil {
                        println("StockStore: could not save StockStore")
                    } else {
                        println("StockStore: CKRecord moved")
                    }
                })
            }
        }
        
    }
    
    /** Remove the record for a given stock from the iCloud StockStore */
    func removeRecordFromCloud(stockToRemove: Stock) {
        if CloudManager.sharedManager.cloudActivated {
            // The record to remove has a recordName corresponding to the stock uniqueIdentifier
            let recordName = stockToRemove.uniqueIdentifier
            
            // Remove the CKRecord for this stock
            privateDatabase.deleteRecordWithID(CKRecordID(recordName: recordName), completionHandler: { (recordID, error) in
                if error != nil {
                    println("StockStore: could not remove record")
                } else {
                    // Update the stockIdentifiers of the stockStore CKRecord accordingly
                    if var stockIdentifiers = self.stockStoreRecord.objectForKey(Constants.StockIdentifiers) as? [String] {
                        // Remove entry corresponding to the stockIdentifier
                        if let index = find(stockIdentifiers, recordID.recordName) {
                            stockIdentifiers.removeAtIndex(index)
                        }
                        self.stockStoreRecord.setObject(stockIdentifiers, forKey: Constants.StockIdentifiers)
                        
                        self.privateDatabase.saveRecord(self.stockStoreRecord, completionHandler: { (stockStoreRecord, error) in
                            if error != nil {
                                println("StockStore: could not save StockStore")
                            } else {
                                println("StockStore: CKRecord removed")
                            }
                        })
                    }
                }
            })
        }
    }
    
    
    /** Remove all stock records from the StockStore (without removing the StockStore CKRecord itself) */
    func removeAllStockRecordsFromCloud() {
        
        if CloudManager.sharedManager.cloudActivated {
            // Remove all stock CKRecords from iCloud
            let recordNamesToDeleteArray = stockStoreRecord.objectForKey(Constants.StockIdentifiers) as! [String]
            let recordsIDsToDeleteArray = recordNamesToDeleteArray.map { CKRecordID(recordName: $0) }
            
            // Create an operation to remove all the Stock CKRecords from the DB
            var deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsIDsToDeleteArray)
            deleteOperation.savePolicy = .IfServerRecordUnchanged // default
            deleteOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
                
                if error != nil {
                    println("StockStore: Error deleting records: \(error.localizedDescription)")
                    
                } else {
                    println("StockStore: Successfully deleted records")
                    // Now remove the stockIdentifiers from the StockStore CKRecord
                    if var stockIdentifiers = self.stockStoreRecord.objectForKey(Constants.StockIdentifiers) as? [String] {
                        stockIdentifiers.removeAll(keepCapacity: true)
                        self.stockStoreRecord.setObject(stockIdentifiers, forKey: Constants.StockIdentifiers)
                        
                        self.privateDatabase.saveRecord(self.stockStoreRecord, completionHandler: { (stockStoreRecord, error) in
                            if error != nil {
                                println("StockStore: could not save StockStore")
                            } else {
                                println("StockStore: CKRecord removed")
                            }
                        })
                    }
                    
                }
            }
            
            self.privateDatabase.addOperation(deleteOperation)
        }
        
    }
    
    
    /** Delete the StockStore and all stock records form iCloud */
    func deleteAllRecordsFromCloud(completionHandler: (deletionError: NSError!) -> ()) {
        
        // Delete the CKRecord corresponding to the stockStore
        // As a consequence, all Stock CKRecords will be deleted in chain
        
        // Check if there is already a StockStore CKRecord
        var query = CKQuery(recordType: CloudManager.Constants.RecordTypeStockStore, predicate: NSPredicate(value: true))
        privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (records, error) in
            if error != nil {
                println("Error fetching stockStore: \(error.localizedDescription)")
                completionHandler(deletionError: error)
                
            } else {
                if records.count > 0 {
                    let stockStoreRecord = records.first as! CKRecord
                    let recordID = stockStoreRecord.recordID
                    
                    self.privateDatabase.deleteRecordWithID(recordID, completionHandler: { (recordID, deleteError) in
                        if deleteError != nil {
                            println("StockStore: Error deleting the stockStore: \(deleteError.localizedDescription)")
                            completionHandler(deletionError: deleteError)
                        } else {
                            println("Stockstore: Successfully deleted the StockStore and all corresponding stocks")
                            // Re-init store record property
                            self.stockStoreRecord = nil
                            completionHandler(deletionError: nil)
                        }
                    })
                } else { // No StockStore
                    completionHandler(deletionError: nil)
                }
            }
        })
    }

    
    // MARK: CKSubscriptions
    
    func addStockFromNotification(record: CKRecord) {
        let record = CKRecord(recordType: CloudManager.Constants.RecordTypeStock, recordID: record.recordID)
        let stock = Stock.stockFromCloudRecord(record)
        
        allStocks.append(stock)
        
        // Post notification to update the StockList tableView
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockStore_StockCreatedFromSubscription, object: nil, userInfo: [ "index" : "\(allStocks.last)" ])
    }
    
    
    
    /** Retrieve the stock in the allStocks array corresponding to a given recordID */
    func itemMatching(recordID: CKRecordID) -> (item: Stock!, index: Int) {
        
        var index = NSNotFound
        var stock: Stock!
        for (idx, item) in enumerate(allStocks) {
            if item.uniqueIdentifier == recordID.recordName {
                index = idx
                stock = item
                break
            }
        }
        return (stock, index: index)
    }
    
    
    func updateStockFromNotification(recordID: CKRecordID) {
        // Identify stock from recordID.recordName = stock.uniqueIdentifier
        var (stock, index) = itemMatching(recordID)
        if index == NSNotFound {
            return
        }

        allStocks[index] = stock
        
        // Post notification to update the StockList tableView
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockStore_StockCreatedFromSubscription, object: nil, userInfo: [ "index" : "\(allStocks.last)" ])
    }
    
    func removeStockFromNotification(recordID: CKRecordID) {
        // Identify stock from recordID.recordName = stock.uniqueIdentifier
        var (stock, index) = itemMatching(recordID)
        if index == NSNotFound {
            return
        }

        allStocks.removeAtIndex(index)
        
        // Post notification to update the StockList tableView
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockStore_StockDeletedFromSubscription, object: nil, userInfo: [ "index" : "\(index)" ])
    }
    
    
    
}

