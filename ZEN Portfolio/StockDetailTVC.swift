//
//  StockDetailTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 25/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


class StockDetailTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Public properties
    var stock: Stock? {
        didSet {
            
            var currency = stock?.currency
            // Special case for GBX (0,01 GBP)
            if currency == "GBX" { currency = "GBP" }
            
            if currency == GlobalSettings.sharedStore.portfolioCurrency {
                
                sections = [
                    Section(type: .General, items: [.NumberOfShares, .DatePurchase]),
                    Section(type: .Price, items: [.PricePurchase, .PriceCurrent]),
                    Section(type: .Intraday, items: [.IntradayValue, .IntradayPercentage]),
                    Section(type: .Valuation, items: [.ValuationPurchase, .ValuationCurrent]),
                    Section(type: .GainOrLoss, items: [.GainOrLossValue, .GainOrLossPercentage])
                ]
                
            } else { // currency != GlobalSettings.sharedStore.portfolioCurrency
                
                sections = [
                    Section(type: .General, items: [.NumberOfShares, .DatePurchase]),
                    Section(type: .Price, items: [.PricePurchase, .PriceCurrent]),
                    Section(type: .Intraday, items: [.IntradayValue, .IntradayPercentage]),
                    Section(type: .CurrencyRate, items: [.CurrencyRatePurchase, .CurrencyRateCurrent]),
                    Section(type: .Valuation, items: [.ValuationPurchase, .ValuationCurrent]),
                    Section(type: .GainOrLoss, items: [.GainOrLossValue, .GainOrLossPercentage])
                ]
            }
            
            if isViewLoaded() {
                // Update the UI
                updateView()
            }
        }
    }
    
    
    
    
    private var sections = [Section]()
    
    // MARK: Private struct and enum
    private struct Section {
        var type: SectionType
        var items: [Item]
    }
    
    private enum SectionType {
        case General
        case Price
        case Intraday
        case CurrencyRate
        case Valuation
        case GainOrLoss
    }
    
    private enum Item {
        case NumberOfShares
        case DatePurchase
        case PricePurchase
        case PriceCurrent
        case IntradayValue
        case IntradayPercentage
        case CurrencyRatePurchase
        case CurrencyRateCurrent
        case ValuationPurchase
        case ValuationCurrent
        case GainOrLossValue
        case GainOrLossPercentage
    }
    
    
    // MARK: Private properties
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var createNotificationButton: UIBarButtonItem!
    @IBOutlet private weak var sellStocksButton: UIBarButtonItem!
    @IBOutlet private weak var lastTradeDateButton: UIBarButtonItem! // Dummy barButtonItem whose customView is lastTradeDateLabel
    
    private var lastTradeDateLabel = UILabel(frame: CGRectZero)
    private var headerLabel: UILabel?
    
    
    // Decimal formatter for Share price (2 fraction digits)
    private let sharePriceFormatter: NSNumberFormatter = {
        var decimalFormatter = NSNumberFormatter()
        decimalFormatter.numberStyle = .DecimalStyle
        decimalFormatter.minimumFractionDigits = 2
        decimalFormatter.maximumFractionDigits = 2
        decimalFormatter.locale = NSLocale.currentLocale()
        return decimalFormatter
        }()
    
    // Decimal formatter for Currency rate (4 fraction digits)
    private let currencyRateFormatter: NSNumberFormatter = {
        var rateFormatter = NSNumberFormatter()
        rateFormatter.numberStyle = .DecimalStyle
        rateFormatter.minimumFractionDigits = 4
        rateFormatter.maximumFractionDigits = 4
        rateFormatter.locale = NSLocale.currentLocale()
        return rateFormatter
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
    
    
    // Date formatter
    private let dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter
        }()
    
    
    // Empty View : used to display a message no stock is selected
    private var emptyView: EmptyView?
    
    
    
    // MARK: Update view methods
    
    func updateView() {
        if stock != nil {
            
            if traitCollection.horizontalSizeClass == .Compact {
                navigationItem.title = "\(stock!.symbol)"
                
            } else {
                navigationItem.title = "\(stock!.name)"
            }
            
            // Reload table content
            tableView.reloadData()
            
            // Update the UILabel with the date of last update
            displayLastTradeDateForItem(stock!)
            
            // Remove emptyView
            updateEmptyView()
            
            sellStocksButton.enabled = true
            
            
            // SEGMENTEDCONTROL buttons enabled
            if StockStore.sharedStore.allStocks.count <= 1 { // if there is none or only 1 entry, no neeed for a segmented control
                segmentedControl.hidden = true
                segmentedControl.enabled = false
                
            } else {
                // Disable "up" arrow for first stock item
                if stock === StockStore.sharedStore.allStocks.first {
                    segmentedControl.setEnabled(false, forSegmentAtIndex:0)
                }
                // Disable "down" arrow for last stock item
                if stock === StockStore.sharedStore.allStocks.last {
                    segmentedControl.setEnabled(false, forSegmentAtIndex:1)
                }
            }
            
        } else { // stock is nil -> no stock selected
            // Set title to nil
            navigationItem.title = nil
            
            // Disable sellStocksButton and createNotificationButton
            sellStocksButton.enabled = false
            createNotificationButton.enabled = false
            
            // Display emptyView
            updateEmptyView()
            
            // deactivate SegmentedControl
            segmentedControl.hidden = true
            segmentedControl.enabled = false
            
            // Remove last trade date label
            lastTradeDateLabel.text = nil
        }
    }
    
    
    func resetDeletedItem() {
        stock = nil
        updateView()
    }
    
    
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SEGMENTED CONTROL
        segmentedControl.momentary = true
        
        // TOOLBAR
        // Disable sellStocksButton and createNotificationButton if no item is selected (iPad)
        sellStocksButton.enabled = stock == nil ? false : true
        createNotificationButton.enabled = stock == nil ? false : true
        
        // Dummy button containing the date of last update
        
        lastTradeDateLabel.sizeToFit()
        lastTradeDateLabel.backgroundColor = UIColor.clearColor()
        lastTradeDateLabel.textAlignment = .Center
        lastTradeDateButton.customView = lastTradeDateLabel
        
        
        // NOTIFICATION CENTER
        // With SplitView: changing the model should reload tableView in StockDetailTVC
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"removeStock:",         name:NotificationCenterKeys.CurrencyPickerVC_PortfolioCurrencyDidChangeNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"removeStock:",         name:NotificationCenterKeys.StockSellVC_DidSellShareCompletelyNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadTableView:",     name:NotificationCenterKeys.StockSellVC_DidSellSharePartiallyNotification, object:nil)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // EMPTY VIEW
        updateEmptyView()
    }
    
    
    /** Display empty view with a message "No stock selected" */
    func updateEmptyView() {
        
        // Remove any existing emptyView (to account for change of dimensions / rotation)
        emptyView?.removeFromSuperview()
        emptyView = nil
        
        
        if stock == nil {
            // Create an empty view
            emptyView = EmptyView(frame: tableView.bounds, message: NSLocalizedString("Detail VC:no item selected", comment: "No stock selected"))
            tableView.addSubview(emptyView!)
            
        }
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Update the UI
        updateView()
        
        // Update the UILabel with the date of last update
        if stock != nil {
            displayLastTradeDateForItem(stock!)
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Stock Detail")
    }
    
 
    
    
    deinit {
        // Remove observer when DetailVC is no longer visible
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int     {
        
        if stock != nil {
            return sections.count
            
        } else { // stock = nil
            return  1
        }
    }
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionLocalizedString = String()
        
        if stock != nil {
            // NB: If a stock was selected, that means stock is non-nil and can be safely unwrapped
            
            var currency = stock!.currency
            // Special case for GBX (0,01 GBP)
            if currency == "GBX" { currency = "GBP" }
            
            switch sections[section].type {
            case .General:
                return "\(stock!.name) - \(stock!.market)"
            case .Price:
                sectionLocalizedString = NSLocalizedString("Detail VC:section share price", comment: "Share price")
                return "\(sectionLocalizedString) (\(stock!.currency))"
            case .Intraday:
                return NSLocalizedString("Detail VC:section intraday evolution", comment: "Intraday evolution")
            case .CurrencyRate:
                sectionLocalizedString = NSLocalizedString("Detail VC:section currency rate", comment: "Currency rate")
                return "\(sectionLocalizedString) (\(GlobalSettings.sharedStore.portfolioCurrency)/\(currency))"
            case .Valuation:
                sectionLocalizedString = NSLocalizedString("Detail VC:section stock valuation", comment: "Stock valuation")
                return "\(sectionLocalizedString) (\(GlobalSettings.sharedStore.portfolioCurrency))"
            case .GainOrLoss:
                return NSLocalizedString("Detail VC:section gain or loss", comment: "Gain or loss")
            }
            
        } else {
            // no stock selected
            return nil
        }
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        
        if stock != nil {
            return sections[section].items.count
            
        } else { // no stock selected
            return 1
        }
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("StockDetailCell", forIndexPath: indexPath) as! UITableViewCell
        
        // Default cell text formatting
        cell.textLabel?.textColor = UIColor.blackColor()
        cell.detailTextLabel?.textColor = UIColor.zenGrayTextColor()
        
        // Disable cell selection
        cell.selectionStyle = .None
        
        if stock != nil {
            // NB: If a stock was selected, that means stock is non-nil and can be safely unwrapped
            
            switch sections[indexPath.section].items[indexPath.row] {
                
            case .NumberOfShares:
                cell.textLabel?.text = NSLocalizedString("Detail VC:number of shares", comment: "Number of shares")
                cell.detailTextLabel?.text = "\(stock!.numberOfShares)"
                
            case .DatePurchase:
                // NB: should not appear if purchaseDate is nil
                cell.textLabel?.text = NSLocalizedString("Stock Purchase VC:purchase date", comment: "Purchase date")
                if stock!.purchaseDate != nil {
                    cell.detailTextLabel?.text = dateFormatter.stringFromDate(stock!.purchaseDate!)
                } else {
                    cell.detailTextLabel?.text = "?"
                }
                
            case .PricePurchase:
                cell.textLabel?.text = NSLocalizedString("Detail VC:purchase share price", comment: "Purchase share price")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(stock!.purchaseSharePrice)
                
            case .PriceCurrent:
                cell.textLabel?.text = NSLocalizedString("Detail VC:current share price", comment: "Current share price")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(stock!.currentSharePrice)
                
            case .IntradayValue:
                cell.textLabel?.text = NSLocalizedString("Detail VC:intraday change value", comment: "Intraday change value")
                if let formattedIntradayChangeValueString = sharePriceFormatter.stringFromNumber(stock!.intradayEvolutionValue) {
                    if stock!.intradayEvolutionValue > 0 {
                        cell.detailTextLabel?.text = "\(stock!.currency) +\(formattedIntradayChangeValueString)"
                        cell.detailTextLabel?.textColor = UIColor.zenGreenColor()
                    } else {
                        cell.detailTextLabel?.text = "\(stock!.currency) \(formattedIntradayChangeValueString)"
                        cell.detailTextLabel?.textColor = UIColor.zenRedColor()
                    }
                }
                
            case .IntradayPercentage:
                cell.textLabel?.text = NSLocalizedString("Detail VC:intraday change percentage", comment: "Intraday change percentage")
                if let formattedIntradayChangePercentageString = percentageFormatter.stringFromNumber(stock!.intradayEvolutionPercentage) {
                    if stock!.intradayEvolutionPercentage > 0 {
                        cell.detailTextLabel?.text = "+\(formattedIntradayChangePercentageString)"
                        cell.detailTextLabel?.textColor = UIColor.zenGreenColor()
                    } else {
                        cell.detailTextLabel?.text = formattedIntradayChangePercentageString;
                        cell.detailTextLabel?.textColor = UIColor.zenRedColor()
                    }
                }
                
            case .CurrencyRatePurchase:
                cell.textLabel?.text = NSLocalizedString("Detail VC:purchase currency rate", comment: "Purchase currency rate")
                cell.detailTextLabel?.text = currencyRateFormatter.stringFromNumber(stock!.purchaseCurrencyRate)
                
            case .CurrencyRateCurrent:
                cell.textLabel?.text = NSLocalizedString("Detail VC:current currency rate", comment: "Current currency rate")
                cell.detailTextLabel?.text = currencyRateFormatter.stringFromNumber(stock!.currentCurrencyRate)
                
            case .ValuationPurchase:
                
                cell.textLabel?.text = NSLocalizedString("Detail VC:cost of stock", comment: "Cost of stock")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(stock!.costInPortfolioCurrency)
                
            case .ValuationCurrent:
                cell.textLabel?.text = NSLocalizedString("Detail VC:value of stock", comment: "Value of stock")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(stock!.valueInPortfolioCurrency)
                
                
            case .GainOrLossValue:
                cell.textLabel?.text = NSLocalizedString("Detail VC:gain or loss value", comment: "Gain or loss value")
                if let formattedGainOrLossValueString = sharePriceFormatter.stringFromNumber(fabs(stock!.gainOrLossValue)) {
                    if stock!.gainOrLossValue > 0 {
                        cell.detailTextLabel?.text = "\(GlobalSettings.sharedStore.portfolioCurrency)  + \(formattedGainOrLossValueString)"
                        cell.detailTextLabel?.textColor = UIColor.zenGreenColor()
                    } else {
                        cell.detailTextLabel?.text = "\(GlobalSettings.sharedStore.portfolioCurrency)  - \(formattedGainOrLossValueString)"
                        cell.detailTextLabel?.textColor = UIColor.zenRedColor()
                    }
                }
                
            case .GainOrLossPercentage:
                cell.textLabel?.text = NSLocalizedString("Detail VC:gain or loss percentage", comment: "Gain or loss percentage")
                if let formattedGainOrLossPercentageString = percentageFormatter.stringFromNumber(fabs(stock!.gainOrLossPercentage)) {
                    if stock!.gainOrLossPercentage > 0 {
                        cell.detailTextLabel?.text = "+ \(formattedGainOrLossPercentageString)"
                        cell.detailTextLabel?.textColor = UIColor.zenGreenColor()
                    } else {
                        cell.detailTextLabel?.text = "- \(formattedGainOrLossPercentageString)"
                        cell.detailTextLabel?.textColor = UIColor.zenRedColor()
                    }
                }
            }
            
        } else { // no stock selected
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
        }
        return cell
    }
    
    
    
    // MARK: custom methods
    
    @IBAction func segmentAction(sender: UISegmentedControl) {
        
        // The segmented control was clicked, handle it here
        
        // NB: stock can be unwrapped because the SegmentedControl is deactivated if there is no stock selected
        if let currentIndex = find(StockStore.sharedStore.allStocks, stock!) {
            
            if sender.selectedSegmentIndex == 0 { // "up" segment
                stock = StockStore.sharedStore.allStocks[currentIndex - 1]
                
                if currentIndex == 1 { // second entry -> first entry
                    segmentedControl.setEnabled(false, forSegmentAtIndex:0) // won't be able to go one up
                    segmentedControl.setEnabled(true, forSegmentAtIndex:1)  // will be able to go one down
                    // Reload table content
                    tableView.reloadData()
                    // Update the UILabel with the date of last update
                    displayLastTradeDateForItem(stock!)
                } else {
                    segmentedControl.setEnabled(true, forSegmentAtIndex:0) // will be able to go one up
                    segmentedControl.setEnabled(true, forSegmentAtIndex:1) // will be able to go one down
                    // Reload table content
                    tableView.reloadData()
                    // Update the UILabel with the date of last update
                    displayLastTradeDateForItem(stock!)
                }
                
            } else if sender.selectedSegmentIndex == 1 { // "down" segment
                let numberOfArrayEntries = StockStore.sharedStore.allStocks.count
                stock = StockStore.sharedStore.allStocks[currentIndex + 1]
                
                if currentIndex == numberOfArrayEntries - 2 { // last but one entry -> last entry
                    segmentedControl.setEnabled(true, forSegmentAtIndex:0)  // will be able to go one up
                    segmentedControl.setEnabled(false, forSegmentAtIndex:1) // won't be able to go one down
                    // Reload table content
                    tableView.reloadData()
                    // Update the UILabel with the date of last update
                    displayLastTradeDateForItem(stock!)
                } else {
                    segmentedControl.setEnabled(true, forSegmentAtIndex:0) // will be able to go one up
                    segmentedControl.setEnabled(true, forSegmentAtIndex:1) // will be able to go one down
                    // Reload table content
                    tableView.reloadData()
                    // Update the UILabel with the date of last update
                    displayLastTradeDateForItem(stock!)
                }
            }
        }
    }
    
    
    @IBAction func sellStocks(sender: UIBarButtonItem) {
        // Warning : are you sure you want to sell stocks ?
        var sellingWarning = UIAlertController(title: NSLocalizedString("Detail VC:AS sell title", comment: "Do you want to sell stocks ?"), message: nil, preferredStyle: .ActionSheet)
        
        // Button "Sell stocks"
        let sellAction = UIAlertAction(title: NSLocalizedString("Detail VC:AS sell button", comment: "Sell button title"), style: .Default, handler: { action in
            
            // Present STOCK SELL VC
            self.performSegueWithIdentifier("SellStocks", sender:self)
        })
        
        // cancel button
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .Cancel, handler: nil)
        
        sellingWarning.addAction(sellAction)
        sellingWarning.addAction(cancelAction)
        
        // If this AlertController is presented inside a popover, it must provide the location information, either a sourceView and sourceRect or a barButtonItem.
        sellingWarning.popoverPresentationController?.barButtonItem = sender
        sellingWarning.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
        
        self.presentViewController(sellingWarning, animated: true, completion: nil)
    }
    
    
    func displayLastTradeDateForItem(stock: Stock) {
        
        if stock.lastTradeDate != nil {
            // Format the date of last update according to the NSLocale local time zone
            var localFormatter = NSDateFormatter()
            localFormatter.dateStyle = .ShortStyle
            localFormatter.timeStyle = .ShortStyle
            localFormatter.timeZone = NSTimeZone.systemTimeZone()
            let localDateString = localFormatter.stringFromDate(stock.lastTradeDate!)
            
            // Attributed string for the date of last update
            if localDateString.isEmpty {
                lastTradeDateLabel.attributedText = nil
            } else {
                var updateDateAttrString = NSMutableAttributedString(string: localDateString, attributes: [
                    NSFontAttributeName                :    UIFont.boldSystemFontOfSize(12.0),
                    NSForegroundColorAttributeName     :    UIColor.darkGrayColor(),
                    ])
                
                // Attributed string for the text of last update
                let updateText = NSLocalizedString("Detail VC:last quotation Text", comment: "Last quotation: ")
                var updateTextAttrString = NSMutableAttributedString(string: updateText, attributes: [
                    NSFontAttributeName                :    UIFont.systemFontOfSize(12.0),
                    NSForegroundColorAttributeName     :    UIColor.darkGrayColor(),
                    ])
                
                updateTextAttrString.appendAttributedString(updateDateAttrString)
                
                lastTradeDateLabel.attributedText = updateTextAttrString
                lastTradeDateLabel.sizeToFit()
                
            }
        }
    }
    
    
    // MARK: navigation methods
    
    // ** WARNING: "SellStocks" is a segue from VC to VC in the storyboard, triggered by the "Sell stocks" button, not by selecting a row of the tableView
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var destination = segue.destinationViewController as? UIViewController
        if let navController = destination as? UINavigationController {
            destination = navController.visibleViewController
        }
        
        if let identifier = segue.identifier {
            switch identifier {
                
            case "SellStocks":
                if let stockSellVC = destination as? StockSellViewController {
                    stockSellVC.stock = stock!
                    
                    stockSellVC.popToRootClosure = {
                        // This closure will ask the navController of the StockListVC to pop this (StockDetailTVC) view controller
                        (self.splitViewController?.viewControllers.first as? UINavigationController)?.popViewControllerAnimated(true)
                        return
                    }
                }
                
            case "CreateNotification":
                if let createNotificationVC = destination as? CreateNotificationMainViewController {
                    createNotificationVC.stock = stock
                }
                
            default: break
            }
        }
    }
    
    @IBAction func cancelCreateNotification(segue: UIStoryboardSegue) {
        // Unwind Segue
        println("Closing Create Notification Main VC")
    }
    
    
    
    // MARK: notification center methods
    func reloadTableView(notification: NSNotification) {
        updateView()
    }
    
    func removeStock(notification: NSNotification) {
        stock = nil
        updateView()
    }
    
}