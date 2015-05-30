//
//  AppDelegate.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 08/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

// Global properties
struct Identifiers {
    static let AppStoreIdentifier = "576249340"
    static let GoogleAnalyticsIdentifier = "UA-61260961-2"
}

var appVersion: String! {
    return NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
}
var bundleVersion: String! {
    return NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as! String
}


// Keys for NSUserDefaults dictionary
struct Defaults {
    static let VariableValueModePrefKey     = "ZENPortfolioVariableValueModePrefKey"
    static let CurrencyPrefKey              = "ZENPortfolioCurrencyPrefKey"
    static let AutomaticUpdateKey           = "ZENPortfolioAutomaticUpdateKey"
    static let UpdateFreqKey                = "ZENPortfolioUpdateFreqKey"
    static let CurrentThemeKey              = "ZENPortfolioCurrentThemeKey"
    static let ButtonCycleArray             = "ZENPortfolioButtonCycleArray"
    static let FetchDatePrefKey             = "ZENPortfolioFetchDatePrefKey"
}

// Codes for Button cycle values
struct ButtonCycle {
    static let NumberOfShares      =     "NUMBER_SHARES"
    static let IntradayEvolution   =     "INTRADAY_PCT"
    static let PortfolioValue      =     "PORTFOLIO_VALUE"
    static let GainOrLossValue     =     "GAIN_OR_LOSS_VALUE"
    static let GainOrLossPercent   =     "GAIN_OR_LOSS_PCT"
}


// Keys for NSNotificationCenter observers
struct NotificationCenterKeys {
    static let StockPurchaseVC_DidBuyShareNotification                       =       "StockPurchaseVC_DidBuyShareNotification"
    static let StockSellVC_DidSellShareCompletelyNotification                =       "StockSellVC_DidSellShareCompletelyNotification"
    static let StockSellVC_DidSellSharePartiallyNotification                 =       "StockSellVC_DidSellSharePartiallyNotification"
    static let CurrencyPickerVC_PortfolioCurrencyDidChangeNotification       =       "CurrencyPickerVC_PortfolioCurrencyDidChangeNotification"
    static let ButtonCycleVC_ButtonCycleDidChangeNotification                =       "ButtonCycleVC_ButtonCycleDidChangeNotification"
    static let ThemeSelectorVC_CurrentThemeDidChangeNotification             =       "ThemeSelectorVC_CurrentThemeDidChangeNotification"
    static let StockListVC_DidFireLocalNotificationNotification              =       "StockListVC_DidFireLocalNotificationNotification"
    static let StockListVC_DidUpdateStockQuotesNotification                  =       "StockListVC_DidUpdateStockQuotesNotification"
    
    // CKRecords for StockStore
    static let StockStore_LoadedStocksFromCloud                              =       "StockStore_LoadedStocksFromCloud"
    // CKSubscriptions
    static let StockStore_StockCreatedFromSubscription                       =       "StockStore_StockCreatedFromSubscription"
    static let StockStore_StockDeletedFromSubscription                       =       "StockStore_StockDeletedFromSubscription"
    
}

