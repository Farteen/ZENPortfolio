//
//  CurrencyPickerTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 20/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class CurrencyPickerTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Private properties
    private var checkedIndexPath: NSIndexPath!
    
    
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Currency Picker VC:title",comment: "Currency")
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Set Portfolio Currency")
    }
    

    
    // MARK: Table view datasource methods

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return PortfolioCurrencyStore.sharedStore.allCurrencySymbols.count
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currency  = PortfolioCurrencyStore.sharedStore.allCurrencies[indexPath.row]
        var cell = tableView.dequeueReusableCellWithIdentifier("CurrencyPickerCell", forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = currency.symbol
        cell.detailTextLabel?.text = currency.description
        cell.imageView?.image = UIImage(named: currency.flagImageName)
        
        
        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
        
        // Mark the selected cell
        if cell.textLabel?.text == GlobalSettings.sharedStore.portfolioCurrency {
            cell.accessoryType = .Checkmark
            checkedIndexPath = indexPath
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Currency Picker VC:Reset warning", comment: "Changing the currency will reset the portfolio")
    }
    
    
    // MARK: Table view delegate methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var previouslySelectedCell: UITableViewCell?
        if checkedIndexPath != nil {
            previouslySelectedCell = tableView.cellForRowAtIndexPath(checkedIndexPath)
        }
        var selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        let selectedCurrency = PortfolioCurrencyStore.sharedStore.allCurrencies[indexPath.row]
        
        if selectedCurrency.symbol != GlobalSettings.sharedStore.portfolioCurrency {
            
            // Warning : changing the portfolio currency will reset the portfolio
            var resetWarning = UIAlertController(title: NSLocalizedString("Currency Picker VC:AS title", comment: "Changing currency will reset portfolio"), message: nil, preferredStyle: .ActionSheet)
            
            // destructive button
            let resetAction = UIAlertAction(title: NSLocalizedString("Currency Picker VC:AS destructive", comment: "Destructive button title"), style: .Destructive, handler: { action in
            
                // Remove checkmark from the previously marked cell
                previouslySelectedCell?.accessoryType = .None
                
                // Add checkmark to the selected cell
                selectedCell?.accessoryType = .Checkmark
                self.checkedIndexPath = indexPath
                
                // Animate deselection of cell
                self.tableView.deselectRowAtIndexPath(indexPath, animated:true)
                
                // Stock the portfolio currency as NSUserDefaults
                GlobalSettings.sharedStore.portfolioCurrency = selectedCurrency.symbol // link between portfolioCurrency as a String and currency.symbol as the property of a Currency instance.
                
                // Delete all items from the StockStore
                StockStore.sharedStore.removeAllStocks()
                StockStore.sharedStore.removeAllStockRecordsFromCloud()
                println("StockStore : all entries were deleted")
                
                // Delete all items from the CurrencyRateStore
                CurrencyRateStore.sharedStore.deleteAllRates()
                println("CurrencyStore : all entries were deleted")
                
                // Delete all items from the SalesJournal
                SalesJournal.sharedStore.removeAllEntries()
                SalesJournal.sharedStore.removeAllSaleRecordsFromCloud()
                println("SalesJournal : all Sales journal entries were deleted")

                
                // Reload tableView
                self.tableView.reloadData()
                
                // On Regular sizes, the currency picker is presented inside a popover : reloadData of the List View
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.CurrencyPickerVC_PortfolioCurrencyDidChangeNotification, object:nil)
                
                // Animate deselection of cell
                tableView.deselectRowAtIndexPath(indexPath, animated:true)
                
                // Return to root VC
                self.navigationController?.popToRootViewControllerAnimated(true)
                
                })
            
            
            
            // cancel button
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .Cancel, handler: { action in
                // Animate deselection of cell
                self.tableView.deselectRowAtIndexPath(indexPath, animated:true)
            })

            resetWarning.addAction(resetAction)
            resetWarning.addAction(cancelAction)
            
            // If this AlertController is presented inside a popover, it must provide the location information, either a sourceView and sourceRect or a barButtonItem.
            resetWarning.popoverPresentationController?.sourceView = selectedCell?.contentView
            resetWarning.popoverPresentationController?.sourceRect = selectedCell!.contentView.frame
            
            presentViewController(resetWarning, animated: true, completion: nil)
            
            
        } else {
            // Animate deselection of cell
            tableView.deselectRowAtIndexPath(indexPath, animated:true)
        }
    }
}