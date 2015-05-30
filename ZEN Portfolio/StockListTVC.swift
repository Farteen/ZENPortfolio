//
//  StockListTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 24/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

class StockListTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate { // UIPopoverPresentationControllerDelegate
    
    /** Stores the current presentation mode : quantity, value of the shares, gain or loss value, gain or loss %, etc. */
    var variableValueMode: Int = 1 // default = share quantity
    var variableValueArray = [String]()
    
    /** Date at which the stock quotes were updated for the last time. */
    var fetchDate: NSDate?
    
    
    
    // MARK: Private properties
    @IBOutlet private weak var lastUpdateButton: UIBarButtonItem! // Dummy barButtonItem whose customView is lastUpdateLabel
    
    @IBOutlet private weak var totalValueLabel: UILabel!
    @IBOutlet private weak var totalValueView: UIView!
    private var stockDetailTVC: StockDetailTableViewController?
    
    private var headerLabel = UILabel()
    private var lastUpdateLabel = UILabel(frame: CGRectZero)
    private var isRefreshing = false
    
    private var stockRootObject: JSONStockDetailRootObject?
    private var currencyRateRootObject: JSONStockDetailRootObject?
    
    private var lastOffset = CGPointZero // used to prevent the total value from scrolling
    
    // Empty View : used to display a message if list of stocks is empty
    private var emptyView: EmptyView?
    private var stocksDocumentLoaded = false // stocksDocument exists ?
    
    
    // Decimal formatter for Share price (2 fraction digits)
    private let sharePriceFormatter: NSNumberFormatter = {
        var decimalFormatter = NSNumberFormatter()
        decimalFormatter.numberStyle = .DecimalStyle
        decimalFormatter.minimumFractionDigits = 2
        decimalFormatter.maximumFractionDigits = 2
        decimalFormatter.locale = NSLocale.currentLocale()
        return decimalFormatter
        }()
    
    
    // Percentage formatter for Gain or loss % (2 fraction digits)
    private let percentageFormatter: NSNumberFormatter = {
        var percentFormatter = NSNumberFormatter()
        percentFormatter.numberStyle = .PercentStyle
        percentFormatter.minimumFractionDigits = 2
        percentFormatter.maximumFractionDigits = 2
        percentFormatter.locale = NSLocale.currentLocale()
        return percentFormatter
        }()
    
    
    
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        // caution : self.bounds not yet set !
        
        super.viewDidLoad()
        
        // Title view
        navigationItem.titleView = UIImageView(image: UIImage(named: "zenPortfolio_black.png"))
        
        
        // VARIABLE VALUE ARRAY
        // Constitute the variableValueArray from GlobalSettings buttonCycleArray
        let buttonCycleArray = GlobalSettings.sharedStore.buttonCycleArray
        for dict in buttonCycleArray {
            if let key = dict.keys.first {
                if dict[key] == true {
                    variableValueArray.append(key)
                }
            }
        }
        
        // Represents the (index +1) in the variableValueArray
        variableValueMode = GlobalSettings.sharedStore.variableValueMode
        
        
        // TOOLBAR
        // Dummy button containing the date of last update
        lastUpdateLabel.sizeToFit()
        lastUpdateLabel.backgroundColor = UIColor.clearColor()
        lastUpdateLabel.textAlignment = .Center
        lastUpdateButton.customView = lastUpdateLabel
        
        
        // Determine Stock detail View controller
        if let splitVC = self.splitViewController {
            if let navController = splitVC.viewControllers.last as? UINavigationController {
                stockDetailTVC = navController.visibleViewController as? StockDetailTableViewController
                if let detailViewController = stockDetailTVC {
                    // Show the first stock in the detailTVC
                    detailViewController.stock = StockStore.sharedStore.allStocks.first
                }
            }
        }
        