/*
Stock update mechanism

There are 4 ways to update stocks :

1 - Manually, via StockListTableViewController refreshControl ; calls directly fetchStockQuotes in StockListTableViewController.

2 - In StockListTableViewController / viewWillAppear, limited to the active state (useful when navigating within the app, and coming back to the StockListTableViewController) ; calls updateStocks (checking that a refresh is not already in process, that automatic update has been activated and that the stock quotes are more than 10-mn old)

3 - In AppDelegate / didBecomeActive (useful when the App is launched, or re-launched, because then, StockListTableViewController viewWillAppear may not be called again) ; calls updateStocks (checking that a refresh is not already in process, that automatic update has been activated and that the stock quotes are more than 10-mn old)

4 - Background fetch, in AppDelegate / performFetchWithCompletionHandler ; calls directly fetchStockQuotesWithCompletionHandler in StockListTableViewController (checking that automatic update has been activated)
*/



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // Constant
    let DefaultUpdateFrequency = 10 // in minutes
    
    
    // Change to "true" to get more details in the console
    let debug = false
    
    /** Checks if the app is running on the simulator */
    var onSimulator = false
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
    
        // Override point for customization after application launch.
        
        if debug == true { println("** applicationDidFinishLaunchingWithOptions") }
        
        // Check if running on the simulator
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            onSimulator = true
        #endif
        
        // Background fetch minimum interval
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        // Initialize defaults in NSUserDefaults
        initializeDefaults()
        
        // Initialize Google Analytics
        if !onSimulator {
        setupGoogleAnalytics()
        }

        // Customize UI
        self.window?.tintColor = GlobalSettings.sharedStore.currentTheme.color
        

        // Request permission from the user to use icon badges / local notifications
        let notificationSettings = UIUserNotificationSettings(forTypes: .Sound | .Badge | .Alert, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        
        
        // Handle launching from a local notification
        if let launchOptions = launchOptions where launchOptions[UIApplicationLaunchOptionsLocalNotificationKey] != nil {
            // Set icon badge number to zero
            application.applicationIconBadgeNumber = 0
        }
        
        // Request permission from the user to use remote notifications (for CKSubscriptions)
        application.registerForRemoteNotifications()
        
        
        
        // TEST DATA !!
        // Simulator only
        if onSimulator {
            println("Document directory on simulator: \(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true))")
//            CloudManager.sharedManager.cloudPrompted = false
//            CloudManager.sharedManager.cloudActivated = false

            // Sample portfolio
            createTestDataFromPlist("SampleData")
        }
        // Portfolio FAD
//        CloudManager.sharedManager.cloudActivated = false
//        createTestDataFromPlist("Portfolio_FAD")      
        
        
        // Load stores
        println("Loading stocks: \(StockStore.sharedStore.allStocks)")
        println("Loading sales: \(SalesJournal.sharedStore.allEntries)")
        println("Loading notifications: \(StockNotificationStore.sharedStore.allNotifications)")
        
        return true
    }
    
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        if debug == true { println("** applicationWillResignActive") }
    }
    
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        if debug == true { println("** applicationDidEnterBackground") }
        
        // Save to disk whether iCloud is activated (caching) or not (local archiving)
        
        // Save stocks
        let stockSavePath = CloudManager.sharedManager.cloudActivated ? StockStore.sharedStore.cachePath : StockStore.sharedStore.localArchivePath
        let successArchivingStocks = StockStore.sharedStore.saveDataToLocalPath(stockSavePath)
        if successArchivingStocks {
            println("Saved all of the Stocks")
        } else {
            println("Could not save any of the Stocks")
        }
        
        // Save Sales journal
        let salesSavePath = CloudManager.sharedManager.cloudActivated ? SalesJournal.sharedStore.cachePath : SalesJournal.sharedStore.localArchivePath
        let successArchivingSalesJournal = SalesJournal.sharedStore.saveDataToLocalPath(salesSavePath)
        if successArchivingSalesJournal {
            println("Saved the SalesJournal")
        } else {
            println("Could not save the SalesJournal")
        }
        
        // Save Notifications
        let notificationSavePath = CloudManager.sharedManager.cloudActivated ? StockNotificationStore.sharedStore.cachePath : StockNotificationStore.sharedStore.localArchivePath
        let successArchivingNotifications = StockNotificationStore.sharedStore.saveDataToLocalPath(notificationSavePath)
        if successArchivingNotifications {
            println("Saved all of the StockNotifications")
        } else {
            println("Could not save any of the StockNotifications")
        }
        
    }
    
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        if debug == true { println("** applicationWillEnterForeground") }
        
        // Reset application badge
        application.applicationIconBadgeNumber = 0
    }
    
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if debug == true { println("** applicationDidBecomeActive") }
        
        // This updateStocks call has been replaced by an observer in StockListTVC for applicationDidBecomeActiveNotification
