//
//  ZENGlobalSettings.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENGlobalSettings {
   
    // MARK: Singleton
    class func sharedStore() -> ZENGlobalSettings! {
        struct Static {
            static var instance: ZENGlobalSettings?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ZENGlobalSettings()
        }
        
        return Static.instance!
    }
    
    // MARK: Portfolio Currency
    var portfolioCurrency: String {
    get {
        // Point to NSUserDefaults to retrieve the portfolio currency
        return NSUserDefaults.standardUserDefaults().stringForKey("ZENPortfolioCurrencyPrefKey")
    }
    set {
        // Stock the portfolio currency as NSUserDefaults
        NSUserDefaults.standardUserDefaults().setObject(newValue, forKey:"ZENPortfolioCurrencyPrefKey")
        println("Saved portfolio currency \(newValue) as NSUserDefaults")
    }
    }
    
    // MARK: Update Frequency
    var updateFrequency: Int {
    get {
        // Point to NSUserDefaults to retrieve the update Frequency in mn
        return NSUserDefaults.standardUserDefaults().integerForKey("ZENPortfolioUpdateFreqKey")
    }
    set {
        // Stock the update frequency as NSUserDefaults
        NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey:"ZENPortfolioUpdateFreqKey")
        println("Saved update frequency \(newValue) mn as NSUserDefaults")
    }
    }

    // MARK: Automatic Update On / Off
    var automaticUpdate: Bool {
    get {
        // Point to NSUserDefaults to retrieve the automatic update bool
        return NSUserDefaults.standardUserDefaults().boolForKey("ZENPortfolioAutomaticUpdateKey")
    }
    set {
        // Stock the automatic update bool as NSUserDefaults
        NSUserDefaults.standardUserDefaults().setBool(newValue, forKey:"ZENPortfolioAutomaticUpdateKey")
        let automaticUpdateString = newValue ? "YES" : "NO"
        println("Saved automatic update \(automaticUpdateString) as NSUserDefaults")
    }
    }

    
    // MARK: Current theme
    var currentThemeNumber: Int {
    get {
        // Point to NSUserDefaults to retrieve the current theme number
        return NSUserDefaults.standardUserDefaults().integerForKey("ZENPortfolioCurrentThemeKey")
    }
    set {
        // Stock the current theme number as NSUserDefaults
        NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey:"ZENPortfolioCurrentThemeKey")
        if let themeName = ZENTheme.fromRaw(newValue)?.name {
            println("Saved current theme \"\(themeName)\" as NSUserDefaults")
            println(NSUserDefaults.standardUserDefaults().persistentDomainForName(NSBundle.mainBundle().bundleIdentifier))
        }
    }
    }
}