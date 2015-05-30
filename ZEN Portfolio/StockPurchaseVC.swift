//
//  StockPurchaseVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 09/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



final class StockPurchaseViewController: StockTradingViewController {
    //  Polymorphism : only the methods specific to share purchasing are implemented in this subclass of StockTradingViewController
    
    // MARK: Public properties
    /** Block to re-enable table view selection in Search ViewController. */
    var enableSearchTableViewSelectionClosure: (() -> ())?
    
    /** Block to dismiss presented VC and go back to ListViewController. */
    var dismissClosure: (() -> ())?
    
    
    // MARK: Private properties
    @IBOutlet private weak var buyStockButton: UIBarButtonItem!
    
    
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Button title
        buyStockButton.title = NSLocalizedString("Stock Purchase VC:buy button", comment: "Buy")
        
        // Default values for purchase share price and currency rate
        tradingNumberOfShares = 0
        tradingSharePrice = stock.currentSharePrice
        tradingCurrencyRate = stock.currentCurrencyRate
        
        // By default, the Buy button is disabled, because the tradingNumberOfShares property is 0 by default (unauthorized value)
        buyStockButton.enabled = false
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Stock Purchase")
        
        
        if stock.currentSharePrice == 0.0 {
            // If things went wrong, show an error notification
            TSMessage.showNotificationInViewController(self,
                title: NSLocalizedString("Yahoo Finance unavailable", comment: "Yahoo Finance is unavailable"),
                subtitle: NSLocalizedString("Stock Purchase VC:enter info manually", comment: "Please enter the purchase information manually"),
                type:TSMessageNotificationType.Warning)
        }
    }
    
    
    
    // MARK: Table view data source methods
    func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        switch sections[section].type {
        case .TradingInfoEntry:
            return NSLocalizedString("Stock Purchase VC:section Purchase", comment: "Purchase information")
        case .CurrentInfoDisplay:
            return NSLocalizedString("Stock Purchase VC:section Current", comment: "Current information")
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
            cell.label.text = NSLocalizedString("Detail VC:number of shares", comment: "Number of shares")
            if tradingNumberOfShares == 0 {
                cell.textField.text = ""
            } else {
                cell.textField.text = numberOfSharesFormatter.stringFromNumber(tradingNumberOfShares)
            }
            // Set textField tag as the indexPath row number (only for lines with a textField)
            cell.textField.tag = indexPath.row
            // Set self as the textField delegate
            cell.textField.delegate = self
            return cell
            
        case .Price:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TextFieldCellReuseIdentifier, forIndexPath: indexPath) as! TextFieldTableViewCell
            let purchaseSharePriceLocalizedText = NSLocalizedString("Detail VC:purchase share price", comment: "Purchase share price")
            cell.label.text = "\(purchaseSharePriceLocalizedText) (\(stock.currency))"
            // Put the current price as the default purchasing price
            cell.textField.text = sharePriceFormatter.stringFromNumber(tradingSharePrice)
            
            // Set textField tag as the indexPath row number (only for lines with a textField)
            cell.textField.tag = indexPath.row
            // Set self as the textField delegate
            cell.textField.delegate = self
            return cell
            
        case .ExchangeRate:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TextFieldCellReuseIdentifier, forIndexPath: indexPath) as! TextFieldTableViewCell
            let purchaseCurrencyRateLocalizedText = NSLocalizedString("Detail VC:purchase currency rate", comment: "Purchase currency rate")
            cell.label.text = "\(purchaseCurrencyRateLocalizedText) (\(GlobalSettings.sharedStore.portfolioCurrency)/\(currency))"
            // Put the current currency rate  as the default purchasing currency rate
            cell.textField.text = currencyRateFormatter.stringFromNumber(tradingCurrencyRate)
            
            // Set textField tag as the indexPath row number (only for lines with a textField)
            cell.textField.tag = indexPath.row
            // Set self as the textField delegate
            cell.textField.delegate = self
            return cell
            
        case .Date:
            var cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.DateCellReuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
            cell.textLabel?.text = NSLocalizedString("Stock Purchase VC:purchase date", comment: "Purchase date")
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
            
            let currentCurrencyRateLocalizedText = NSLocalizedString("Detail VC:current currency rate", comment: "Current currency rate")
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
            
            if textField.tag == 0 {  // Number of shares to purchase
                textFieldValueNumber = numberOfSharesFormatter.numberFromString(textField.text)
            } else if textField.tag == 1 {  // Purchase share price
                textFieldValueNumber = sharePriceFormatter.numberFromString(textField.text)
            } else if textField.tag == 2 { // Purchase currency rate
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
                textFieldInError = true
                buyStockButton.enabled = false
                return false
            }
        }
        // Allow saving
        textFieldInError = false
        return super.textFieldShouldEndEditing(textField)
    }
    
    
    override func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == 0 {         // Number of shares
            // update numberOfSharesField
            if let purchaseNumberOfSharesNumber = numberOfSharesFormatter.numberFromString(textField.text) {
                tradingNumberOfShares = purchaseNumberOfSharesNumber.integerValue
            }
        } else if (textField.tag == 1) {  // Purchase share price
            // update purchaseSharePriceField
            if let purchaseSharePriceNumber = sharePriceFormatter.numberFromString(textField.text) {
                tradingSharePrice = purchaseSharePriceNumber.doubleValue
            }
        } else if (textField.tag == 2) {  // Purchase currency rate
            // update purchaseCurrencyRateField
            if let purchaseCurrencyRateNumber = currencyRateFormatter.numberFromString(textField.text) {
                tradingCurrencyRate = purchaseCurrencyRateNumber.doubleValue
            }
        }
        super.textFieldDidEndEditing(textField)
        
        // Enable the Buy button only if the current edited textField is not in error, and there is a valid value in each one
        buyStockButton.enabled = (textFieldInError == false) && (tradingNumberOfShares > 0) && (tradingSharePrice > 0) && (tradingCurrencyRate > 0)
    }
    
    
    
    // MARK: Custom methods
    @IBAction func buyShares(sender: UIBarButtonItem) {
        // Resign first responder, which removes the decimal keypad
        view.endEditing(true)
        
        
        // Update the ITEM properties
        stock.numberOfShares = tradingNumberOfShares
        stock.purchaseSharePrice = tradingSharePrice
        stock.purchaseCurrencyRate = tradingCurrencyRate
        stock.purchaseDate = tradingDate
        
        // Add the new stock to the iCloud StockStore
        StockStore.sharedStore.addRecordToCloud(stock)
        
        // Dismiss StockPurchaseViewController and return back to the StockListTableViewController
        
        // The SearchStockVC is embedded in a navController
        if let navController = presentingViewController as? UINavigationController {
            if let searchVC = navController.childViewControllers.first as? StockSearchTableViewController {
                searchVC.shouldDisplayKeyboard = false // Don't display keyboard when animating dismissal
                searchVC.dismissViewControllerAnimated(true, completion: dismissClosure)
            }
        }
        
        // ReloadData of the List View tableView
        // Get the index of the item to be added: it is the last item added
        if let index = StockStore.sharedStore.allStocks.last {
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockPurchaseVC_DidBuyShareNotification, object: nil, userInfo: [ "index" : "\(index)" ])
        }
                
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        cancelButtonPressed = true
        
        // Hide the keyboard if a textField is still being edited
        selectedTextField?.resignFirstResponder()
        
        // If the user cancelled, then remove the item from the store
        StockStore.sharedStore.removeStock(stock)
        
        presentingViewController?.dismissViewControllerAnimated(true, completion: enableSearchTableViewSelectionClosure)
    }
}