//        // Update stock quotes when becoming active
//        if stockListTVC != nil {
//            stockListTVC!.updateStocks()
//        }
        
        // Get outstanding notifications
        CloudManager.sharedManager.getOutstandingNotifications()

        
        // RELEASE NOTES : notify the users about what's new in this version
        if !TWSReleaseNotesView.isAppOnFirstLaunch() && TWSReleaseNotesView.isAppVersionUpdated() {
            
            TWSReleaseNotesView.setupViewWithAppIdentifier(Identifiers.AppStoreIdentifier,
                releaseNotesTitle: String.localizedStringWithFormat(NSLocalizedString("Release notes title", comment: "What's new in version *version*"), appVersion),
                closeButtonTitle:"OK",
                completionBlock: { (releaseNotesView: TWSReleaseNotesView!, releaseNotesText: String!, error: NSError?) in
                    
                    if error != nil {
                        println("An error occurred: \(error!.localizedDescription)")
                    } else {
                        // Create and show release notes view
                        if self.window?.rootViewController is UISplitViewController {
                            releaseNotesView.showInView(self.window?.rootViewController?.view)
                        } else {
                            releaseNotesView.showInView(self.window)
                        }
                    }
            })
        }
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        if debug == true { println("** applicationWillTerminate") }
     
    }
    
    
    // MARK: Background fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult -> Void)) {
        if debug == true { println("** Perform background fetch") }
        
        
        // Update only if automatic update is activated
        if GlobalSettings.sharedStore.automaticUpdate {
            
            /** Get a hold on the StockListTVC */
            // TraitOverrideVC is the root view controller.
            if let traitOverrideVC = self.window?.rootViewController as? TraitOverrideViewController {
                // The SplitViewController is the first childVC of the TraitOverrideVC
                if let splitVC = traitOverrideVC.childViewControllers.first as? SplitViewController {
                    
                    // The first view controller of the split view is a UINavigationController
                    if let navigationController = splitVC.viewControllers.first as? UINavigationController {
                        // The StockListTableViewController is at the root of the first navigation stack
                        if let stockListTVC = navigationController.viewControllers.first as? StockListTableViewController {
                            
                            // Update stock quotes in background
                            stockListTVC.fetchStockQuotesWithCompletionHandler(completionHandler)
                        }
                    }
                }
            }
        }
    }

    
    // MARK: Local notifications
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        let state = application.applicationState
        
        if state == .Active {
            
            // Remove double %% (escaped form of %) to display in TSMessage
            let nonEscapedAlertBody = notification.alertBody!.stringByReplacingOccurrencesOfString("%%", withString:"%")
            
            TSMessage.showNotificationWithTitle(nonEscapedAlertBody,
                subtitle: NSLocalizedString("Local notification:tap to dismiss", comment: "Slide up to dismiss"),
                type: TSMessageNotificationType.Message,
                duration: -1) // "endless" (user must tap to dismiss)
            
        }
        
        // Set icon badge number to zero
        application.applicationIconBadgeNumber = 0
        
    }

    
    // MARK: Remote notifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println("Registered for Push notifications with token: \(deviceToken)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("Push subscription failed: \(error)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if let notification = CKQueryNotification(fromRemoteNotificationDictionary: userInfo) {
            CloudManager.sharedManager.handleNotification(notification)
        }
    }
    
    
    // MARK: custom methods
    
    func initializeDefaults() {
        
        // WARNING: Reset persistent domain
//                NSUserDefaults.standardUserDefaults().removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
        
        let persistentDomain = NSUserDefaults.standardUserDefaults().persistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
        
        // Initial values in NSUserDefaults persistent domain
        if debug == true {
            println("Standard defaults (initial):\n \(persistentDomain)")
        }
        
        // VARIABLE VALUE MODE
        let variableValueMode = 1
        if debug == true { println("Default variable value mode set as: \(variableValueMode)") }
        
        // PORTFOLIO CURRENCY DEFAULT
        var currencyCode = "USD"
        
        // Get the user currency code (part of currentLocale)
        if let userCurrencyCode = NSLocale.currentLocale().objectForKey(NSLocaleCurrencyCode) as? String {
            
            // If the currency in NSLocale is not part of the PortfolioCurrencyStore, use USD (default)
            if find(PortfolioCurrencyStore.sharedStore.allCurrencySymbols, userCurrencyCode) != nil {
                currencyCode = userCurrencyCode
            }
        }
        if debug == true { println("Default portfolio currency (from NSLocale) is: \(currencyCode)") }
        
        
        // AUTOMATIC UPDATE BOOL DEFAULT
        let automaticUpdate = true
        if debug == true { println("Default automatic update is: \(automaticUpdate)") }
        
        // UPDATE FREQUENCY DEFAULT
        let updateFrequency = DefaultUpdateFrequency // in minutes
        if debug == true { println("Default update frequency is: \(updateFrequency) mn") }
        
        // CURRENT THEME
        let defaultTheme = 1 // Stone theme
        if debug == true { println("Default theme is: \(Theme(rawValue: defaultTheme)!.description)") }
        
        // MAIN SCREEN BUTTON CYCLE
        // Stores the list of possible "toggle" values, and their order, as an array of dictionaries
        // Each dictionary indicates if the value must be displayed (TRUE) or not (FALSE)
        let defaultCycleArray = [
            [ ButtonCycle.NumberOfShares    :   true ],
            [ ButtonCycle.IntradayEvolution :   false ],
            [ ButtonCycle.PortfolioValue    :   true ],
            [ ButtonCycle.GainOrLossValue   :   true ],
            [ ButtonCycle.GainOrLossPercent :   true],
        ]
        
        
        // RegisterDefaults dictionary
        let defaults : [NSObject : AnyObject] = [
            Defaults.VariableValueModePrefKey   :    variableValueMode,
            Defaults.CurrencyPrefKey            :    currencyCode,
            Defaults.AutomaticUpdateKey         :    automaticUpdate,
            Defaults.UpdateFreqKey              :    updateFrequency,
            Defaults.CurrentThemeKey            :    defaultTheme,
            Defaults.ButtonCycleArray           :    defaultCycleArray,
        ]
        
        NSUserDefaults.standardUserDefaults().registerDefaults(defaults)
        
        // Force storage of ZENPortfolioCurrencyPrefKey in the persistent domain
        if let persistentDomain = persistentDomain {
            if persistentDomain[Defaults.CurrencyPrefKey] == nil {
                GlobalSettings.sharedStore.portfolioCurrency = currencyCode
            }
        } else {
            GlobalSettings.sharedStore.portfolioCurrency = currencyCode
        }
        
        
        // Final values in NSUserDefaults persistent domain
        if debug == true {
            println("Standard defaults (final):\n \(persistentDomain)")
        }
    }
    
    
    /** Defines test data directly in the model. */
    func createTestDataFromPlist(fileName: String) {
        
        // Number formatter to parse Plist file (locale = US because decimal separator is '.')
        var numberFormatter = NSNumberFormatter()
        numberFormatter.locale = NSLocale(localeIdentifier:"en_US")
        
        // Date formatter to parse Plist file (locale = FR because dates are formatted DD/MM/YYYY)
        var dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "fr_FR")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let userCurrencyCode = NSLocale.currentLocale().objectForKey(NSLocaleCurrencyCode) as! String
        GlobalSettings.sharedStore.portfolioCurrency = userCurrencyCode
        
        
        // Delete all items from the StockStore
        StockStore.sharedStore.removeAllStocks()
        println("StockStore : all entries were deleted")
        
        // Delete all items from the CurrencyRateStore
        CurrencyRateStore.sharedStore.deleteAllRates()
        println("CurrencyStore : all entries were deleted")
        
        // Delete all items from the SalesJournal
        SalesJournal.sharedStore.removeAllEntries()
        println("SalesJournal : all Sales journal entries were deleted")
        
        // Get sample data from the plist file
        if let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "plist") {
            let dataArray = NSDictionary(contentsOfFile: path)!
            
            // Create current stocks
            let stocks = dataArray["stocks"] as! NSArray
            
            for stock: AnyObject in stocks {
                let symbol = stock["symbol"] as! String
                let name = stock["name"] as! String
                let market = stock["market"] as! String
                let currency = stock["currency"] as! String
                
                var newStock = StockStore.sharedStore.createStock(symbol: symbol, name: name, market: market, currency: currency)
                newStock.numberOfShares = (stock["numberOfShares"] as! String).toInt()!
                
                //            newStock.purchaseSharePrice = (stock["purchaseSharePrice"] as NSString).doubleValue
                newStock.purchaseSharePrice = numberFormatter.numberFromString(stock["purchaseSharePrice"] as! String)!.doubleValue
                
                if  userCurrencyCode == currency {
                    newStock.purchaseCurrencyRate = 1.0000
                } else {
                    let currencyRateDict = stock["purchaseCurrencyRate"] as! NSDictionary
                    newStock.purchaseCurrencyRate = numberFormatter.numberFromString(currencyRateDict[userCurrencyCode] as! String)!.doubleValue
                }
                newStock.purchaseDate = dateFormatter.dateFromString(stock["purchaseDate"] as! String)
                
            }
            
            // Create Sales journal entries
            let sales = dataArray["sales"] as! NSArray
            
            for sale: AnyObject in sales {
                let symbol = sale["symbol"] as! String
                let name = sale["name"] as! String
                let currency = sale["currency"] as! String
                let saleDate = dateFormatter.dateFromString(sale["saleDate"] as! String)!
                let numberOfShares = (sale["numberOfShares"] as! String).toInt()!
                let purchaseSharePrice = numberFormatter.numberFromString(sale["purchaseSharePrice"] as! String)!.doubleValue
                let sellingSharePrice = numberFormatter.numberFromString(sale["sellingSharePrice"] as! String)!.doubleValue
                let purchaseCurrencyRate = numberFormatter.numberFromString(sale["purchaseCurrencyRate"] as! String)!.doubleValue
                let sellingCurrencyRate = numberFormatter.numberFromString(sale["sellingCurrencyRate"] as! String)!.doubleValue
                
                
                var newSale = SalesJournal.sharedStore.createSale(symbol: symbol, name: name, currency: currency, saleDate: saleDate, numberOfSharesSold: numberOfShares, purchaseSharePrice: purchaseSharePrice, sellingSharePrice: sellingSharePrice, purchaseCurrencyRate: purchaseCurrencyRate, sellingCurrencyRate: sellingCurrencyRate)
                
                newSale.purchaseDate = dateFormatter.dateFromString(sale["purchaseDate"] as! String)
            }
        }
        
    }
    
    
    /** Initialize Google Analytics */
    func setupGoogleAnalytics() {
        // Optional: automatically send uncaught exceptions to Google Analytics.
        GAI.sharedInstance().trackUncaughtExceptions = true
        
        // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
        GAI.sharedInstance().dispatchInterval = 20
        
        // Optional: set Logger to VERBOSE for debug information.
        GAI.sharedInstance().logger.logLevel = .Error
        
        // Initialize tracker. Replace with your tracking ID.
        GAI.sharedInstance().trackerWithTrackingId(Identifiers.GoogleAnalyticsIdentifier)
    }
    
}