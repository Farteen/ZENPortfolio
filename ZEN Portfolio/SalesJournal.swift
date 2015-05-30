//
//  SalesJournal.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 13/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import CloudKit

@objc(ZENSalesJournal) class SalesJournal {
    // Need to reference the old Obj-C class name to retrieve the archive
    
    
    // MARK: Singleton
    static let sharedStore = SalesJournal()
    
    // MARK: Properties
    var allEntries = [Sale]()
    
    
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
    
    
   
    
    // MARK: Methods for sales management
    /** Create a new sales entry and adds it to the "allEntries" array */
    func createSale(#symbol: String, name: String, currency: String, saleDate:NSDate, numberOfSharesSold: Int, purchaseSharePrice : Double, sellingSharePrice: Double, purchaseCurrencyRate: Double, sellingCurrencyRate: Double) -> Sale {
        var sale = Sale(
            symbol: symbol,
            name: name,
            currency: currency,
            saleDate:saleDate,
            numberOfSharesSold: numberOfSharesSold,
            purchaseSharePrice : purchaseSharePrice,
            sellingSharePrice: sellingSharePrice,
            purchaseCurrencyRate: purchaseCurrencyRate,
            sellingCurrencyRate: sellingCurrencyRate)
        
        allEntries.append(sale)
        
        // sort array by saleDate descending
        sort(&allEntries) { $0.saleDate.compare($1.saleDate) == NSComparisonResult.OrderedDescending }
        
        
        // Track event in Analytics
        if let tracker = GAI.sharedInstance().defaultTracker {
            let event = GAIDictionaryBuilder.createEventWithCategory("Stock management", action: "New Sale", label: sale.symbol, value: nil).build() as [NSObject : AnyObject]
            tracker.send(event)
        }
        
        return sale
    }
    
    
    /** Remove a given sale from the Sales journal */
    func removeEntry(saleToRemove: Sale) {
        if let index = find(allEntries, saleToRemove) {
            allEntries.removeAtIndex(index)
        }
    }
    
    /** Remove all sales from the SalesJournal */
    func removeAllEntries() {
        
        allEntries.removeAll()
        println("SalesJournal : all Sales journal entries were deleted")
    }
    
    
    
