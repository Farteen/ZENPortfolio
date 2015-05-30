//
//  GlobalSettings.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class GlobalSettings {
    
    // MARK: Singleton
    static let sharedStore = GlobalSettings()
    
    
    /** Constant: update frequency (in minutes) */
    let DefaultUpdateFrequency = 10
    
    
    // MARK: Portfolio Currency
    var portfolioCurrency: String {
        get {
            // Point to NSUserDefaults to retrieve the portfolio currency
            return NSUserDefaults.standardUserDefaults().stringForKey(Defaults.CurrencyPrefKey)!
        }
        set {
            // Stock the portfolio currency as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: Defaults.CurrencyPrefKey)
            println("Saved portfolio currency \(newValue) as NSUserDefaults")
        }
    }
    
    // MARK: Update Frequency
    var updateFrequency: Int {
        get {
            // Point to NSUserDefaults to retrieve the update Frequency in mn
            return NSUserDefaults.standardUserDefaults().integerForKey(Defaults.UpdateFreqKey)
        }
        set {
            // Stock the update frequency as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: Defaults.UpdateFreqKey)
            println("Saved update frequency \(newValue) mn as NSUserDefaults")
        }
    }
    
    // MARK: Automatic Update On / Off
    var automaticUpdate: Bool {
        get {
            // Point to NSUserDefaults to retrieve the automatic update bool
            return NSUserDefaults.standardUserDefaults().boolForKey( Defaults.AutomaticUpdateKey)
        }
        set {
            // Stock the automatic update bool as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey:  Defaults.AutomaticUpdateKey)
            let automaticUpdateString = newValue ? "YES" : "NO"
            println("Saved automatic update \(automaticUpdateString) as NSUserDefaults")
            
            if newValue { // Automatic update = On
                // Set update Frequency to the default value
                updateFrequency = DefaultUpdateFrequency
            }
        }
    }
    
    
    // MARK: Current theme
    var currentThemeNumber: Int {
        get {
            // Point to NSUserDefaults to retrieve the current theme number
            return NSUserDefaults.standardUserDefaults().integerForKey( Defaults.CurrentThemeKey)
        }
        set {
            // Stock the current theme number as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey:  Defaults.CurrentThemeKey)
            if let themeName = Theme(rawValue: newValue)?.description {
                println("Saved current theme \(themeName) as NSUserDefaults")
                //            println(NSUserDefaults.standardUserDefaults().persistentDomainForName(NSBundle.mainBundle().bundleIdentifier))
            }
        }
    }
    
    // Secondary property: shortcut to get the currentTheme from the currentThemeNumber
    var currentTheme: Theme {
        if let theme = Theme(rawValue: GlobalSettings.sharedStore.currentThemeNumber) {
            return theme
        }
        return Theme.Void // This should not happen, since the "default" theme is initialized in AppDelegate
    }
    
    
    // MARK: Main screen button cycle
    var variableValueMode: Int {
        get {
            // Point to NSUserDefaults to retrieve the current variable value mode
            return NSUserDefaults.standardUserDefaults().integerForKey( Defaults.VariableValueModePrefKey)
        }
        set {
            // Stock the current variable value mode as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey:  Defaults.VariableValueModePrefKey)
            println("Saved variable value mode \(newValue) as NSUserDefaults")
        }
    }
    
    var buttonCycleArray: [Dictionary <String, Bool>] {
        
        get {
            // Point to NSUserDefaults to retrieve the current button cycle array
            return NSUserDefaults.standardUserDefaults().arrayForKey( Defaults.ButtonCycleArray) as! [Dictionary <String, Bool>]
        }
        set {
            // Store the current button cycle array as NSUserDefaults
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey:  Defaults.ButtonCycleArray)
            println("Saved button cycle array \(newValue) as NSUserDefaults")
        }
    }
    
}


