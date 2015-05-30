//
//  AlertTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 20/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

// Global function to round up a number to the closest multiple
func roundUp(numToRound: Int, multiple: Int) -> Int
{
    if multiple == 0 {
        return numToRound
    }
    
    var remainder = numToRound % multiple
    if remainder == 0 {
        return numToRound
    } else {
        return numToRound + multiple - remainder
    }
}


class AlertTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // Private properties

     // Global constants
    let EMPTYVIEW_SIDE_MARGIN: CGFloat = 20.0
    let EMPTYVIEW_HEIGHT:CGFloat = 50.0
    
    var headerLabel = UILabel()
    
    // Empty View : used to display a message if list of stocks is empty
    @lazy var emptyView: UIView = {
        var view = UIView(frame: self.tableView.bounds)
        view.backgroundColor = UIColor.whiteColor()
        self.tableView.addSubview(view)
        view.addSubview(self.messageLabel)
        return view
        }()
    
    @lazy var messageLabel: UILabel = {
        var label = UILabel.init(frame:CGRectZero)
        label.text = NSLocalizedString("Notifications List VC:Header no entry", comment: "No entry in the Notification list")
        label.numberOfLines = 2
        label.textAlignment = .Center;
        label.textColor = UIColor.zenGrayColor()
        label.font = UIFont.systemFontOfSize(20.0)
        return label
        }()
    
    
    // Decimal formatter for Share price (2 fraction digits)
    var sharePriceFormatter: NSNumberFormatter = {
        var decimalFormatter = NSNumberFormatter()
            decimalFormatter.numberStyle = .DecimalStyle
            decimalFormatter.minimumFractionDigits = 2
            decimalFormatter.maximumFractionDigits = 2
            decimalFormatter.locale = NSLocale.currentLocale()
        return decimalFormatter
    }()
    
    var sectionSet = NSMutableOrderedSet()
    
    
    
    // MARK: View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Prefs VC:Notifications", comment: "Notifications")
        
        
        // NAVIGATION BAR ITEMS
        // Deactivate Trash button if list of alerts is empty
        if StockAlertStore.sharedStore().allAlerts.isEmpty {
            navigationItem.rightBarButtonItem.enabled = false
        } else {
            navigationItem.rightBarButtonItem.enabled = true
        }
        
        // Section set
        var sectionArray = [String]()
        for alert in StockAlertStore.sharedStore().allAlerts {
            sectionArray += alert.stock.name;
        }
        sectionSet = NSMutableOrderedSet(array: sectionArray)
        
    }

    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        emptyView.hidden = StockAlertStore.sharedStore().allAlerts.isEmpty
            
            // Calculate message position
        messageLabel.frame = CGRectMake(emptyView.bounds.origin.x + EMPTYVIEW_SIDE_MARGIN,
                                        emptyView.bounds.size.height / 2 - EMPTYVIEW_HEIGHT / 2,
                                        emptyView.bounds.size.width - 2 * EMPTYVIEW_SIDE_MARGIN,
                                        EMPTYVIEW_HEIGHT)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO: check if this is still necessary
        // NOTIFICATION CENTER
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadMyTableView:", name:"ListVC_DidFireLocalNotificationNotifications", object:nil)

    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: Table view datasource methods
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return sectionSet.count
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        let stockName: String = sectionSet[section].description
        return StockAlertStore.sharedStore().alertsFilteredByStockName(stockName).count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
         var cell = tableView.dequeueReusableCellWithIdentifier("AlertCell") as AlertTableViewCell
        
        contentForCell(cell, atIndexPath:indexPath)
        
        return cell;
    }
    
    // Helper method
    func contentForCell(cell: AlertTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let stockName: String = sectionSet[indexPath.section].description
        let alert = StockAlertStore.sharedStore().alertsFilteredByStockName(stockName)[indexPath.row]
        
        // * Fixed string components
        let stringComponent1 = NSAttributedString(string: NSLocalizedString("Notifications List VC:Notify me", comment: "Notify me when the "))
        let stringComponent2 = NSAttributedString(string: NSLocalizedString("Notifications List VC:of", comment: "of "))
        let stringComponent3 = NSAttributedString(string: NSLocalizedString("Notifications List VC:my", comment: "my "))
        let stringComponent4 = alert.compareAscending ? NSAttributedString(string: NSLocalizedString("Notifications List VC:goes over", comment: "goes over ")) : NSAttributedString(string: NSLocalizedString("Notifications List VC:goes under", comment: "goes under "))
        
        // * Variable string components
        let boldAttributes = [ NSFontAttributeName : UIFont.boldSystemFontOfSize(16.0) ]
        
        // Alert type (bold)
        let attAlertType = NSAttributedString(string: alert.typeDescription, attributes:boldAttributes)
        
        // Number of shares
        let sharesLocalizedString = NSLocalizedString("Sales Journal VC:shares", comment: "shares")
        let attNumberOfShares = NSAttributedString(string: "\(alert.stock.numberOfShares) \(sharesLocalizedString)")
        
        // Stock name (bold), limited to 40 characters
        let attStockName = NSAttributedString(string:stockName[0..<40], attributes:boldAttributes)
        
        // Target value and unit (bold)
        var targetValue = String()
        if alert.type == StockAlertType.GainOrLossPercentage {
            targetValue = sharePriceFormatter.stringFromNumber(alert.target * 100)
        } else {
            targetValue = sharePriceFormatter.stringFromNumber(alert.target)
        }
        let attTarget = NSAttributedString(string: "\(targetValue) \(alert.targetUnit)", attributes:boldAttributes)

        
        // * Concatenate the attributed strings
        var attAlertText = NSMutableAttributedString(string: stringComponent1.string)                               // Notify me when the
        attAlertText.appendAttributedString(attAlertType)                                                           // GAIN OR LOSS (VALUE)
        attAlertText.appendAttributedString(stringComponent2)                                                       // of
        if alert.type != StockAlertType.Price { // other than share price
            if alert.type == StockAlertType.GainOrLossValue
                || alert.type == StockAlertType.GainOrLossPercentage { // gain or loss value or %
                attAlertText.appendAttributedString(stringComponent3)                                               // my
            }
            attAlertText.appendAttributedString(attNumberOfShares)                                                  // 10 shares
            attAlertText.appendAttributedString(stringComponent2)                                                   // of
        }
        attAlertText.appendAttributedString(attStockName)                                                           // Apple Inc.
        attAlertText.appendAttributedString(stringComponent4)                                                       // goes over
        attAlertText.appendAttributedString(attTarget)                                                              // 900 EUR
        
        cell.alertDetailLabel.attributedText = attAlertText
        
        
        // Cell style
        cell.alertDetailLabel.textColor = UIColor.darkGrayColor()
        cell.colorView.backgroundColor = alert.color
    }

    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        return sectionSet[section].description
    }
    
    
    override func tableView(tableView: UITableView!, titleForFooterInSection section: Int) -> String! {
        if section == numberOfSectionsInTableView(tableView) - 1 {
            return NSLocalizedString("Notifications List VC:Header explain", comment: "How local notifications work")
        }
        return nil;

    }
 
    
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        // If the table view is asking to commit a delete command ...
        if editingStyle == .Delete {
            if let stockName = sectionSet[indexPath.section].description {
                let alert = StockAlertStore.sharedStore().alertsFilteredByStockName(stockName)[indexPath.row]
                
                // Remove the alert from the alert store
                StockAlertStore.sharedStore().removeAlert(alert)
                
                
                // Also remove that row from the table view with an animation
                tableView.beginUpdates()
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                tableView.endUpdates()
                
                
                if tableView.numberOfRowsInSection(indexPath.section) == 0 { // section is now empty
                    
                    // Remove the section title from the section set
                    // This is required to re-calculate correctly numberOfSectionsInTableView:
                    sectionSet.removeObject(alert.stock.name)
                    
                    // Remove section
                    tableView.beginUpdates()
                    let sectionIndexSet = NSIndexSet(index:indexPath.section)
                    tableView.deleteSections(sectionIndexSet, withRowAnimation: .Fade)
                    tableView.endUpdates()
                }
            }
        }
        
        // If list of alerts is empty ...
        if StockAlertStore.sharedStore().allAlerts.isEmpty {
            
            // ... show an indication "no entries" in the table header view
            headerLabel.text = NSLocalizedString("Notifications List VC:Header no entry", comment: "No entry in the Notification list")
            headerLabel.font = UIFont.italicSystemFontOfSize(18.0)
            
            // Disable trash button
            navigationItem.rightBarButtonItem.enabled = false
        }
    }
    
    
    
    // MARK: Table view delegate methods
    
    override func tableView(tableView: UITableView!, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 70.0
    }
    
    
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        // Dynamic row height calculation !
        
        var sizingCell = AlertTableViewCell()
        var onceToken: dispatch_once_t = 0
        dispatch_once(&onceToken, {
            sizingCell = tableView.dequeueReusableCellWithIdentifier("AlertCell") as AlertTableViewCell
        })
        
        // Get the cell content
        contentForCell(sizingCell, atIndexPath:indexPath)
        
        // Force layout if needed
        sizingCell.layoutIfNeeded()
        
        // Get the fitting size
        let fittingSize = sizingCell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        
        // Add a 5-pt margin to the fitting height and round up to the closest multiple of 10
        let roundedUpHeight = CGFloat(roundUp(Int(fittingSize.height + 5), 10))
        
        return roundedUpHeight
    }
    
    // MARK: Custom methods
    
    @IBAction func eraseAllEntries() {
        // Warning : erase all alerts
        var eraseWarning = ZENActionSheet(title:NSLocalizedString("Notifications List VC:AS title", comment: "Do you really want to erase all notifications ?"))
        
        // destructive button
        eraseWarning.addDestructiveButtonWithTitle(NSLocalizedString("Notifications List VC:AS destructive", comment: "Destructive button title"), block: { [unowned self] in
            
            // Delete all items from the StockAlertStore
            StockAlertStore.sharedStore().removeAllAlerts()
            println("StockAlerts : all alerts were deleted")
            
            // Remove all section titles from the section set
            // This is required to re-calculate correctly numberOfSectionsInTableView:
            self.sectionSet.removeAllObjects()
            
            // Refresh tableView
            self.tableView.reloadData()
            
            // Disable trash button
            self.navigationItem.rightBarButtonItem.enabled = false
            })
        
        // cancel button is last
        eraseWarning.addCancelButtonWithTitle(NSLocalizedString("Detail VC:AS cancel button", comment: "Cancel button title"), block:nil)
        
        eraseWarning.actionSheetStyle = .Automatic
        
        eraseWarning.showInView(view)
    }
    
    
    // MARK: Notification center (observer) method
    
    func reloadMyTableView(notification: NSNotification) {
        // Useful to reload data of the tableView after portfolio currency has been changed
        tableView.reloadData()
        
        // Deactivate Trash button if list of alerts is empty
        if StockAlertStore.sharedStore().allAlerts.isEmpty {
            navigationItem.rightBarButtonItem.enabled = false
            emptyView.hidden = false
        } else {
            navigationItem.rightBarButtonItem.enabled = true
            emptyView.hidden = true
        }
    }

    
}