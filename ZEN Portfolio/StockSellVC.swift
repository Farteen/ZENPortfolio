//
//  StockSellVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 09/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



final class StockSellViewController: StockTradingViewController {
    //  Polymorphism : only the methods specific to share selling are implemented in this subclass of StockTradingViewController
    
    // MARK: Public properties
    /** Closure to pop to Root ViewController, i.e. StockListTVC */
    var popToRootClosure: (() -> ())?
    
    // MARK: Private properties
    @IBOutlet private weak var sellStockButton: UIBarButtonItem!
    
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Button title
        sellStockButton.title = NSLocalizedString("Stock Sell VC:sell button", comment: "Sell")
        
        // Default values for number of shares to sell, trading share price and currency rate
        tradingNumberOfShares = stock.numberOfShares
        tradingSharePrice = stock.currentSharePrice
        tradingCurrencyRate = stock.currentCurrencyRate
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Stock Sell")
    }
    

    
    // MARK: Table view data source methods
    func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        switch sections[section].type {
        case .TradingInfoEntry:
            return NSLocalizedString("Stock Sell VC:section Sale", comment: "Selling information")
        case .CurrentInfoDisplay:
            return NSLocalizedString("Stock Sell VC:section Current", comment: "Current information")
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var currency = stock.currency
        // Special case for GBX (0,01 GBP)
        if currency == "GBX" { currency = "GBP" }
        
        
        switch sections[indexPath.section].items[indexPath.row] {
            
            // Trading info (entry)
        case .NumberOfShares:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TextFieldCellReuseIdentifier, forIndexPath: indexPath) as! TextFieldTableViewCell
            cell.label.text = NSLocalizedString("Stock Sell VC:number of shares", comment: "Number of shares to sell")
            // Put the item number of shares as the default number of shares to sell
            cell.textField.text = numberOfSharesFormatter.stringFromNumber(tradingNumberOfShares)            
            
            // Set textField tag as the indexPath row number (only for lines with a textField)
            cell.textField.tag = indexPath.row
            // Set self as the textField delegate
            cell.textField.delegate = self
            return cell
            
        case .Price:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TextFieldCellReuseIdentifier, forIndexPath: indexPath) as! TextFieldTableViewCell
            let sellingSharePriceLocalizedText = NSLocalizedString("Stock Sell VC:sell share price", comment: "Selling share price")
            cell.label.text = "\(sellingSharePriceLocalizedText) (\(stock.currency))"
            // Put the current price as the default selling price
            cell.textField.text = sharePriceFormatter.stringFromNumber(tradingSharePrice)
            
            // Set textField tag as the indexPath row number (only for lines with a textField)
            cell.textField.tag = indexPath.row
            // Set self as the textField delegate
            cell.textField.delegate = self
            return cell
            
        case .ExchangeRate:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TextFieldCellReuseIdentifier, forIndexPath: indexPath) as! TextFieldTableViewCell
            let sellingCurrencyRateLocalizedText = NSLocalizedString("Stock Sell VC:sell currency rate", comment: "Selling currency rate")
            cell.label.text = "\(sellingCurrencyRateLocalizedText) (\(GlobalSettings.sharedStore.portfolioCurrency)/\(currency))"
            // Put the current currency rate  as the default selling currency rate
            cell.textField.text = currencyRateFormatter.stringFromNumber(tradingCurrencyRate)
            
            // Set textField tag as the indexPath row number (only for lines with a textField)
            cell.textField.tag = indexPath.row
            // Set self as the textField delegate
            cell.textField.delegate = self
            
            return cell
            
        case .Date:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.DateCellReuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = NSLocalizedString("Stock Sell VC:sale date", comment: "Sale date")
            cell.detailTextLabel?.text = dateFormatter.stringFromDate(tradingDate)
            return cell
            
        case .DatePicker:
            // the indexPath is the one containing the inline date picker
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.DatePickerReuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
            return cell

            
            // Current info (display)
        case .DisplayPrice:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.DisplayInfoCellReuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
            let currentSharePriceLocalizedText = NSLocalizedString("Detail VC:current share price", comment: "Current share price")
            cell.textLabel?.text = "\(currentSharePriceLocalizedText) (\(stock.currency))"
            cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(stock.currentSharePrice)
            return cell
            
        case .DisplayExchangeRate:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.DisplayInfoCellReuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
            let currentCurrencyRateLocalizedText = NSLocalizedString("Detail VC:current currency rate", comment :"Current currency rate")
            cell.textLabel?.text = "\(currentCurrencyRateLocalizedText) (\(GlobalSettings.sharedStore.portfolioCurrency)/\(currency))"
            cell.detailTextLabel?.text = currencyRateFormatter.stringFromNumber(stock.currentCurrencyRate)
            return cell
        }
    }
    
    
    
    // MARK: Textfield delegate methods
    override func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        // If the user pressed Cancel, then return without checking the content of the textfield
        if cancelButtonPressed == false {
            
            var textFieldValueNumber = NSNumber?()
            
            if textField.tag == 0 {  // Number of shares to sell
                textFieldValueNumber = numberOfSharesFormatter.numberFromString(textField.text)
                
                // Impossible to sell more stocks than you own
                if textFieldValueNumber?.integerValue > stock.numberOfShares {
                    let alertView = UIAlertController(title: NSLocalizedString("Stock Sell VC:control nb of shares", comment: "Wrong number of shares"),
                        message:NSLocalizedString("Stock Sell VC:control nb message", comment: "You cannot sell more shares that you actually own"),
                        preferredStyle: .Alert)
                    // cancel button
                    let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertView.addAction(cancelAction)
                    
                    presentViewController(alertView, animated: true, completion: nil)
                    // Prevent from saving
                    self.textFieldInError = true
                    return false
                }
            } else if textField.tag == 1 {  // Selling share price
                textFieldValueNumber = sharePriceFormatter.numberFromString(textField.text)
            } else if textField.tag == 2 { // Selling currency rate
                textFieldValueNumber = currencyRateFormatter.numberFromString(textField.text)
            }
            
            // Control that the number is entered correctly (if the number is not properly formatted, it will be nil)
            if textFieldValueNumber == nil {
                let alertView = UIAlertController(title: NSLocalizedString("Stock Trading VC:incorrect entry title", comment: "Entry error"),
                    message: NSLocalizedString("Stock Trading VC:incorrect entry message", comment: "Please check that this field is not empty and does not contain incorrect characters"),
                    preferredStyle: .Alert)
                // cancel button
                let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alertView.addAction(cancelAction)
                
                presentViewController(alertView, animated: true, completion: nil)
                
                
                // Prevent from saving
                self.textFieldInError = true
                sellStockButton.enabled = false
                return false
            }
        }
        // Allow saving
        self.textFieldInError = false
        return super.textFieldShouldEndEditing(textField)
    }
    
    
    override func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == 0 { // Number of shares
            // update trading number of shares
            if let sellingNumberOfSharesNumber = numberOfSharesFormatter.numberFromString(textField.text) {
                tradingNumberOfShares = sellingNumberOfSharesNumber.integerValue
            }
        } else if (textField.tag == 1) {  // Purchase share price
            // update selling share price
            if let sellingSharePriceNumber = sharePriceFormatter.numberFromString(textField.text) {
                tradingSharePrice = sellingSharePriceNumber.doubleValue
            }
        } else if (textField.tag == 2) {  // Purchase currency rate
            // update selling currency rate
            if let sellingCurrencyRateNumber = currencyRateFormatter.numberFromString(textField.text) {
                tradingCurrencyRate = sellingCurrencyRateNumber.doubleValue
            }
        }
        super.textFieldDidEndEditing(textField)
        
        // Enable the Sell button only if the current edited textField is not in error, and there is a valid value in each one
        sellStockButton.enabled = (textFieldInError == false) && (tradingNumberOfShares > 0) && (tradingSharePrice > 0) && (tradingCurrencyRate > 0)
    }
    
    
    
    // MARK: Specific Selling methods
    @IBAction func sellShares() {
        // Resign first responder, which removes the decimal keypad
        view.endEditing(true)
        
        // Log entry in the Sales journal
        var sale = SalesJournal.sharedStore.createSale(
            symbol: stock.symbol,
            name: stock.name,
            currency: stock.currency,
            saleDate: tradingDate,
            numberOfSharesSold: tradingNumberOfShares,
            purchaseSharePrice: stock.purchaseSharePrice,
            sellingSharePrice: tradingSharePrice,
            purchaseCurrencyRate: stock.purchaseCurrencyRate,
            sellingCurrencyRate: tradingCurrencyRate)
        
        // PurchaseDate was not activated in the previous versions of the app
        sale.purchaseDate = stock.purchaseDate
        
        // Add the newly created sale to iCloud
        SalesJournal.sharedStore.addRecordToCloud(sale)
        
        
        // Check if there are corresponding notifications corresponding to this stock
        var notificationsToRemove = [StockNotification]()
        for notification in StockNotificationStore.sharedStore.allNotifications {
            if stock == notification.stock {
                notificationsToRemove.append(notification)
            }
        }
        
        var message = String()
        if notificationsToRemove.isEmpty {
            message = NSLocalizedString("Stock Sell VC:logging message", comment: "The sale of your stocks has been logged in the Sales journal")
        } else {
            message = NSLocalizedString("Stock Sell VC:logging message (notif)", comment: "The sale of your stocks has been logged in the Sales journal \n(the corresponding notifications were removed)")
        }
        
        // Issue message indicating that the sale is logged in the Sales journal
        let alert = UIAlertController(title: NSLocalizedString("Stock Sell VC:logging title", comment: "New entry in the Sales journal"),
            message:message, preferredStyle: .Alert)
        // cancel button
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: { action in
            
            // update the numberOfShares of the item with the remaining stocks
            var remainingNumberOfShares = self.stock.numberOfShares - self.tradingNumberOfShares
            self.stock.numberOfShares = remainingNumberOfShares
            
            if remainingNumberOfShares == 0 {
                // Get the index of the item to be deleted
                let index = find(StockStore.sharedStore.allStocks, self.stock)
                
                // If the number of shares is 0, then delete the stock
                StockStore.sharedStore.removeRecordFromCloud(self.stock) // Remove it first from iCloud!
                StockStore.sharedStore.removeStock(self.stock)
                
                
                // Dismiss StockSellViewController and, if necessary, return all the way back to the StockList TableViewController
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: self.popToRootClosure)
                
                // ReloadData of the List/Detail views tableView
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockSellVC_DidSellShareCompletelyNotification, object:nil, userInfo: [ "index" : "\(index)" ])
                
            } else { // remaining number of shares > 0
                
                // Dismiss StockSellViewController and return to the detailViewController
                self.presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
                
                // ReloadData of the List/Detail views tableView
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockSellVC_DidSellSharePartiallyNotification, object:nil,
                    userInfo: [         "stockIdentifier" : self.stock.uniqueIdentifier,
                                "remainingNumberOfShares" : remainingNumberOfShares     ])
                
                // Remove corresponding notifications from Notification Store, even if there are remaining shares
                StockNotificationStore.sharedStore.allNotifications = StockNotificationStore.sharedStore.allNotifications.filter { value in
                    !contains(notificationsToRemove, value)
                }
            }
        })
        
        
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    @IBAction func cancel() {
        
        cancelButtonPressed = true
        
        // Hide the keyboard if a textField is still being edited
        selectedTextField?.resignFirstResponder()
        
        
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    
}