//
//  StockNotificationTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 20/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


class StockNotificationTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Private properties
    private var headerLabel = UILabel()
    
    // Empty View : used to display a message if list of stocks is empty
    private var emptyView: EmptyView!

    // Decimal formatter for Share price (2 fraction digits)
    private let sharePriceFormatter: NSNumberFormatter = {
        var decimalFormatter = NSNumberFormatter()
            decimalFormatter.numberStyle = .DecimalStyle
            decimalFormatter.minimumFractionDigits = 2
            decimalFormatter.maximumFractionDigits = 2
            decimalFormatter.locale = NSLocale.currentLocale()
        return decimalFormatter
    }()
    
    private var sectionSet = NSMutableOrderedSet()
    
    
    
    // MARK: View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Prefs VC:Notifications", comment: "Notifications")
        
        
        // NAVIGATION BAR ITEMS
        // Deactivate Trash button if list of notifications is empty
        if StockNotificationStore.sharedStore.allNotifications.isEmpty {
            navigationItem.rightBarButtonItem?.enabled = false
        } else {
            navigationItem.rightBarButtonItem?.enabled = true
        }
        
        // Section set (to guarantee unique entries)
        var sectionArray = [String]()
        for notification in StockNotificationStore.sharedStore.allNotifications {
            if notification.stock != nil {
                sectionArray.append(notification.stock!.name)
            }
        }
        sectionSet = NSMutableOrderedSet(array: sectionArray)
        
        // Self-sizing cells
        tableView.estimatedRowHeight = tableView.rowHeight // retrieve value from storyboard
        tableView.rowHeight = UITableViewAutomaticDimension
        
        
        // NOTIFICATION CENTER
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"reloadTableView:", name:NotificationCenterKeys.StockListVC_DidFireLocalNotificationNotification, object:nil)

    }

    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // EMPTY VIEW
        updateEmptyView()
    }
    
    
    /** Display empty view with a message "No entry in the Notification list" */
    func updateEmptyView() {
        
        // Remove any existing emptyView (to account for change of dimensions / rotation)
        emptyView?.removeFromSuperview()
        emptyView = nil
        
        if StockNotificationStore.sharedStore.allNotifications.isEmpty {
            // Create an empty view
            emptyView = EmptyView(frame: tableView.bounds, message: NSLocalizedString("Stock Notif List VC:Header no entry", comment: "No entry in the Notification list"))
            
            tableView.addSubview(emptyView!)
        }
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("List of Notifications")
    }
    

    
    deinit {
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: Table view datasource methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionSet.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stockName: String = sectionSet[section].description
        return StockNotificationStore.sharedStore.notificationsFilteredByStockName(stockName).count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
         var cell = tableView.dequeueReusableCellWithIdentifier("StockNotificationCell", forIndexPath: indexPath) as! StockNotificationTableViewCell
        
        let stockName: String = sectionSet[indexPath.section].description
        let notification = (StockNotificationStore.sharedStore.notificationsFilteredByStockName(stockName))[indexPath.row]
        
        // * Fixed string components
        let stringComponent1 = NSAttributedString(string: NSLocalizedString("Stock Notif List VC:Notify me", comment: "Notify me when the "))
        let stringComponent2 = NSAttributedString(string: NSLocalizedString("Stock Notif List VC:of", comment: "of "))
        let stringComponent3 = NSAttributedString(string: NSLocalizedString("Stock Notif List VC:my", comment: "my "))
        let stringComponent4 = notification.compareAscending ? NSAttributedString(string: NSLocalizedString("Stock Notif List VC:goes over", comment: "goes over ")) : NSAttributedString(string: NSLocalizedString("Stock Notif List VC:goes under", comment: "goes under "))
        
        // * Variable string components
        let boldAttributes = [ NSFontAttributeName : UIFont.boldSystemFontOfSize(16.0) ]
        
        // Notification type (bold)
        let attNotificationType = NSAttributedString(string: notification.typeDescription, attributes:boldAttributes)
        
        // Number of shares
        let sharesLocalizedString = NSLocalizedString("Sales Journal VC:shares", comment: "shares")
        let attNumberOfShares = NSAttributedString(string: "\(notification.stock!.numberOfShares) \(sharesLocalizedString)")
        
        // Stock name (bold), limited to 40 characters
        let attStockName = NSAttributedString(string:stockName[0..<40], attributes:boldAttributes)
        
        // Target value and unit (bold)
        var targetValue = String()
        if notification.type == StockNotificationType.GainOrLossPercentage {
            targetValue = sharePriceFormatter.stringFromNumber(notification.target * 100)!
        } else {
            targetValue = sharePriceFormatter.stringFromNumber(notification.target)!
        }
        let attTarget = NSAttributedString(string: "\(targetValue) \(notification.targetUnit)", attributes:boldAttributes)

        
        // * Concatenate the attributed strings
        var attNotificationText = NSMutableAttributedString(string: stringComponent1.string)                               // Notify me when the
        attNotificationText.appendAttributedString(attNotificationType)                                                    // GAIN OR LOSS (VALUE)
        attNotificationText.appendAttributedString(stringComponent2)                                                       // of
        if notification.type != StockNotificationType.Price { // other than share price
            if notification.type == StockNotificationType.GainOrLossValue
                || notification.type == StockNotificationType.GainOrLossPercentage { // gain or loss value or %
                attNotificationText.appendAttributedString(stringComponent3)                                               // my
            }
            attNotificationText.appendAttributedString(attNumberOfShares)                                                  // 10 shares
            attNotificationText.appendAttributedString(stringComponent2)                                                   // of
        }
        attNotificationText.appendAttributedString(attStockName)                                                           // Apple Inc.
        attNotificationText.appendAttributedString(stringComponent4)                                                       // goes over
        attNotificationText.appendAttributedString(attTarget)                                                              // 900 EUR
        
        cell.notificationDetailLabel!.attributedText = attNotificationText
        
        
        // Cell style
        cell.notificationDetailLabel!.textColor = UIColor.darkGrayColor()
        cell.colorView!.backgroundColor = notification.color
        
        // Make sure the constraints have been added to this cell, since it may have just been created from scratch
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        
        return cell
    }

    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionSet[section].description
    }
    
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == numberOfSectionsInTableView(tableView) - 1 {
            return NSLocalizedString("Stock Notif List VC:Header explain", comment: "How local notifications work")
        }
        return nil

    }
 
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // If the table view is asking to commit a delete command ...
        if editingStyle == .Delete {
            if let stockName = sectionSet[indexPath.section].description {
                let notification = StockNotificationStore.sharedStore.notificationsFilteredByStockName(stockName)[indexPath.row]
                
                // Remove the notification from the Stock notification store
                StockNotificationStore.sharedStore.removeNotification(notification)
                StockNotificationStore.sharedStore.removeRecordFromCloud(notification)
                
                
                // Also remove that row from the table view with an animation
                tableView.beginUpdates()
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                tableView.endUpdates()
                
                
                if tableView.numberOfRowsInSection(indexPath.section) == 0 { // section is now empty
                    
                    // Remove the section title from the section set
                    // This is required to re-calculate correctly numberOfSectionsInTableView:
                    if notification.stock != nil {
                        sectionSet.removeObject(notification.stock!.name)
                    }
                    
                    // Remove section
                    tableView.beginUpdates()
                    let sectionIndexSet = NSIndexSet(index:indexPath.section)
                    tableView.deleteSections(sectionIndexSet, withRowAnimation: .Fade)
                    tableView.endUpdates()
                }
            }
        }
        
        // If list of notifications is empty ...
        if StockNotificationStore.sharedStore.allNotifications.isEmpty {
            
            // ... show an indication "no entries" in the table header view
            updateEmptyView()
            
            // Disable trash button
            navigationItem.rightBarButtonItem?.enabled = false
        }
    }
    
    
    // MARK: Custom methods
    
    @IBAction func eraseAllEntries(sender: UIBarButtonItem) {
        // Warning : erase all notifications
        var eraseWarning = UIAlertController(title: NSLocalizedString("Stock Notif List VC:AS title", comment: "Do you really want to erase all notifications ?"), message: nil, preferredStyle: .ActionSheet)
        
        // Button "Erase"
        let eraseAction = UIAlertAction(title: NSLocalizedString("Stock Notif List VC:AS destructive", comment: "Destructive button title"), style: .Destructive, handler: { action in
            
            // Delete all items from the StockNotificationStore
            StockNotificationStore.sharedStore.removeAllNotifications()
            println("StockNotifications : all notifications were deleted")
            // Remove notifications from iCloud
            StockNotificationStore.sharedStore.removeAllNotificationRecordsFromCloud()
            
            // Remove all section titles from the section set
            // This is required to re-calculate correctly numberOfSectionsInTableView:
            self.sectionSet.removeAllObjects()
            
            // Refresh tableView
            self.tableView.reloadData()
            
            // Disable trash button
            self.navigationItem.rightBarButtonItem?.enabled = false
            
            // update EmptyView
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
    
    
    // MARK: Notification center (observer) method
    
    func reloadTableView(notification: NSNotification) {
        // Useful to reload data of the tableView after portfolio currency has been changed
        tableView.reloadData()
        
        // Deactivate Trash button if list of notifications is empty
        navigationItem.rightBarButtonItem?.enabled = !StockNotificationStore.sharedStore.allNotifications.isEmpty

        // Update emptyView
        updateEmptyView()

    }

}