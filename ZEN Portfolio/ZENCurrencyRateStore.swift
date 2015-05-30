//
//  ZENCurrencyRateStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENCurrencyRateStore {
    
    // MARK: Singleton
    class func sharedStore() -> ZENCurrencyRateStore! {
        struct Static {
            static var instance: ZENCurrencyRateStore?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ZENCurrencyRateStore()
        }
        
        return Static.instance!
    }
    
    // MARK: Properties
    
    /** Dictionary of currency rates used by the portfolio, presented like EURUSD=X : 1.3624 */
    var dictionary = Dictionary <String, Double>()
    
    /** Returns a sorted array of all the keys on the currency rates dictionary */
    var allKeys: String[] {
    var keysArray = Array(dictionary.keys)
        keysArray.sort {$0 < $1}
        return keysArray
    }
    
    
    init() {
        
        // TODO: check if this is correct ...
        if let currencyRateDictionary: AnyObject = NSKeyedUnarchiver.unarchiveObjectWithFile(currencyRateArchivePath) {
            dictionary = currencyRateDictionary as Dictionary <String, Double>
        }
    }
    
    
    subscript(index: String) -> Double? {
        get {
            if let value = dictionary[index] {
                return value
            }
            return nil
        }
        set(newValue) {
            dictionary[index] = newValue
            println("ZENCurrencyRateStore - Updated rate for \(index) : \(newValue)")
        }
    }
    
    /** Removes all currency rates from the Currency rate store */
    func deleteAllRates()
    {
        dictionary.removeAll()
    }
    
    
    // MARK: Archive items in CurrencyRateStore
    var currencyRateArchivePath: String { // Archive path
    var documentDirectories: Array = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        // Get the only document directory from that list
        let documentDirectory: AnyObject = documentDirectories[0]
        
        return documentDirectory.stringByAppendingPathComponent("currencyRates.archive")
    }
    
    func saveChanges()-> Bool
    {
        // return success or failure
        return NSKeyedArchiver.archiveRootObject(dictionary, toFile: currencyRateArchivePath)
    }
}