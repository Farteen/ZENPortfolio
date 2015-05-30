//
//  SalesJournalTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 11/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class SalesJournalTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
       // MARK: Private properties
    private var emptyView: EmptyView?

    // Decimal formatter for price or value (2 fraction digits)
    private let decimalFormatter: NSNumberFormatter = {
        var decFormatter = NSNumberFormatter()
        decFormatter.numberStyle = .DecimalStyle
        decFormatter.minimumFractionDigits = 2
        decFormatter.maximumFractionDigits = 2
        decFormatter.locale = NSLocale.currentLocale()
        return decFormatter
        }()

    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Sales Journal VC:title", comment: "Sales Journal")
        
        
        // NAVIGATION BAR ITEMS
        // Deactivate Trash button if list of journal entries is empty
        if SalesJournal.sharedStore.allEntries.isEmpty {
            navigationItem.leftBarButtonItem?.enabled = false
        } else {
            navigationItem.leftBarButtonItem?.enabled = true
        }
        
        // Provide custom BACK BUTTON for Sales Detail VC
        let backButtonTitle = NSLocalizedString("Sales Journal VC:short title", comment: "Journal")
        let customBackButton = UIBarButtonItem(title: backButtonTitle,
            style:.Plain,
            target:self,
            action:"goBack")
        
        navigationItem.backBarButtonItem = customBackButton
        
        // Self-sizing cells
        tableView.estimatedRowHeight = tableView.rowHeight // retrieve value from storyboard
        tableView.rowHeight = UITableViewAutomaticDimension
        
    }
    
    
    // Method for custom Back button
    func goBack() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Table View SEPARATOR INSET
        tableView.separatorInset = UIEdgeInsetsZero
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Sales Journal")
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // EMPTY VIEW
        updateEmptyView()
        
        // Table View SEPARATOR INSET
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
    }
    
    
    /** Display empty view with a message "No entry in the Sales Journal" */
    func updateEmptyView() {
        
        // Remove any existing emptyView (to account for change of dimensions / rotation)
        emptyView?.removeFromSuperview()
        emptyView = nil
        
        if SalesJournal.sharedStore.allEntries.isEmpty {
            // Create an empty view
            emptyView = EmptyView(frame: tableView.bounds, message: NSLocalizedString("Sales Journal VC:Header no entry", comment: "No entry in the Sales journal"))
            
            tableView.addSubview(emptyView!)
            
        }
    }

    
    
    deinit {
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    
    // MARK: Table view data source methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SalesJournal.sharedStore.allEntries.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let sale = SalesJournal.sharedStore.allEntries[indexPath.row]
        var cell = tableView.dequeueReusableCellWithIdentifier("SalesJournalCell", forIndexPath: indexPath) as! SalesJournalTableViewCell
        
        cell.sale = sale
        
        // Cell style and highlight when selected
        cell.selectionStyle = .Gray
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // If the table view is asking to commit a delete command
        if editingStyle == .Delete {
            let sale = SalesJournal.sharedStore.allEntries[indexPath.row]
            
            // update the model
            SalesJournal.sharedStore.removeEntry(sale)
            // Remove the entry from iCloud
            SalesJournal.sharedStore.removeRecordFromCloud(sale)
            
            // remove that row from the table view with an animation
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
            
            // recalculate the header subtotal
            tableView.reloadData()
            
            // Update Emptyview
            updateEmptyView()
        }
        
        // If list of sales entries is empty, disable trash button
        navigationItem.leftBarButtonItem?.enabled = !SalesJournal.sharedStore.allEntries.isEmpty
    }
    
    
    
    // MARK: Table view delegate methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    // After selection, deselect the line
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48.0
    }
    
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var balanceGainOrLoss = 0.0
        
        for sale in SalesJournal.sharedStore.allEntries {
            // "round" (truncate) every item gainOrLossValue to 2 decimals after the point
            balanceGainOrLoss += round(sale.gainOrLossValue * 100.0) / 100.0
        }
        
        
        let headerGainOrLossLocalizedText = NSLocalizedString("Sales Journal VC:Total Gain/Loss", comment: "Total Gain/loss :")
        var valueInPortfolioCurrencyFormattedString = decimalFormatter.stringFromNumber(fabs(balanceGainOrLoss))!
        if balanceGainOrLoss > 0 {
            valueInPortfolioCurrencyFormattedString = "+ " + valueInPortfolioCurrencyFormattedString
        } else {
            valueInPortfolioCurrencyFormattedString = "- " + valueInPortfolioCurrencyFormattedString
        }
        
        
        // Attributed string for localized text
        var headerAttString = NSMutableAttributedString(string: headerGainOrLossLocalizedText, attributes: [
            NSForegroundColorAttributeName  :   UIColor.darkGrayColor(),
            NSFontAttributeName             :   UIFont.systemFontOfSize(18.0),
            ])
        
        // Attributed string for Total gain / loss value
        let totalValueString = "\(GlobalSettings.sharedStore.portfolioCurrency)  \(valueInPortfolioCurrencyFormattedString)"
        var headerValueAttString = NSMutableAttributedString(string: totalValueString, attributes: [
            NSTextEffectAttributeName       :   NSTextEffectLetterpressStyle,
            NSFontAttributeName             :   UIFont.boldSystemFontOfSize(18.0),
            ])
        
        if balanceGainOrLoss > 0 {
            headerValueAttString.addAttribute(NSForegroundColorAttributeName, value: UIColor.zenGreenColor(), range:NSMakeRange(0, count(totalValueString)))
        } else if balanceGainOrLoss < 0 {
            headerValueAttString.addAttribute(NSForegroundColorAttributeName, value: UIColor.zenRedColor(), range:NSMakeRange(0, count(totalValueString)))
        }
        
        headerAttString.appendAttributedString(headerValueAttString)
        var headerLabel = UILabel()
        headerLabel.attributedText = headerAttString
        headerLabel.textAlignment = .Center
        headerLabel.backgroundColor = UIColor.clearColor()
        
        return headerLabel
    }
    
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Table View SEPARATOR INSET
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
    }
    
    
    
    // MARK: custom methods
    @IBAction func eraseAllEntries(sender: UIBarButtonItem) {
        // Warning : erase sales journal
        var eraseWarning = UIAlertController(title: NSLocalizedString("Sales Journal VC:AS title", comment: "Do you really want to erase the Sales journal ?"), message: nil, preferredStyle: .ActionSheet)
        
        // Button "Erase"
        let eraseAction = UIAlertAction(title: NSLocalizedString("Sales Journal VC:AS destructive", comment: "Destructive button title"), style: .Destructive, handler: { action in
            
            // Delete all items from the SalesJournal
            SalesJournal.sharedStore.removeAllEntries()
            println("SalesJournal : all Sales journal entries were deleted")
            // Remove entries from iCloud
            SalesJournal.sharedStore.removeAllSaleRecordsFromCloud()
            
            
            // Refresh tableView
            self.tableView.reloadData()
            
            // Disable trash button
            self.navigationItem.leftBarButtonItem?.enabled = false
            
            // Show empty View
            self.updateEmptyView()
        })
        
        // cancel button
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .Cancel, handler: nil)
        
        eraseWarning.addAction(eraseAction)
        eraseWarning.addAction(cancelAction)
        
        // If this AlertController is presented inside a popover, it must provide the location information, either a sourceView and sourceRect or a barButtonItem.
        eraseWarning.popoverPresentationController?.barButtonItem = sender
        eraseWarning.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
        
        self.presentViewController(eraseWarning, animated: true, completion: nil)
    }
    
    
    
    // MARK: navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if let identifier = segue.identifier {
            switch identifier {
                
            case "ShowSalesJournalDetail":
                if let salesJournalDetailTVC = segue.destinationViewController as? SalesJournalDetailTableViewController {
                    if let indexPath = tableView.indexPathForSelectedRow() {
                        salesJournalDetailTVC.sale = SalesJournal.sharedStore.allEntries[indexPath.row]
                    }
                }
                
            default: break
            }
        }
    }

  
}