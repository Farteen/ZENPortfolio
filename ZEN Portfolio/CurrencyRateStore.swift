//
//  CurrencyRateStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class CurrencyRateStore {
    
    // MARK: Singleton
    static let sharedStore = CurrencyRateStore()

    
    // MARK: Properties
    
    /** Dictionary of currency rates used by the portfolio, presented like  [ EURUSD=X : 1.3624 ] */
    var dictionary = [String : Double]()
    
    /** Returns a sorted array of all the keys on the currency rates dictionary */
    var allKeys: [String] {
    var keysArray = Array(dictionary.keys)
        keysArray.sort {$0 < $1}
        return keysArray
    }

    
    subscript(index: String) -> Double? {
        get {
            return dictionary[index]
        }
        set {
            dictionary[index] = newValue!
            
                println("CurrencyRateStore - updated rate for \(index) : \(newValue!)")
        }
    }
    
    
    func deleteRateForKey(key: String) {
        dictionary.removeValueForKey(key)
    }
    
    
    /** Removes all currency rates from the Currency rate store */
    func deleteAllRates()
    {
        dictionary.removeAll()
    }
    
}