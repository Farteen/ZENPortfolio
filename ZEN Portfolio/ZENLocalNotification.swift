//
//  ZENLocalNotification.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation
import UIKit

enum ZENPortfolioNotificationType: Int {
    case Price = 0, StockValue, GainOrLossValue, GainOrLossPercentage
}

class ZENLocalNotification {
    
    // MARK:Properties
    /** The type of notification (on share price, on current stock value, on gain or loss value or on gain or loss percentage). */
    let notificationType: ZENPortfolioNotificationType
    
    /** The stock on which the notification is created. */
    let stock: ZENStock
    
    /** The target level at which the notification should fire and warn the user. */
    let target: Double
    
    /** A boolean defining if the target level is superior or equal to the current level (compareAscending = YES) or inferior to the current level (compareAscending = NO). */
    let compareAscending: Bool
    
    
    // secondary properties (can be derived from the notification type)
    var notificationTypeDescription: String {
        switch notificationType {
            case .Price:
                return  NSLocalizedString("Create Notif Main VC:share price", comment:"SHARE PRICE")
            
            case .StockValue:
                return NSLocalizedString("Create Notif Main VC:stock value", comment:"STOCK VALUE")
            
            case .GainOrLossValue:
                return NSLocalizedString("Create Notif Main VC:gain", comment:"GAIN OR LOSS") // short version of "GAIN OR LOSS VALUE"
            
            case .GainOrLossPercentage:
                return NSLocalizedString("Create Notif Main VC:gain %", comment:"GAIN OR LOSS %")

        }
    }
    
    var targetUnit: String {
        switch notificationType {
            case .Price:
                return stock.currency
        
            case .StockValue:
                return ZENGlobalSettings.sharedStore().portfolioCurrency
            
            case .GainOrLossValue:
                return ZENGlobalSettings.sharedStore().portfolioCurrency
        
            case .GainOrLossPercentage:
                return "%"
        }
    }
    
    var notificationColor: UIColor {
        switch notificationType {
            case .Price:
                return UIColor.zenNotificationSharePriceColor()
                
            case .StockValue:
                return UIColor.zenNotificationStockValueColor()
            
            case .GainOrLossValue:
                return UIColor.zenNotificationGainValueColor()
            
            case .GainOrLossPercentage:
                return UIColor.zenNotificationGainPercentageColor()
        }
    }
    
        

    /*! Designated initializer for the ZENLocalNotification class.
    * param notificationType The type of notification (on share price, on current stock value, on gain or loss value or on gain or loss percentage)
    * param stock The stock on which the notification is created.
    * param target The target level at which the notification should fire and warn the user.
    * param compareAscending A boolean defining if the target level is superior or equal to the current level (compareAscending = YES) or inferior to the current level (compareAscending = NO)
    */
    init(notificationType: ZENPortfolioNotificationType, stock: ZENStock, target: Double, compareAscending: Bool) {
        self.notificationType = notificationType
        self.stock = stock
        self.target = target
        self.compareAscending = compareAscending
    }
}
