//
//  ViewController.swift
//  TEST
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
                          
    @IBOutlet var portfolioLabel: UILabel
    
    @IBAction func pressedLongHere(sender: UILongPressGestureRecognizer) {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        GlobalSettings.sharedStore().portfolioCurrency = "EUR"
        GlobalSettings.sharedStore().currentThemeNumber = 2
        
        println("Current theme is: \(GlobalSettings.sharedStore().currentTheme.name)")
        
        
        var stock1 = StockStore.sharedStore().createStock(symbol: "AAPL", name: "Apple.Inc", market: "NASDAQ", currency: "USD")
        stock1.numberOfShares = 5
        stock1.purchaseCurrencyRate = 1.3724
        stock1.purchaseSharePrice = 620.00
        stock1.currentCurrencyRate = 1.38
        stock1.currentSharePrice = 640.00
        
        var stock2 = StockStore.sharedStore().createStock(symbol: "TSLA", name: "Tesla", market: "NASDAQ", currency: "GBP")
        stock2.numberOfShares = 10
        stock2.purchaseCurrencyRate = 1.3724
        stock2.purchaseSharePrice = 220.00
        stock2.currentCurrencyRate = 1.38
        stock2.currentSharePrice = 240.00




        
        CurrencyRateStore.sharedStore()["EURUSD=X"] = 1.3426
        CurrencyRateStore.sharedStore()["EURRUB=X"] = 0.456
        CurrencyRateStore.sharedStore()["EURJPY=X"] = 0.222

        let keyArray = CurrencyRateStore.sharedStore().allKeys

//        for currency in PortfolioCurrencyStore.sharedStore().allCurrencies {
//            println("Currency symbol: \(currency.symbol) description: \(currency.description) imageName: \(currency.flagImageName)")
//            }
        
        
//        var dateFormatter = NSDateFormatter()
//        dateFormatter.dateFormat = "dd-MMM-yy"
//
//        var dateString1 = "03-Sep-11"
//        var dateString2 = "26-Sep-13"
//
//        var date1 = dateFormatter.dateFromString(dateString1)
//        var date2 = dateFormatter.dateFromString(dateString2)
//        
//        SalesJournal.sharedStore().createSale(symbol: "AAPL", currency: "USD", saleDate:date1, numberOfSharesSold: 5, purchaseSharePrice: 640.25, sellingSharePrice: 680.10, purchaseCurrencyRate: 1.00, sellingCurrencyRate:1.00)
//        
//        SalesJournal.sharedStore().createSale(symbol: "TSLA", currency: "USD", saleDate:date2, numberOfSharesSold: 6, purchaseSharePrice: 640.25, sellingSharePrice: 680.10, purchaseCurrencyRate: 1.00, sellingCurrencyRate:1.00)
//
//        for sale in SalesJournal.sharedStore().allEntries {
//            println("Sale: \(sale.symbol) date: \(sale.saleDate)")
//        }
        
        
        GlobalSettings.sharedStore().currentThemeNumber = 1
    
        
        StockAlertStore.sharedStore().createNotification(type: StockAlertType.Price, forStock: stock2, withTarget: 235.00, compareAscending: true)
        StockAlertStore.sharedStore().createNotification(type: StockAlertType.Price, forStock: stock2, withTarget: 335.00, compareAscending: true)
        
        for notification in StockAlertStore.sharedStore().allAlerts {
            println("Notification: \(notification.stock.symbol) target: \(notification.target)")
        }
        
        //
        //        for stock in StockStore.sharedStore().allStocks {
        //            println("\(stock.symbol)")
        //        }
        //
        //        FeedStore.sharedStore().fetchStockQuotes(["EURUSD=X", "AAPL"], completion: {(obj: JSONStockDetailRootObject?, err: NSError?) -> () in
        //            println(obj!.items.firstElement.symbol)
        //            println(err)
        //            })
        
        GlobalSettings.sharedStore().automaticUpdate = true
    }

    
}

