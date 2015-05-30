//
//  StockNotification.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


import UIKit

enum StockNotificationType: Int {
    case Price = 0, StockValue, GainOrLossValue, GainOrLossPercentage
    
    var description: String {
        let typeNames = [
            "Price",
            "StockValue",
            "GainOrLossValue",
            "GainOrLossPercentage",
            ]
            
            return typeNames[self.rawValue]
    }
    
    var color: UIColor {
        switch self {
        case .Price:
            return UIColor(red:100.0/255.0, green:180.0/255.0, blue:255.0/255.0, alpha:1.0)
        
        case .StockValue:
            return UIColor(red:150.0/255.0, green:255.0/255.0, blue:150.0/255.0, alpha:1.0)
        
        case .GainOrLossValue:
            return UIColor(red:255.0/255.0, green:150.0/255.0, blue:255.0/255.0, alpha:1.0)
        
        case .GainOrLossPercentage:
            return UIColor(red:150.0/255.0, green:150.0/255.0, blue:255.0/255.0, alpha:1.0)
        }
    }
}

@objc(ZENLocalNotification) class StockNotification: NSObject, NSCoding {
    // Need to reference the old Obj-C class name to retrieve the archive

    
    // MARK: Stored properties
    /** The type of stock notification (on share price, on current stock value, on gain or loss value or on gain or loss percentage). */
    let type: StockNotificationType
    
    /** Unique Identifier which points to the stock for which the notification is created. */
    let stockIdentifier: String!
    
    /** The stock for which the stock notification is created. It is determined based on its Unique Identifier. 
    NB: this is a computed property */
    var stock: Stock? {
        for stock in StockStore.sharedStore.allStocks {
            if stockIdentifier == stock.uniqueIdentifier {
                return stock
            }
        }
        return nil
    }
    
    /** The target level at which the stock notification should fire and warn the user. */
    let target: Double
    
    /** A boolean defining if the target level is superior or equal to the current level (compareAscending = true) or inferior to the current level (compareAscending = false). */
    let compareAscending: Bool
    
    
    /** Unique identifier for this sale, used to keep unicity with the corresponding CKRecord */
    var cloudIdentifier: String!

    
    // Computed properties (can be derived from the notification type)
    var typeDescription: String {
        switch type {
            case .Price:
                return  NSLocalizedString("Create Stock Notif Main VC:share price", comment: "SHARE PRICE")
            
            case .StockValue:
                return NSLocalizedString("Create Stock Notif Main VC:stock value", comment: "STOCK VALUE")
            
            case .GainOrLossValue:
                return NSLocalizedString("Create Stock Notif Main VC:gain", comment: "GAIN OR LOSS") // short version of "GAIN OR LOSS VALUE"
            
            case .GainOrLossPercentage:
                return NSLocalizedString("Create Stock Notif Main VC:gain %", comment: "GAIN OR LOSS %")

        }
    }
    
    var targetUnit: String {
        switch type {
        case .Price:
            if stock != nil {
                return stock!.currency
            }
            // If the stock cannot be determined, assume the stock currency is the portfolio currency
            return GlobalSettings.sharedStore.portfolioCurrency
            
        case .StockValue:
            return GlobalSettings.sharedStore.portfolioCurrency
            
        case .GainOrLossValue:
            return GlobalSettings.sharedStore.portfolioCurrency
            
        case .GainOrLossPercentage:
            return "%"
        }
    }
    
    var color: UIColor {
        return self.type.color
    }
    
    
    

    /** Designated initializer for the StockNotification class.
    - type: The type of notification (on share price, on current stock value, on gain or loss value or on gain or loss percentage)
    - stockIdentifier: Unique Identifier which points to the stock for which the notification is created.
    - target: The target level at which the notification should fire and warn the user.
    - compareAscending: A boolean defining if the target level is superior or equal to the current level (compareAscending = YES) or inferior to the current level (compareAscending = NO)
    */
    init(type: StockNotificationType, stockIdentifier: String, target: Double, compareAscending: Bool) {
        self.type = type
        self.stockIdentifier = stockIdentifier
        self.target = target
        self.compareAscending = compareAscending
    }
    
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        type = StockNotificationType(rawValue: aDecoder.decodeIntegerForKey("type"))!
        stockIdentifier = aDecoder.decodeObjectForKey("stockIdentifier") as? String
        target = aDecoder.decodeDoubleForKey("target")
        compareAscending = aDecoder.decodeBoolForKey("compareAscending")
        
        cloudIdentifier = aDecoder.decodeObjectForKey("cloudIdentifier") as? String
    }
    
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(type.rawValue, forKey:"type")
        if stockIdentifier != nil {
            aCoder.encodeObject(stockIdentifier, forKey: "stockIdentifier")
        }
        aCoder.encodeDouble(target, forKey: "target")
        aCoder.encodeBool(compareAscending, forKey: "compareAscending")
        
        if cloudIdentifier != nil {
            aCoder.encodeObject(cloudIdentifier, forKey:"cloudIdentifier")
        }
    }
}



// MARK: - Conversion from and to CKRecord
import CloudKit
extension StockNotification {
    
    /** Turns a CloudKit record into a StockNotification object */
    class func notificationFromCloudRecord(record: CKRecord) -> StockNotification {
        
        let type = StockNotificationType(rawValue: record.objectForKey("type") as! Int)!
        let stockIdentifier = record.objectForKey("stockIdentifier") as! String
        let target = record.objectForKey("target") as! Double
        
        // Bool is not supported in the CKRecordValue protocol
        let compareAscendingString = record.objectForKey("compareAscending") as! String
        let compareAscending = (compareAscendingString == "true") ? true : false
        
        var notification = StockNotification(type: type, stockIdentifier: stockIdentifier, target: target, compareAscending: compareAscending)
        notification.cloudIdentifier = record.recordID.recordName

        return notification
    }
    
    
    /** Turns a StockNotification object into a CloudKit record */
    class func cloudRecordFromNotification(notification: StockNotification) -> CKRecord {
        
        // Create a CKRecord for the notification
        var notificationRecord = CKRecord(recordType: CloudManager.Constants.RecordTypeNotification)
        notification.cloudIdentifier = notificationRecord.recordID.recordName
        
        notificationRecord.setObject(notification.stock?.symbol, forKey: "name")
        
        // NB: values must conform to CKRecordValue protocol!
        notificationRecord.setObject(notification.type.rawValue as NSNumber, forKey: "type")
        notificationRecord.setObject(notification.stockIdentifier as NSString, forKey: "stockIdentifier")
        notificationRecord.setObject(notification.target as NSNumber, forKey: "target")
        
        // Bool is not supported in the CKRecordValue protocol
        let compareAscendingString = (notification.compareAscending == true) ? "true" : "false"
        notificationRecord.setObject(compareAscendingString as NSString, forKey: "compareAscending")
        
        return notificationRecord
    }
    
}

