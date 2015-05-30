//
//  ButtonCycleTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 28/11/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

class ButtonCycleTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Properties
    var buttonCycleArray: [Dictionary <String, Bool>]
    
    // MARK: View controller life cycle

    required init(coder aDecoder: NSCoder) {
        self.buttonCycleArray = GlobalSettings.sharedStore.buttonCycleArray
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Button Cycle VC:title", comment: "Button cycle")

        // Edit button
        navigationItem.rightBarButtonItem = editButtonItem()
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Define Button Cycle")
    }
    

    
    // MARK: Table view data source methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buttonCycleArray.count
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("ButtonCycleCell", forIndexPath: indexPath) as! UITableViewCell
        let dict = buttonCycleArray[indexPath.row]
        if let key = dict.keys.first as String? {
            
            switch key {
                
            case ButtonCycle.NumberOfShares:
                cell.textLabel?.text = NSLocalizedString("List VC:Quantity text", comment:"Quantity")
                
            case ButtonCycle.IntradayEvolution:
                cell.textLabel?.text = NSLocalizedString("List VC:Intraday evolution text", comment:"Intraday Evolution")
                
            case ButtonCycle.PortfolioValue:
                cell.textLabel?.text = NSLocalizedString("List VC:Stock value text", comment:"Stock value");
                
            case ButtonCycle.GainOrLossValue:
                cell.textLabel?.text = NSLocalizedString("List VC:Gain/loss value text", comment:"Gain/loss value in ");
                
            case ButtonCycle.GainOrLossPercent:
                cell.textLabel?.text = NSLocalizedString("List VC:Gain/loss percentage text", comment:"Gain/loss percentage");
                
            default:
                println("Unknown variable value")
            }
            
            if let bool = dict.values.first as Bool? {
                if  bool == true {
                    cell.accessoryType = .Checkmark
                    cell.textLabel?.textColor = UIColor.blackColor()
                } else {
                    cell.accessoryType = .None
                    cell.textLabel?.textColor = UIColor.lightGrayColor()
                }
            }
        }
        return cell
    }
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Button Cycle VC:explanation", comment: "Select the values you want to use in the main screen and their cycle order")
    }
    
    
    // MARK: Table view delegate methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if var selectedCell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell? {
            
            if selectedCell.accessoryType == .Checkmark {
                
                // Check that there is at least one entry left in the buttonCycleArray
                var variableValueArray = [Dictionary <String, Bool>]()
                for dict in buttonCycleArray {
                    if dict.values.first as Bool? == true {
                        variableValueArray.append(dict)
                    }
                }
                if variableValueArray.count == 1 {
                    // Alert : At least one entry must be selected
                    var alertView = UIAlertController(title: NSLocalizedString("Error", comment: "Error"),
                        message: NSLocalizedString("Button Cycle VC:check last entry", comment: "At least one entry must remain selected"),
                        preferredStyle: .Alert)
                    
                    // cancel button
                    let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertView.addAction(cancelAction)
                    
                    presentViewController(alertView, animated: true, completion: nil)
                    
                } else {
                    if var dict = buttonCycleArray[indexPath.row] as Dictionary<String, Bool>? {
                        if let key = dict.keys.first as String? {
                            (buttonCycleArray[indexPath.row])[key] = false
                        }
                    }
                }
                
            } else if selectedCell.accessoryType == .None {
                if var dict = buttonCycleArray[indexPath.row] as Dictionary<String, Bool>? {
                    if let key = dict.keys.first as String? {
                        (buttonCycleArray[indexPath.row])[key] = true
                    }
                }
            }
            
            // Update NSUserDefaults
            GlobalSettings.sharedStore.buttonCycleArray = buttonCycleArray
            
            // Inform the StockListVC that the buttonCycleArray was changed
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.ButtonCycleVC_ButtonCycleDidChangeNotification, object:nil)

            // Reload tableView
            tableView.reloadData()

        }
    }
    
    // Moving rows
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
        // Update buttonCycleArray
        let entry = buttonCycleArray[sourceIndexPath.row]
        buttonCycleArray.removeAtIndex(sourceIndexPath.row)
        buttonCycleArray.insert(entry, atIndex: destinationIndexPath.row)
        
        // Update NSUserDefaults
        GlobalSettings.sharedStore.buttonCycleArray = buttonCycleArray
        
        // Inform the StockListVC that the buttonCycleArray was changed
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.ButtonCycleVC_ButtonCycleDidChangeNotification, object:nil)

    }
    

    
}