    // MARK: - Persistence management
    private let FileName = "salesJournal.archive"
    
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
        if let salesArray = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [Sale] {
            allEntries = salesArray
        }
    }
    
    /** Save the allEntries array to an archived file on disk */
    func saveDataToLocalPath(path: String) -> Bool {
        return NSKeyedArchiver.archiveRootObject(allEntries, toFile:path)
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
            println("SalesJournal: Error moving data from Documents to Cache : \(error!.localizedDescription)")
        }
    }
    
    
    func deleteCache() {
        let fileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(cachePath) {
            var error: NSError?
            fileManager.removeItemAtPath(cachePath, error: &error)
            
            if error != nil {
                println("SalesJournal: Error deleting Cache : \(error!.localizedDescription)")
            }
        }
        
    }

    
    
    // MARK: Saving / loading data from the Cloud
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
    var salesJournalRecord: CKRecord!
    
    /** Load the allEntries array from the CKRecords in iCloud */
    func loadDataFromCloud(completionHandler: (loadingError: NSError!) -> ()) {
        
        // Get the CKRecord corresponding to the SalesJournal
        // Check if there is already a SalesJournal CKRecord
        var query = CKQuery(recordType: CloudManager.Constants.RecordTypeSalesJournal, predicate: NSPredicate(value: true))
        privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (records, queryError) in
            if queryError != nil {
                println("SalesJournal: Error fetching the SalesJournal: \(queryError.localizedDescription)")
                completionHandler(loadingError: queryError)
                
            } else {
                if records.count > 0 {
                    let salesJournalRecord = records.first as! CKRecord
                    
                    // Get a hold on the SalesJournal CKRecord
                    self.salesJournalRecord = salesJournalRecord

                    // Define the SalesJournal record as a reference for the Sale records
                    let reference = CKReference(record: salesJournalRecord, action: .DeleteSelf)
                    
                    // Get all records corresponding to sales
                    let predicate = NSPredicate(format: "%K == %@", CloudManager.Constants.RecordTypeSalesJournal, reference)
                    var query = CKQuery(recordType: CloudManager.Constants.RecordTypeSale, predicate: predicate)
                    self.privateDatabase.performQuery(query, inZoneWithID: nil) { (salesRecords, error) in
                        if error != nil {
                            // Handle error
                            println("SalesJournal: Error loading records: \(error.localizedDescription)")
                            completionHandler(loadingError: error)
                            
                        } else {
                            if let salesRecords = salesRecords as? [CKRecord] {
                                
                                // Recreate the allEntries array
                                if salesRecords.count > 0 {
                                    var salesArray = salesRecords.map { Sale.saleFromCloudRecord($0) }
                                    // sort array by saleDate descending
                                    sort(&salesArray) { $0.saleDate.compare($1.saleDate) == NSComparisonResult.OrderedDescending }
                                    self.allEntries = salesArray
                                    
                                }
                            }
                            println("SalesJournal: Sales loaded from iCloud")
                            completionHandler(loadingError: nil)
                        }
                    }
                } else { // No SalesJournal
                    println("No SalesJournal found!")
                    completionHandler(loadingError: nil)
                }
            }
        })
    }
    
    
    
    /** Copy all Sales to iCloud */
    func copyDataToCloud(completionHandler: (copyError: NSError!) -> ()) {
        
        // Create a New SalesJournal CKRecord
        var salesJournalRecord = CKRecord(recordType: CloudManager.Constants.RecordTypeSalesJournal)
        salesJournalRecord.setObject(CloudManager.Constants.RecordTypeSalesJournal, forKey: "name")
        
        // Define the SalesJournal record as a reference for the Sale records
        let reference = CKReference(record: salesJournalRecord, action: .DeleteSelf)
        
        // Create the Sale CKRecords
        let salesRecords = self.allEntries.map { Sale.cloudRecordFromSale($0) }
        for saleRecord in salesRecords {
            saleRecord.setObject(reference, forKey: CloudManager.Constants.RecordTypeSalesJournal)
        }
        
        // Save SalesJournal Record to the DB
        privateDatabase.saveRecord(salesJournalRecord, completionHandler: { (salesJournalRecord, saveError) in
            
            if saveError != nil {
                println("SalesJournal: Error saving SalesJournal: \(saveError.localizedDescription)")
                completionHandler(copyError: saveError)
                
            } else {
                // Get a hold on the SalesJournal CKRecord
                self.salesJournalRecord = salesJournalRecord

                // Copy sales to iCloud
                if salesRecords.count > 0 {
                    // Create an operation to save all the Sale CKRecords to the DB
                    var uploadOperation = CKModifyRecordsOperation(recordsToSave: salesRecords, recordIDsToDelete: nil)
                    uploadOperation.savePolicy = .IfServerRecordUnchanged // default
                    uploadOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
                        
                        if error != nil {
                            println("SalesJournal: Error saving records: \(error.localizedDescription)")
                            completionHandler(copyError: error)
                            
                        } else {
                            println("SalesJournal: Successfully saved records")
                            completionHandler(copyError: nil)
                        }
                    }
                    
                    self.privateDatabase.addOperation(uploadOperation)
                    
                } else { // No sale to move
                    println("SalesJournal: no sale to save")
                    completionHandler(copyError: nil)
                }
                
            }
        })
        
    }
    
    
    /** Add a CKRecord to iCloud */
    func addRecordToCloud(sale: Sale) {
        if CloudManager.sharedManager.cloudActivated {
            
            let saleRecord = Sale.cloudRecordFromSale(sale)
            let reference = CKReference(record: self.salesJournalRecord, action: .DeleteSelf)
            saleRecord.setObject(reference, forKey: CloudManager.Constants.RecordTypeSalesJournal)
            
            // Save the CKRecord in the DB for this sale
            privateDatabase.saveRecord(saleRecord, completionHandler: { (record, error) in
                if error != nil {
                    println("SalesJournal: could not add CKRecord")
                } else {
                    println("SalesJournal: CKRecord added")
                }
            })
        }
        
    }
    
    
    
    /** Remove the record for a given sale from the iCloud SalesJournal */
    func removeRecordFromCloud(saleToRemove: Sale) {
        if CloudManager.sharedManager.cloudActivated {
            // The record to remove has a recordName corresponding to the stock uniqueIdentifier
            let recordName = saleToRemove.cloudIdentifier
            
            // Remove the CKRecord for this stock
            privateDatabase.deleteRecordWithID(CKRecordID(recordName: recordName), completionHandler: { (recordID, error) in
                if error != nil {
                    println("SalesJournal: could not remove record")
                } else {
                    println("StockStore: CKRecord removed")
                }
            })
        }
        
    }
    
    
    /** Removes all sale records from the SalesJournal (without removing the SalesJournal CKRecord itself) */
    func removeAllSaleRecordsFromCloud() {
        
        if CloudManager.sharedManager.cloudActivated {
            // Remove all sale CKRecords from iCloud
            var query = CKQuery(recordType: CloudManager.Constants.RecordTypeSale, predicate: NSPredicate(value: true))
            privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (saleRecords, error) -> Void in
                if error != nil {
                    println("SalesJournal : Could not query the sales records")
                } else {
                    if saleRecords.count > 0 {
                        let recordsIDsToDeleteArray = saleRecords.map { $0.recordID }
                        
                        
                        // Create an operation to remove all the Sale CKRecords from the DB
                        var deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsIDsToDeleteArray)
                        deleteOperation.savePolicy = .IfServerRecordUnchanged // default
                        deleteOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordsIDs, error in
                            
                            if error != nil {
                                println("SalesJournal: Error deleting records: \(error.localizedDescription)")
                                
                            } else {
                                println("SalesJournal: Successfully deleted records")
                            }
                        }
                        
                        self.privateDatabase.addOperation(deleteOperation)
                    }
                }
            })
        }
    }

    
    
    
    /** Delete the SalesJournal and all sale records form iCloud */
    func deleteAllRecordsFromCloud(completionHandler: (deletionError: NSError!) -> ()) {
        
        // Delete the CKRecord corresponding to the SalesJournal
        // As a consequence, all Sale CKRecords will be deleted in chain
        
        // Check if there is already a SalesJournal CKRecord
        var query = CKQuery(recordType: CloudManager.Constants.RecordTypeSalesJournal, predicate: NSPredicate(value: true))
        privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (records, error) in
            if error != nil {
                println("Error fetching SalesJournal: \(error.localizedDescription)")
                completionHandler(deletionError: error)
                
            } else {
                if records.count > 0 {
                    let salesJournalRecord = records.first as! CKRecord
                    let salesJournalRecordID = salesJournalRecord.recordID
                    
                    
                    self.privateDatabase.deleteRecordWithID(salesJournalRecordID, completionHandler: { (salesJournalRecordID, deleteError) in
                        if deleteError != nil {
                            println("SalesJournal: Error deleting the SalesJournal: \(deleteError.localizedDescription)")
                            completionHandler(deletionError: deleteError)
                        } else {
                            println("SalesJournal: Successfully deleted the SalesJournal and all corresponding sales")
                            // Re-init store record property
                            self.salesJournalRecord = nil
                            completionHandler(deletionError: nil)
                        }
                    })
                } else { // No SalesJournal
                    completionHandler(deletionError: nil)
                }
            }
        })
    }
    

    // MARK: CKSubscriptions
    func addSaleFromNotification(record: CKRecord) {
        let record = CKRecord(recordType: CloudManager.Constants.RecordTypeSale, recordID: record.recordID)
        let sale = Sale.saleFromCloudRecord(record)
        
        allEntries.append(sale)
    }
    
    
    
    /** Retrieve the sale in the allEntries array corresponding to a given recordID */
    func itemMatching(recordID: CKRecordID) -> (item: Sale!, index: Int) {
        
        var index = NSNotFound
        var sale: Sale!
        for (idx, item) in enumerate(allEntries) {
            if item.cloudIdentifier == recordID.recordName {
                index = idx
                sale = item
                break
            }
        }
        return (sale, index: index)
    }
    
    
    func removeSaleFromNotification(recordID: CKRecordID) {
        // Identify sale from recordID.recordName = sale.CloudIdentifier
        var (sale, index) = self.itemMatching(recordID)
        if index == NSNotFound {
            return
        }
        
        allEntries.removeAtIndex(index)
        
    }

    
}