        // NOTIFICATION CENTER
        // On a SplitView : changing the model should update the tableView in StockListTVC
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addThisRow:",          name: NotificationCenterKeys.StockPurchaseVC_DidBuyShareNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deleteThisRow:",       name: NotificationCenterKeys.StockSellVC_DidSellShareCompletelyNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableView:",     name: NotificationCenterKeys.StockSellVC_DidSellSharePartiallyNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableView:",     name: NotificationCenterKeys.CurrencyPickerVC_PortfolioCurrencyDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButtonCycle:",   name: NotificationCenterKeys.ButtonCycleVC_ButtonCycleDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateTheme:",         name: NotificationCenterKeys.ThemeSelectorVC_CurrentThemeDidChangeNotification, object: nil)
        
        // If the application became active again, update stock
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateStocks",         name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        // iCloud
        // Stocks loaded from iCloud: reload tableView (use block!)
        NSNotificationCenter.defaultCenter().addObserverForName(NotificationCenterKeys.StockStore_LoadedStocksFromCloud, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
            self.reloadTableView(notification)
        }
        // Stock created / deleted via a CKSubscription
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addThisRow:",          name: NotificationCenterKeys.StockStore_StockCreatedFromSubscription, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deleteThisRow:",       name: NotificationCenterKeys.StockStore_StockDeletedFromSubscription, object: nil)

        
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // TOTAL VALUE
        // Set the initial frame of totalValueView : must be placed over the toolbar
        // Set the new totalViewFrame y coordinate as the height of self.view minus the height of the totalValueView, minus the height of the toolBar, plus the offset due to scrolling
        
        // TODO: check in future releases if Apple fixes the issue of the toolbar disappearing when pushing to detail VC / reappearing when popping from detailVC
        // NB : in the storyboard, property "hidesBottomBarWhenPushed" on the navigation controller is set to false (but that does not seem to be taken into account)
        var toolbarHeight = (navigationController?.toolbar.frame.size.height)!
        if navigationController?.toolbarHidden == true {
            toolbarHeight = 0
        }
        totalValueView.frame.origin.y = view.frame.size.height - totalValueView.bounds.size.height - toolbarHeight + view.bounds.origin.y
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // EMPTY VIEW
        updateEmptyView()
        
        // Table View SEPARATOR INSET
        tableView.separatorInset = GlobalSettings.sharedStore.currentTheme.themeSeparatorInset()
        tableView.layoutMargins = GlobalSettings.sharedStore.currentTheme.themeSeparatorInset()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Default values
        // NB: careful to retrieve these values AFTER the AppDelegate called applicationDidFinishLaunchingWithOptions, therefore not in viewDidLoad!
        fetchDate = NSUserDefaults.standardUserDefaults().objectForKey(Defaults.FetchDatePrefKey) as? NSDate
        
        
        // UPDATES
        // Fetch current stock valuation for all items
        // useful when coming back from other VC
        if UIApplication.sharedApplication().applicationState == .Active { // not in Background fetch
            updateStocks()
        }
        
        // Must be called each time the view will appear
        tableView.reloadData()
        
        // Update the UILabel with the DATE OF LAST UPDATE
        updateDateLabel()
        
        // Update Total Value Label
        updateTotalValueLabel()
       
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Stocks List")
        
        // iCloud: evaluate
        promptToUseiCloud()
        
    }
    
      
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        //        // Hide toolBar in Compact vertical size
        //        if traitCollection.verticalSizeClass == .Compact {
        //            navigationController?.toolbarHidden = true
        //        } else {
        //            navigationController?.toolbarHidden = false
        //        }
    }
    
    
    deinit {
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: Scrolling delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // Compensate the vertical scrolling so totalValueView stays at the same place
        totalValueView.frame.origin.y += scrollView.contentOffset.y - lastOffset.y
        lastOffset = scrollView.contentOffset
    }
    
    
    
    // MARK: Table view data source methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StockStore.sharedStore.allStocks.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let stock = StockStore.sharedStore.allStocks[indexPath.row]
        
        // Get the new or recycled cell
        var cell = tableView.dequeueReusableCellWithIdentifier("StockListCell", forIndexPath: indexPath) as! StockListTableViewCell
        
        // Define self as the cell controller
        cell.controller = self
        
        // configure the cell with the Item properties
        cell.nameLabel.text = stock.name
        cell.symbolLabel.text = stock.symbol
        
        
        // Implementation of the variable value
        switch variableValueArray[variableValueMode - 1] {
            
        case ButtonCycle.NumberOfShares:
            cell.variableTextButton.setTitle("\(stock.numberOfShares)", forState: UIControlState.Normal)
            cell.variableTextButton.backgroundColor = UIColor.zenGrayColor()
            
        case ButtonCycle.IntradayEvolution:
            if var formattedIntradayPercentageString = percentageFormatter.stringFromNumber(abs(stock.intradayEvolutionPercentage)) {
                
                if stock.intradayEvolutionPercentage >= 0 {
                    formattedIntradayPercentageString = "+ " + formattedIntradayPercentageString
                    cell.variableTextButton.backgroundColor = UIColor.zenGreenColor()
                } else {
                    formattedIntradayPercentageString = "- " + formattedIntradayPercentageString
                    cell.variableTextButton.backgroundColor = UIColor.zenRedColor()
                }
                cell.variableTextButton.setTitle(formattedIntradayPercentageString, forState:UIControlState.Normal)
            }
            
        case ButtonCycle.PortfolioValue:
            let formattedValueInPortfolioCurrencyString = sharePriceFormatter.stringFromNumber(stock.valueInPortfolioCurrency)
            cell.variableTextButton.setTitle(formattedValueInPortfolioCurrencyString, forState:UIControlState.Normal)
            cell.variableTextButton.backgroundColor = UIColor.zenGrayColor()
            
        case ButtonCycle.GainOrLossValue:
            if var formattedGainOrLossValueString = sharePriceFormatter.stringFromNumber(abs(stock.gainOrLossValue)) {
                
                if stock.gainOrLossValue >= 0 {
                    formattedGainOrLossValueString = "+ " + formattedGainOrLossValueString
                    cell.variableTextButton.backgroundColor = UIColor.zenGreenColor()
                } else {
                    formattedGainOrLossValueString = "- " + formattedGainOrLossValueString
                    cell.variableTextButton.backgroundColor = UIColor.zenRedColor()
                }
                cell.variableTextButton.setTitle(formattedGainOrLossValueString, forState:UIControlState.Normal)
            }
            
        case ButtonCycle.GainOrLossPercent:
            if var formattedGainOrLossPercentageString = percentageFormatter.stringFromNumber(abs(stock.gainOrLossPercentage)) {
                
                if stock.gainOrLossPercentage >= 0 {
                    formattedGainOrLossPercentageString = "+ " + formattedGainOrLossPercentageString
                    cell.variableTextButton.backgroundColor = UIColor.zenGreenColor()
                } else {
                    formattedGainOrLossPercentageString = "- " + formattedGainOrLossPercentageString
                    cell.variableTextButton.backgroundColor = UIColor.zenRedColor()
                }
                cell.variableTextButton.setTitle(formattedGainOrLossPercentageString, forState:UIControlState.Normal)
            }
            
        default:
            println("Unknown variable value mode")
        }
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // If the table view is asking to commit a delete command
        if editingStyle == .Delete {
            let stock = StockStore.sharedStore.allStocks[indexPath.row]
            
            // If the stock to be deleted is the one displayed in the detailVC
            if stockDetailTVC?.stock == stock {
                // Notify Detail Table View that this stock was deleted, so it displays an emptyView
                stockDetailTVC?.resetDeletedItem()
            }
            
            // Remove the stock from the StockStore
            StockStore.sharedStore.removeRecordFromCloud(stock) // Remove it first from iCloud!
            StockStore.sharedStore.removeStock(stock)
            
            // Remove that row from the table view with an animation
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Automatic)
            
            // Update the table view : causes problems with deletion animation ...
            //  tableView.reloadData()
            
            // Update Total Value Label
            updateTotalValueLabel()
            
            // Update (remove) date of last update
            updateDateLabel()
            
            // Update EmptyView
            updateEmptyView()
            
            // Tell the Detail Table View to update its view
            stockDetailTVC?.updateView()
        }
        
    }
    
    /* Replaced by a long press gesture
    
    override func tableView(tableView: UITableView!, moveRowAtIndexPath sourceIndexPath: NSIndexPath!, toIndexPath destinationIndexPath: NSIndexPath!) {
    StockStore.sharedStore.moveStockFromIndex(sourceIndexPath.row, toIndex:destinationIndexPath.row)
    
    // Re-apply color gradients
    tableView.reloadData()
    }
    */
    
    private var snapshot: UIView?
    private var tempIndexPath: NSIndexPath?
    private var sourceIndexPath: NSIndexPath? // Keep a hold on the initial indexPath of the moved cell


    @IBAction func longPressDetected(gesture: UILongPressGestureRecognizer) {
        // Long press to move rows
        let location = gesture.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(location)
        
        switch gesture.state {
            
        case .Began:
            if indexPath != nil {
                tempIndexPath = indexPath
                sourceIndexPath = indexPath
                
                if let cell = tableView.cellForRowAtIndexPath(indexPath!) {
                    
                    // Take a snapshot of the selected row using helper method
                    snapshot = customSnapshotFromView(cell)
                    
                    if snapshot != nil {
                        // Add the snapshot as subview, centered on the center of the cell
                        snapshot!.center = cell.center
                        snapshot!.alpha = 0.0
                        tableView.addSubview(snapshot!)
                        
                        UIView.animateWithDuration(0.25, animations: {
                            // Offset for gesture location
                            self.snapshot!.center.y = location.y
                            self.snapshot!.transform = CGAffineTransformMakeScale(1.05, 1.05)
                            self.snapshot!.alpha = 0.98
                            
                            // Black out
                            cell.hidden = true
                            // cell.backgroundColor = UIColor.blackColor()
                        })
                    }
                }
            }
            
        case .Changed:
            snapshot?.center.y = location.y
            
            // Is destination valid and different from the source ?
            if indexPath != nil && tempIndexPath != nil && indexPath != tempIndexPath {
                // ... move the row
                tableView.moveRowAtIndexPath(tempIndexPath!, toIndexPath:indexPath!)
                
                // ... and update tempIndexPath so it is in sync with UI changes
                tempIndexPath = indexPath
            }
            
        case .Ended:
            if indexPath != nil && sourceIndexPath != nil && indexPath != sourceIndexPath {
                
                // Update tempIndexPath so it is in sync with UI changes
                tempIndexPath = indexPath

                // Update datasource
                StockStore.sharedStore.moveStockFromIndex(sourceIndexPath!.row, toIndex:tempIndexPath!.row)
                StockStore.sharedStore.moveRecordInCloudFromIndex(sourceIndexPath!.row, toIndex:tempIndexPath!.row)
            }
            fallthrough
            
            
            
        default: // meaning gesture ended or was cancelled
            
            // Clean up
            if tempIndexPath != nil {
                if var cell = tableView.cellForRowAtIndexPath(tempIndexPath!) {
                    
                    UIView.animateWithDuration(0.25, animations: {
                        self.snapshot?.center = cell.center
                        self.snapshot?.transform = CGAffineTransformIdentity
                        self.snapshot?.alpha = 0.0
                        
                        // Undo the black-out effect
                        cell.hidden = false
                        //  cell.backgroundColor = initialCellBackgroundColor
                        
                        // Re-apply color gradients
                        self.tableView.reloadData()
                        
                        }, completion: { (finished: Bool) in
                            self.snapshot?.removeFromSuperview()
                            self.snapshot = nil
                    })
                    tempIndexPath = nil
                }
            }
        }
    }
    
    
    func customSnapshotFromView(inputView: UIView!) -> UIView! {
        var snapshot = inputView.snapshotViewAfterScreenUpdates(true)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0.0
        snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
        snapshot.layer.shadowRadius = 5.0
        snapshot.layer.opacity = 0.4
        
        return snapshot
    }
    
    
    // MARK: Table view delegate methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // After selection, deselect the line
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
    }
    
    
    // Cell gradient color
    func colorForIndex(index: Int) -> UIColor? {
        
        let itemCount = tableView.numberOfRowsInSection(0)
        let val = CGFloat(index) / CGFloat(itemCount) * 0.6
        
        return GlobalSettings.sharedStore.currentTheme.gradientColorForBaseValue(val)
    }
    
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        cell.backgroundColor = colorForIndex(indexPath.row)
        
        // Table View SEPARATOR INSET
        cell.separatorInset = GlobalSettings.sharedStore.currentTheme.themeSeparatorInset()
        cell.layoutMargins = GlobalSettings.sharedStore.currentTheme.themeSeparatorInset()
    }
    
    
    override func tableView(tableView: UITableView,heightForHeaderInSection section: Int) -> CGFloat {
        return 48 // Should be the same as the height of the TSMessage view that will cover it
    }
    
    
    override func tableView(tableView: UITableView,viewForHeaderInSection section: Int) -> UIView? {
        
        headerLabel.font = UIFont.boldSystemFontOfSize(18.0)
        headerLabel.textColor = UIColor.darkGrayColor()
        headerLabel.textAlignment = .Center
        headerLabel.backgroundColor = UIColor.clearColor()
        
        switch variableValueArray[variableValueMode - 1] {
            
        case ButtonCycle.NumberOfShares:
            let quantityLocalizedText = NSLocalizedString("List VC:Quantity text", comment:"Quantity")
            headerLabel.text = quantityLocalizedText
            
        case ButtonCycle.IntradayEvolution:
            let intradayEvolutionLocalizedText = NSLocalizedString("List VC:Intraday evolution text", comment:"Intraday evolution")
            headerLabel.text = intradayEvolutionLocalizedText
            
        case ButtonCycle.PortfolioValue:
            let stockValueLocalizedText = NSLocalizedString("List VC:Stock value text", comment:"Stock value");
            headerLabel.text = "\(stockValueLocalizedText) (\(GlobalSettings.sharedStore.portfolioCurrency))"
            
        case ButtonCycle.GainOrLossValue:
            let gainOrLossValueLocalizedText = NSLocalizedString("List VC:Gain/loss value text", comment:"Gain/loss value in ");
            headerLabel.text = "\(gainOrLossValueLocalizedText) (\(GlobalSettings.sharedStore.portfolioCurrency))"
            
        case ButtonCycle.GainOrLossPercent:
            let gainOrLossPercentageLocalizedText = NSLocalizedString("List VC:Gain/loss percentage text", comment:"Gain/loss percentage");
            headerLabel.text = gainOrLossPercentageLocalizedText
            
        default:
            println("Unknown variable value mode")
        }
        return headerLabel
    }
    
    
    
    // MARK: Stocks management methods
    
    func toggleValues(cell: StockListTableViewCell) {
        
        // Add 1 to the VariableValueMode each time the variable text button is tapped
        ++variableValueMode
        
        // If variableValueMode passes over (variableValueArray.count), go back to 1
        if variableValueMode > variableValueArray.count { variableValueMode = 1 }
        
        
        // Stock this variable value mode as a NSUserDefaults
        GlobalSettings.sharedStore.variableValueMode = variableValueMode
        
        // Store the cell for which the button was tapped
        if let indexPath = tableView.indexPathForCell(cell) {
            
            // Inform the detailViewController that this row was selected, so that it shows the correct info
            stockDetailTVC!.stock = StockStore.sharedStore.allStocks[indexPath.row]
        }
        
        // NB : cellForRowAtIndexPath takes VariableValueMode into account to define the way the cell displays variable value
        tableView.reloadData()
        
        // Update Total Value Label
        updateTotalValueLabel()
    }
    
    
    // Refresh control
    @IBAction func refreshControlPulled(sender: UIRefreshControl) {
        fetchStockQuotes()
    }
    
    
    /** Method used to call fetchStockQuotes. This method takes into account whether automatic update is activated in the app, and whether stock quotes are old enough to be refreshed
    */
    func updateStocks() {
        if !StockStore.sharedStore.allStocks.isEmpty {
            
            // Update only if not already refreshing
            if !isRefreshing {
                
                // Update only if automatic update is activated
                if GlobalSettings.sharedStore.automaticUpdate {
                    
                    // Update only if stock quotes are more than x minutes old
                    if let t:NSTimeInterval = fetchDate?.timeIntervalSinceNow {
                        
                        //                        println("fetchdate: \(fetchDate)")
                        //                        println("Update frequency: \(GlobalSettings.sharedStore.updateFrequency) mn")
                        //                        println("time diff: \(t)")
                        
                        if t < (-60 * NSTimeInterval(GlobalSettings.sharedStore.updateFrequency)) {
                            
                            println("Updating stock quotes and currency rates")
                            fetchStockQuotes() // update ALL stock quotes and currency rates
                            
                        } else  { println("Stock quotes are less than \(GlobalSettings.sharedStore.updateFrequency) mn old") }
                        
                    } else {
                        println ("No fetchdate could be determined")
                        println("Updating stock quotes and currency rates")
                        fetchStockQuotes() // update ALL stock quotes and currency rates
                    }
                    
                } else { println("Automatic update deactivated") }
                
            } else { println ("Already refreshing") }
            
        } else { println("No stocks") }
    }
    
    
    func fetchStockQuotes() {
        refreshControl?.beginRefreshing()
        fetchStockQuotesWithCompletionHandler(nil)
        // NB: refreshControl.endRefreshing() is taken care of in the completion block of fetchStockQuotesWithCompletionHandler:
    }
    
    
    func fetchStockQuotesWithCompletionHandler(completionHandler: (UIBackgroundFetchResult -> Void)!) {
        
        var arrayOfSymbols = Array<String>()
        var arrayOfStocks = Array<String>()
        var arrayOfCurrencyRates = Array<String>()
        
        
        for stock in StockStore.sharedStore.allStocks {
            
            // * Array of symbols
            if find(arrayOfStocks, stock.symbol) == nil {
                // Add stock to arrayofSymbols only if not there already
                arrayOfStocks.append(stock.symbol)
            }
            
            // * Array of currencies
            
            // recalculate the needed currency rates (useful for initialization).
            
            // Combinations only make sense if the stock currency is different from the portfolio currency (chosen in Preferences)
            
            var currency = stock.currency
            // Special case for GBX (0,01 GBP)
            if currency == "GBX" { currency = "GBP" }
            
            if currency != GlobalSettings.sharedStore.portfolioCurrency {
                
                var combination = GlobalSettings.sharedStore.portfolioCurrency + currency + "=X"
                
                if GlobalSettings.sharedStore.portfolioCurrency == "USD" {
                    // currency rate with USD must always feature USD as the base unit
                    // Yahoo does not have combinations like USDEUR=X, only EURUSD=X
                    combination = currency + GlobalSettings.sharedStore.portfolioCurrency + "=X"
                }
                
                if find(arrayOfCurrencyRates, combination) == nil {
                    // Add combination to arrayofSymbols only if not there already
                    arrayOfCurrencyRates.append(combination)
                }
            }
        }
        
        // Remove unused currency rates from ZENCurrencyRateStore
        for key in CurrencyRateStore.sharedStore.dictionary.keys {
            if find(arrayOfCurrencyRates, key) == nil {
                CurrencyRateStore.sharedStore.deleteRateForKey(key)
                println("CurrencyRateStore: removed currency rate \(key)")
            }
        }
        
        // In the array of symbols (submitted to fetchStockQuotes), add the array of currencies first
        arrayOfSymbols += arrayOfCurrencyRates
        // and then the array of stocks, so that the stocks are updated with the correct current exchange rate
        arrayOfSymbols += arrayOfStocks
        
        println("Array of symbols: \(arrayOfSymbols)")
        
        
        if !arrayOfSymbols.isEmpty {
            
            // Trigger myRefreshControl
            isRefreshing = true
            
            FeedStore.sharedStore.fetchStockQuotes(arrayOfSymbols, completion: { (jsonObject: JSONStockDetailRootObject?, error: NSError?) in
                
                // When the request completes, this block will be called
                // Refresh the UI in the main queue
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if error == nil {
                        // If the block completed without an error, grab the channel object
                        self.stockRootObject = jsonObject
                        println("Fetch Stock quotes complete")
                        
                        if self.stockRootObject?.items != nil {
                            
                            // Reload the table
                            self.tableView.reloadData()
                            
                            // Update FETCHDATE (last update of the stock quotes)
                            if self.stockRootObject?.fetchDate != nil {
                                
                                self.fetchDate = self.stockRootObject?.fetchDate // not nil, can be unwrapped safely
                                // Stock this fetchDate as a NSUserDefaults
                                NSUserDefaults.standardUserDefaults().setObject(self.fetchDate!, forKey:  Defaults.FetchDatePrefKey)
                                println("Saved fetchDate \(self.fetchDate!) as NSUserDefaults")
                                // Update the UILabel with the date of last update
                                self.updateDateLabel()
                            }
                            
                            // Update Total Value Label
                            self.updateTotalValueLabel()
                            
                            // Background fetch completion handler
                            if completionHandler != nil {
                                completionHandler(UIBackgroundFetchResult.NewData)
                                
                                self.checkForStockNotifications(StockNotificationStore.sharedStore.allNotifications)
                                
                            } else {
                                // If things went OK, show a success notification
                                TSMessage.showNotificationWithTitle(NSLocalizedString("Stock quotes updated", comment: "Stock quotes have been updated"),
                                    type: TSMessageNotificationType.Success)
                                
                                self.checkForStockNotifications(StockNotificationStore.sharedStore.allNotifications)
                            }
                            
                            // Let the StockStore know that the stocks quotes have been updated, so it can save the latest info to iCloud
                            if CloudManager.sharedManager.cloudActivated {
                                NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockListVC_DidUpdateStockQuotesNotification, object: nil)
                            }
                            
                        } else { // Yahoo!Finance fetched back an empty stockRootObject.items array
                            
                            // Background fetch completion handler
                            if completionHandler != nil {
                                completionHandler(UIBackgroundFetchResult.Failed);
                                
                            } else {
                                // If things went wrong, show an error notification
                                TSMessage.showNotificationWithTitle(NSLocalizedString("Error updating stock quotes", comment: "Error updating stock quotes"),
                                    subtitle:NSLocalizedString("Yahoo Finance unavailable", comment: "Yahoo Finance is unavailable"),
                                    type:TSMessageNotificationType.Error)
                            }
                        }
                        
                        // end activity of update representations
                        self.refreshControl?.endRefreshing()
                        self.isRefreshing = false
                        
                    } else { // Error
                        
                        // Background fetch completion handler
                        if completionHandler != nil {
                            completionHandler(UIBackgroundFetchResult.Failed)
                            
                        } else {
                            // If things went wrong, show a warning notification
                            TSMessage.showNotificationWithTitle(NSLocalizedString("Could not connect to server", comment: "Could not connect to server"),
                                subtitle:NSLocalizedString("Check your Internet connection", comment: "Check your Internet connection"),
                                type:TSMessageNotificationType.Warning)
                        }
                        
                        // end activity of update representations
                        self.refreshControl?.endRefreshing()
                        self.isRefreshing = false
                    }
                }) // end dispatch_async
            })
        } else {
            println("No stocks / currencies to update")
            self.refreshControl?.endRefreshing()
            self.isRefreshing = false
            
            // Background fetch completion handler
            if completionHandler != nil {
                completionHandler(UIBackgroundFetchResult.NoData)
            }
        }
        
        
    }
    
    func updateDateLabel() {
        
        // If list of stocks is empty, show nothing in the date label
        if StockStore.sharedStore.allStocks.isEmpty {
            lastUpdateLabel.attributedText = nil
        } else {
            // Format the date of last update according to the NSLocale local time zone
            var localFormatter = NSDateFormatter()
            localFormatter.dateStyle = .ShortStyle
            localFormatter.timeStyle = .ShortStyle
            
            if fetchDate != nil {
                let localDateString = localFormatter.stringFromDate(fetchDate!)
                
                // Attributed string for the date of last update
                if localDateString.isEmpty {
                    lastUpdateLabel.attributedText = nil
                } else {
                    let updateDateAttrString = NSAttributedString(string: localDateString,
                        attributes: [
                            NSFontAttributeName             :   UIFont.boldSystemFontOfSize(12.0),
                            NSForegroundColorAttributeName  :   UIColor.darkGrayColor(),
                        ])
                    
                    // Attributed string for the text of last update
                    let updateText = NSLocalizedString("List VC:Update text", comment: "Last update: ")
                    var updateTextAttrString = NSMutableAttributedString(string: updateText,
                        attributes: [
                            NSFontAttributeName             :   UIFont.systemFontOfSize(12.0),
                            NSForegroundColorAttributeName  :   UIColor.darkGrayColor(),
                        ])
                    
                    updateTextAttrString.appendAttributedString(updateDateAttrString)
                    lastUpdateLabel.attributedText = updateTextAttrString
                    lastUpdateLabel.sizeToFit()
                }
            }
        }
    }
    
    
    func updateTotalValueLabel() {
        totalValueLabel.textAlignment = .Right
        
        // If list of stocks is empty, show nothing in the total view
        if StockStore.sharedStore.allStocks.isEmpty {
            totalValueLabel.hidden = true
            
        } else {
            // Attributed string for localized text
            totalValueLabel.hidden = false
            
            let totalLabelString = NSLocalizedString("List VC:Footer text", comment: "Total :")
            
            let fontSize: CGFloat = totalValueLabel.font.pointSize // Get the font size defined in the storyboard
            var totalLabelAttString = NSMutableAttributedString(string: totalLabelString,
                attributes: [
                    NSFontAttributeName             :   UIFont.boldSystemFontOfSize(fontSize),
                    NSForegroundColorAttributeName  :   UIColor.darkGrayColor(),
                    NSTextEffectAttributeName       :   NSTextEffectLetterpressStyle,
                ])
            
            // Attributed string for footerValue
            var totalValue = NSMutableAttributedString()
            
            switch variableValueArray[variableValueMode - 1] {
                
            case ButtonCycle.NumberOfShares:
                let formattedNumberOfSharesString = "\(StockStore.sharedStore.portfolioNumberOfShares)"
                
                // Attributed string for Total Current Value
                totalValue = NSMutableAttributedString(string: formattedNumberOfSharesString,
                    attributes:[
                        NSForegroundColorAttributeName  :    UIColor.blackColor(),
                    ])
                
            case ButtonCycle.IntradayEvolution:
                totalValueLabel.hidden = true
                
            case ButtonCycle.PortfolioValue:
                if let formattedValueInPortfolioCurrencyString = sharePriceFormatter.stringFromNumber(StockStore.sharedStore.portfolioTotalValue) {
                    
                    // Attributed string for Total Current Value
                    let totalValueString = GlobalSettings.sharedStore.portfolioCurrency + "  " + formattedValueInPortfolioCurrencyString
                    totalValue = NSMutableAttributedString(string: totalValueString,
                        attributes:[
                            NSForegroundColorAttributeName  :   UIColor.blackColor(),
                        ])
                }
                
            case ButtonCycle.GainOrLossValue:
                if var formattedGainOrLossValueString = sharePriceFormatter.stringFromNumber(fabs(StockStore.sharedStore.portfolioGainOrLossValue)) {
                    if StockStore.sharedStore.portfolioGainOrLossValue >= 0 {
                        formattedGainOrLossValueString = "+ " + formattedGainOrLossValueString
                    } else {
                        formattedGainOrLossValueString = "- " + formattedGainOrLossValueString
                    }
                    
                    // Attributed string for Total gain / loss value
                    let totalValueString = "\(GlobalSettings.sharedStore.portfolioCurrency)   \(formattedGainOrLossValueString)"
                    totalValue = NSMutableAttributedString(string: totalValueString)
                    
                    // Conditional color for Gain or loss
                    if StockStore.sharedStore.portfolioGainOrLossValue >= 0 {
                        totalValue.addAttribute(NSForegroundColorAttributeName, value: UIColor.zenGreenColor(), range: NSMakeRange(0,count(totalValueString)))
                    } else {
                        totalValue.addAttribute(NSForegroundColorAttributeName, value: UIColor.zenRedColor(), range: NSMakeRange(0, count(totalValueString)))
                    }
                }
                
            case ButtonCycle.GainOrLossPercent:
                if var formattedGainOrLossPercentageString = percentageFormatter.stringFromNumber(fabs(StockStore.sharedStore.portfolioGainOrLossPercentage)) {
                    if StockStore.sharedStore.portfolioGainOrLossPercentage >= 0 {
                        formattedGainOrLossPercentageString = "+ " + formattedGainOrLossPercentageString
                    } else {
                        formattedGainOrLossPercentageString = "- " + formattedGainOrLossPercentageString
                    }
                    // Attributed string for Total gain / loss value
                    totalValue = NSMutableAttributedString(string: formattedGainOrLossPercentageString)
                    
                    // Conditional color for Gain or loss
                    if StockStore.sharedStore.portfolioGainOrLossPercentage >= 0 {
                        totalValue.addAttribute(NSForegroundColorAttributeName, value: UIColor.zenGreenColor(), range: NSMakeRange(0, count(formattedGainOrLossPercentageString)))
                    } else {
                        totalValue.addAttribute(NSForegroundColorAttributeName, value: UIColor.zenRedColor(), range: NSMakeRange(0, count(formattedGainOrLossPercentageString)))
                    }
                }
                
            default:
                println("Unknown variable value mode")
                
            }
            
            // Common attributes for total Value
            totalValue.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(fontSize), range:NSMakeRange(0, count(totalValue.string as String)))
            
            // Concatenate attributed strings (footerIntroduction + footerValue)
            totalLabelAttString.appendAttributedString(totalValue)
            
            // Common attributes
            totalLabelAttString.addAttribute(NSTextEffectAttributeName, value:NSTextEffectLetterpressStyle, range: NSMakeRange(0, count(totalLabelAttString.string as String)))
            totalValueLabel.attributedText = totalLabelAttString
        }
    }
    
    
    /** Display empty view with a message "No stocks" */
    func updateEmptyView() {
        
        // Remove any existing emptyView (to account for change of dimensions / rotation)
        emptyView?.removeFromSuperview()
        emptyView = nil
        
        if StockStore.sharedStore.allStocks.isEmpty {
            // Create an empty view
            emptyView = EmptyView(frame: tableView.bounds, message: NSLocalizedString("List VC:Header No Stocks", comment: "No stocks"))
            
            tableView.addSubview(emptyView!)
        }
    }
    
    
    
    /** Check if local notifications must be fired after update */
    func checkForStockNotifications(notifications: Array<StockNotification>) {
        
        var notificationsToRemove = [StockNotification]()
        
        for notification in notifications {
            
            var notificationWillBeFired = false
            
            if (notification.stockIdentifier != nil) && (notification.stock != nil) {
                
                // Check if the comparison must be ascending or descending
                if notification.compareAscending {
                    
                    switch notification.type {
                    case .Price:
                        // Check if the notification target level has been reached
                        if notification.stock!.currentSharePrice >= notification.target {
                            notificationWillBeFired = true
                        }
                        
                    case .StockValue:
                        // Check if the notification target level has been reached
                        if notification.stock!.valueInPortfolioCurrency >= notification.target {
                            notificationWillBeFired = true
                        }
                        
                    case .GainOrLossValue:
                        // Check if the notification target level has been reached
                        if notification.stock!.gainOrLossValue >= notification.target {
                            notificationWillBeFired = true
                        }
                        
                    case .GainOrLossPercentage:
                        // Check if the notification target level has been reached
                        if notification.stock!.gainOrLossPercentage >= notification.target {
                            notificationWillBeFired = true
                        }
                    }
                    
                } else { // compare descending
                    
                    switch notification.type {
                    case .Price:
                        // Check if the notification target level has been reached
                        if notification.stock!.currentSharePrice <= notification.target {
                            notificationWillBeFired = true
                        }
                        
                    case .StockValue:
                        // Check if the notification target level has been reached
                        if notification.stock!.valueInPortfolioCurrency <= notification.target {
                            notificationWillBeFired = true
                        }
                        
                    case .GainOrLossValue:
                        // Check if the notification target level has been reached
                        if notification.stock!.gainOrLossValue <= notification.target {
                            notificationWillBeFired = true
                        }
                        
                    case .GainOrLossPercentage:
                        // Check if the notification target level has been reached
                        if notification.stock!.gainOrLossPercentage <= notification.target {
                            notificationWillBeFired = true
                        }
                    }
                }
                
                
                if notificationWillBeFired == true {
                    // Fire UILocalNotification
                    
                    var targetValue = String()
                    var targetUnit = String() // escaped form of % (so that it prints correctly in UILocalNotifications)
                    
                    if notification.type == StockNotificationType.GainOrLossPercentage {
                        targetValue = sharePriceFormatter.stringFromNumber(notification.target * 100)! // Present in %
                        targetUnit = "%%"
                    } else {
                        targetValue = sharePriceFormatter.stringFromNumber(notification.target)!
                        targetUnit = notification.targetUnit
                    }
                    
                    // Alternate (shorter) description for Gain or Loss
                    var notificationTypeAltDescription = String()
                    if notification.type == .GainOrLossValue || notification.type == .GainOrLossPercentage {
                        notificationTypeAltDescription = NSLocalizedString("Create Stock Notif Main VC:gain", comment: "GAIN OR LOSS").uppercaseString
                    } else { // share price or current value
                        notificationTypeAltDescription = notification.typeDescription.uppercaseString
                    }
                    
                    var message = String()
                    if notification.compareAscending == true {
                        message = String.localizedStringWithFormat(NSLocalizedString("Local notification:message (over)", comment: "The *notification type* of *stock name* *has gone over* *target value* *target unit*"), notificationTypeAltDescription, notification.stock!.name, targetValue, targetUnit)
                    } else {
                        message = String.localizedStringWithFormat(NSLocalizedString("Local notification:message (under)", comment: "The *notification type* of *stock name* *has gone under* *target value* *target unit*"), notificationTypeAltDescription, notification.stock!.name, targetValue, targetUnit)
                    }
                    
                    var localNotification = UILocalNotification()
                    localNotification.alertBody = message
                    localNotification.soundName = UILocalNotificationDefaultSoundName
                    UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
                    
                    // Increase the badge indicator by one
                    ++UIApplication.sharedApplication().applicationIconBadgeNumber
                    
                    // Remove the stock notification from the StockNotificationStore
                    notificationsToRemove.append(notification)
                }
                
            } else {
                // Remove notifications which don't have a stockIdentifier property, or for which the notification stock cannot be determined
                notificationsToRemove.append(notification)
            }
        } // for loop
        
        // Remove notifications that were fired
        for notification in notificationsToRemove {
            StockNotificationStore.sharedStore.removeNotification(notification)
            StockNotificationStore.sharedStore.removeRecordFromCloud(notification)
        }
        // Reload data in Notifications list table view
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.StockListVC_DidFireLocalNotificationNotification, object:nil)
    }
    
    
    
    // MARK: iCloud evaluation
    func promptToUseiCloud() {
        
        
            // Ask user if want to turn on iCloud if we haven't asked already
//            println("Already asked the user if he wants to activate iCloud ? \(CloudManager.sharedManager.cloudPrompted)")

            if !CloudManager.sharedManager.cloudActivated && !CloudManager.sharedManager.cloudPrompted {
                
                CloudManager.sharedManager.cloudPrompted = true
                
                var alertView = UIAlertController(
                    title: NSLocalizedString("iCloud:available", comment: "iCloud storage available"),
                    message: NSLocalizedString("iCloud:cloud storage", comment: "Automatically store your documents in iCloud to keep them up-to-date across all your devices?"),
                    preferredStyle: .Alert)
                
                // Yes = activate iCloud
                let acceptAction = UIAlertAction(title: NSLocalizedString("iCloud:open settings", comment: "Open settings"), style: .Default, handler: { (alertAction) in
                    self.performSegueWithIdentifier("DisplayPreferences", sender: self)

                })
                alertView.addAction(acceptAction)
                
                // No = cancel
                let refuseAction = UIAlertAction(title: NSLocalizedString("iCloud:not now", comment :"Not now"), style: .Cancel, handler: nil)
                alertView.addAction(refuseAction)
                
                presentViewController(alertView, animated: true, completion: nil)
            }
        }
    
    
    // MARK: Navigation methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as? UIViewController
        if let navController = destination as? UINavigationController {
            destination = navController.visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {
                
            case "DisplayStockDetails":
                println("Segue to StockDetailVC")
                if let stockDetailTVC = destination as? StockDetailTableViewController {
                    if let indexPath = tableView.indexPathForSelectedRow() {
                        stockDetailTVC.stock = StockStore.sharedStore.allStocks[indexPath.row]
                        stockDetailTVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
                        stockDetailTVC.navigationItem.leftItemsSupplementBackButton = true
                    }
                }
                
            case "DisplayPreferences":
                println("Segue to Preferences")
//                // Determine if Preferences TVC is presented in a popover
//                if let preferencesTVC = destination as? PreferencesTableViewController {
//                    if let ppc = preferencesTVC.popoverPresentationController {
//                        ppc.delegate = self
//                    }
//                }
                
            case "SearchStockSymbol":
                println("Segue to Search Stock VC")
                
            case "DisplaySalesJournal":
                println("Segue to Sales Journal")
                
            default: break
            }
        }
    }
    
    @IBAction func closeSalesJournal(segue: UIStoryboardSegue) {
        // Unwind Segue
        println("Closing Sales journal VC")
        
        // Necessary on iPad with Form Sheet presentation
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func terminatePrefs(segue: UIStoryboardSegue) {
        // Unwind Segue
        println("Closing Preferences VC")
        
    }
    
    
//    // MARK: PopoverPresentationControllerDelegate methods
//    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
//        return .FullScreen
//    }
//    
//    
//    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
//        return UINavigationController(rootViewController: controller.presentedViewController)
//    }
    
    
    // MARK: Notification center methods
    func reloadTableView(notification: NSNotification) {
        
        // Useful to reload data of the tableView after portfolio currency has been changed
        tableView.reloadData()

        // Update Last Update Date
        updateDateLabel()

        // Update Total Value Label
        updateTotalValueLabel()
        
        // Show EmptyView if list of stocks is empty
        updateEmptyView()
    }
    
    
    func addThisRow(notification: NSNotification) {
        // Get the row from the notification userInfo dictionary
        if let row = notification.userInfo?["index"] as? NSString {
            // Get the indexPath for this row in the unique section
            let indexPath = NSIndexPath(forRow: row.integerValue, inSection:0)
            // Add row with animation
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation:.Left)
            // Update the tableView header / footer
            tableView.reloadData()
            // Update Total Value Label
            updateTotalValueLabel()
            // Update Last Update Date
            updateDateLabel()
            // Remove emptyView
            updateEmptyView()
        }
    }
    
    
    func deleteThisRow(notification: NSNotification) {
        // Get the row from the notification userInfo dictionary
        if let row = notification.userInfo?["index"] as? NSString {
            // Get the indexPath for this row in the unique section
            let indexPath = NSIndexPath(forRow: row.integerValue, inSection:0)
            // Delete row with animation
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Left)
            // Update the tableView header / footer
            tableView.reloadData()
            // Update Total Value Label
            updateTotalValueLabel()
            // Update Last Update Date
            updateDateLabel()
            // Show emptyView if list of stocks is empty
            updateEmptyView()
        }
    }
    
    
    func updateButtonCycle(notification: NSNotification) {
        
        // Re-create the variableValueArray from GlobalSettings buttonCycleArray and buttoncycleDict
        variableValueArray.removeAll(keepCapacity: true)
        let buttonCycleArray = GlobalSettings.sharedStore.buttonCycleArray
        for dict in buttonCycleArray {
            if let key = dict.keys.first {
                if dict[key] == true {
                    variableValueArray.append(key)
                }
            }
        }
        
        // Useful to reload data of the tableView after button cycle has been changed
        tableView.reloadData()
        
        // Update NSUserDefaults
        variableValueMode = 1
        GlobalSettings.sharedStore.variableValueMode = variableValueMode
        
        // Update Total Value Label
        updateTotalValueLabel()
    }
    
    
    
    func updateTheme(notification: NSNotification) {
        // Useful to reload data of the tableView after theme has been changed
        // Table View SEPARATOR INSET
        tableView.separatorInset = GlobalSettings.sharedStore.currentTheme.themeSeparatorInset()
        tableView.layoutMargins = GlobalSettings.sharedStore.currentTheme.themeSeparatorInset()
        tableView.reloadData()
    }



}