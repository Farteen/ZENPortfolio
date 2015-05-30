//
//  StockSearchTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 08/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class StockSearchTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UITextFieldDelegate {
    
    // MARK: Public properties
    var shouldDisplayKeyboard = true
    
    
    // MARK: Private properties
    @IBOutlet private weak var searchBar: UISearchBar!
    //    @IBOutlet private weak var searchActivityIndicator: UIActivityIndicatorView!
    
    private weak var fetchActivityIndicator: UIActivityIndicatorView?
    
    private var selectedStock: Stock?
    private var symbolRootObject: JSONSymbolSearchRootObject?
    private var stockRootObject: JSONStockDetailRootObject?
    private var currencyRateRootObject: JSONStockDetailRootObject?
    
    // MARK: View controller life cycle
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Searchbar placeholder text
        searchBar.placeholder = NSLocalizedString("Search VC:Placeholder text", comment: "Type a stock name or ID")
        
        // Re-enable tableView selection
        tableView.allowsSelection = true
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set the Search Bar as the first responder
        if shouldDisplayKeyboard == true {
            searchBar.becomeFirstResponder()
        }
        
        // Google Analytics
        setAnalyticsScreenName("Stock Search")
        
    }
    
    
    
    // MARK: UISearchBar delegate methods
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            searchStockSymbol(searchText)
            
            // Start spinning activity indicator
            //            searchActivityIndicator.startAnimating()
        }
        else {
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = nil
        presentingViewController?.dismissViewControllerAnimated(true, completion:nil)
    }
    
    
    
    // MARK: UITextField delegate methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    
    // MARK: Table view data source methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if symbolRootObject != nil {
            if !symbolRootObject!.symbols.isEmpty {
                return symbolRootObject!.symbols.count
            }
        }
        return 1
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("SearchCell", forIndexPath: indexPath) as! UITableViewCell
        
        cell.selectionStyle = .None // Cell selection style is none until a result is found
        cell.textLabel?.textColor = UIColor.blackColor()
        cell.detailTextLabel?.textColor = UIColor.darkGrayColor()
        
        if symbolRootObject == nil  || searchBar.text.isEmpty {
            cell.textLabel?.text = " "
            cell.detailTextLabel?.text = " "
            return cell
        }
        
        if symbolRootObject!.symbols.isEmpty {
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("Search VC:No match", comment: "No match for stock search")
                cell.textLabel?.font = UIFont.systemFontOfSize(16.0)
                cell.textLabel?.textAlignment = .Center
                cell.textLabel?.textColor = UIColor.darkGrayColor()
                cell.detailTextLabel?.text = " "
                
            } else {
                cell.textLabel?.text = " "
                cell.detailTextLabel?.text = " "
            }
            
        } else {
            let stock = symbolRootObject!.symbols[indexPath.row]
            cell.textLabel?.text = "\(stock.symbol) - \(stock.name)"
            cell.textLabel?.font = UIFont.boldSystemFontOfSize(16.0)
            cell.textLabel?.textAlignment = .Left
            cell.textLabel?.textColor = UIColor.blackColor()
            
            cell.detailTextLabel?.text = stock.market
            cell.detailTextLabel?.font = UIFont.systemFontOfSize(12.0)
            cell.detailTextLabel?.textAlignment = .Left
            cell.detailTextLabel?.textColor = UIColor.darkGrayColor()
            
            cell.selectionStyle = .Gray // Cell selection style is gray when a result is found
        }
        return cell
    }
    
    
    
    // MARK: Table view delegate methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if symbolRootObject?.symbols.count > 0 {
            
            searchBar.resignFirstResponder()
            
            // Disable cell selection once a row has been tapped
            tableView.allowsSelection = false
            
            // Activity indicator
            var cell = tableView.cellForRowAtIndexPath(indexPath)
            
            fetchActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
            cell?.accessoryView = fetchActivityIndicator
            // Start spinning activity indicator
            fetchActivityIndicator?.startAnimating()
            
            // The symbolRootObject has a symbols array of ZENStock items
            selectedStock = symbolRootObject?.symbols[indexPath.row]
            if selectedStock != nil {
                if !(selectedStock!.market.isEmpty) {
                    
                    // Determine currency
                    if let stockCurrencies = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("StockExchangeCurrency", ofType: "plist")!) {
                        
                        // Try to find a currency using the suffix of the stock symbol in Yahoo Stock Exchanges plist
                        for (code, dict) in stockCurrencies {
                            if selectedStock!.symbol.hasSuffix(code as! String) {
                                selectedStock!.currency = dict["Currency"] as! String
                                break
                            } else {
                                // If not, use USD as the default currency
                                selectedStock!.currency = "USD"
                            }
                        }
                    }
                    
                    
                    // Add the new stock to the StockStore (we made sure that it has at least a name, symbol, market and currency)
                    StockStore.sharedStore.addStock(selectedStock!)
                    
                    // Fetch current stock valuation
                    fetchStockQuotesForNewStock(selectedStock!)
                    
                    // update the values of the stock just created
                    println("Stock quotes updated for \(selectedStock!.symbol)")
                    
                    
                } else { // selectedStock.market == nil
                    // NB: that shouldn't happen since we already filter that when building the JSONSymbolSearchRoolObject
                    fetchActivityIndicator?.stopAnimating()
                    
                    // Animate deselection of cell
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
                    
                    // If the fetched item does not have a market, it cannot be used as a stock item
                    let alertView = UIAlertController(title: NSLocalizedString("Error", comment: "Error"),
                        message: NSLocalizedString("Search VC:No market", comment: "No market could be determined for this stock"),
                        preferredStyle: .Alert)
                    // cancel button
                    let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertView.addAction(cancelAction)
                    
                    presentViewController(alertView, animated: true, completion: nil)
                    
                    // Re-enable tableView selection
                    tableView.allowsSelection = true
                }
            }
        }
    }
    
    
    
    // MARK: Custom methods
    func searchStockSymbol(searchString: String) {
        
        FeedStore.sharedStore.searchStockSymbol(searchString, completion: { (symbolObject: JSONSymbolSearchRootObject?, error: NSError?) in
            // When the request completes, this block will be called
            // Refresh the UI in the main queue
            
            dispatch_async(dispatch_get_main_queue(), {
                
                // Stop spinning activity indicator
                //                self.searchActivityIndicator.stopAnimating()
                
                if error == nil {
                    // If everything went OK, grab the channel object, and reload the table
                    self.symbolRootObject = symbolObject
                    self.tableView.reloadData()
                    
                } else {
                    // If things went wrong, show an alert view
                    TSMessage.showNotificationInViewController(self.navigationController,
                        title: NSLocalizedString("Error", comment: "Error"),
                        subtitle: NSLocalizedString("Could not connect to server", comment: "Could not connect to server"),
                        type: .Error)
                    
                    
                    // Re-enable tableView selection
                    self.tableView.allowsSelection = true
                }
            }) // end of dispatch_async
        }) // end of completion block
    }
    
    
    func fetchStockQuotesForNewStock(stock: Stock) {
        var arrayOfSymbols = [String]()
        
        var currency = stock.currency
        // Special case for GBX (0,01 GBP)
        if currency == "GBX" { currency = "GBP" }
        
        if currency != GlobalSettings.sharedStore.portfolioCurrency {
            // Get the currency rate "combination" needed for the new stock
            var combination = "\(GlobalSettings.sharedStore.portfolioCurrency)\(currency)=X"
            
            if GlobalSettings.sharedStore.portfolioCurrency == "USD" {
                // Currency rate with USD must always feature USD as the base unit
                // Yahoo does not have combinations like USDEUR=X, only EURUSD=X
                combination = "\(currency)\(GlobalSettings.sharedStore.portfolioCurrency)=X"
            }
            arrayOfSymbols.append(combination)
        }
        arrayOfSymbols.append(stock.symbol)
        println("Array of symbols: \(arrayOfSymbols)")
        
        FeedStore.sharedStore.fetchStockQuotes(arrayOfSymbols, completion: { (stockObject: JSONStockDetailRootObject?, error: NSError?) in
            
            // When the request completes, this block will be called
            // Refresh the UI in the main queue
            
            dispatch_async(dispatch_get_main_queue(), {
                // Stop spinning activity indicator
                self.fetchActivityIndicator?.stopAnimating()
                
                if error == nil {
                    // If everything went OK, grab the channel object, and present a StockPurchaseViewController with the object
                    self.stockRootObject = stockObject
                    
                    println("Stock quote updated for new stock \(stock.symbol): \(stock.currentSharePrice)")
                    
                    // Present STOCK PURCHASE VC
                    self.performSegueWithIdentifier("BuyStocks", sender:self)
                    
                } else { // error occurred in the fetch
                    
                    TSMessage.showNotificationInViewController(self.navigationController,
                        title: NSLocalizedString("Error", comment: "Error"),
                        subtitle: NSLocalizedString("Could not connect to server", comment: "Could not connect to server"),
                        type: .Error)
                    
                    // Deselect cell which cannot be selected
                    if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow() {
                        self.tableView.deselectRowAtIndexPath(selectedRowIndexPath, animated: true)
                    }
                    
                    // Remove the stock in error from the StockStore
                    StockStore.sharedStore.removeStock(stock)
                    
                    // Re-enable tableView selection
                    self.tableView.allowsSelection = true
                }
            }) // end of dispatch_async
        }) // end of block
    }
    
    
    
    // MARK: Navigation
    
    // ** WARNING: "BuyStocks" is a segue from VC to VC in the storyboard, triggered by "didSelectRowAtIndexPath", not by selecting a row of the tableView
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as? UIViewController
        if let navController = destination as? UINavigationController {
            destination = navController.visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {
                
            case "BuyStocks":
                if let stockPurchaseVC = destination as? StockPurchaseViewController {
                    stockPurchaseVC.stock = selectedStock
                    
                    stockPurchaseVC.enableSearchTableViewSelectionClosure = {
                        // Re-enable tableView selection
                        self.tableView.allowsSelection = true
                        
                        // Animate deselection of previously selected cell
                        if let indexPathOfSelectedCell = self.tableView.indexPathForSelectedRow() {
                            self.tableView.deselectRowAtIndexPath(indexPathOfSelectedCell, animated:true)
                        }
                    }
                    
                    stockPurchaseVC.dismissClosure = {
                        self.dismissViewControllerAnimated(true, completion:nil)
                    }
                }
                
            default: break
            }
        }
    }
    
}