//
//  ThemeSelectorTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 22/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class ThemeSelectorTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Private properties
    private var checkedIndexPath: NSIndexPath!
    private var currentTheme: Theme {
        return GlobalSettings.sharedStore.currentTheme
    }
    
    
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Theme Selector VC:title", comment: "Theme selection")
        
        // Inset tableView to stick it to the top of the view
        tableView.contentInset = UIEdgeInsetsMake(-35, 0, -30, 0)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Table View SEPARATOR INSET
        tableView.separatorInset = currentTheme.themeSeparatorInset()
        tableView.layoutMargins = currentTheme.themeSeparatorInset()

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Theme Selector")
    }
    

    
    // MARK: Table view data source methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfThemes = Theme.lastTheme.rawValue + 1
        return numberOfThemes
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("ThemeSelectorCell", forIndexPath: indexPath) as! UITableViewCell
        
        if let theme = Theme(rawValue: indexPath.row) {
            
            // Cell text
            cell.textLabel?.text = theme.description
            
            // Accessory view
            cell.tintColor = UIColor.blackColor()
            
            cell.selectionStyle = .Gray
            
            // Mark the selected cell
            if theme == currentTheme {
                cell.accessoryType = .Checkmark
                checkedIndexPath = indexPath
            } else {
                cell.accessoryType = .None
            }
        }
        return cell
    }
    
    
    // MARK: Table view delegate methods
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var previouslySelectedCell = tableView.cellForRowAtIndexPath(checkedIndexPath)
        var selectedCell = tableView.cellForRowAtIndexPath(indexPath)
        
        if let selectedTheme = Theme(rawValue: indexPath.row) {
            
            if selectedTheme != currentTheme {
                
                // Remove checkmark from the previously marked cell
                previouslySelectedCell?.accessoryType = .None
                
                // Add checkmark to the selected cell
                selectedCell?.accessoryType = .Checkmark
                self.checkedIndexPath = indexPath
                
                // Animate deselection of cell
                tableView.deselectRowAtIndexPath(indexPath, animated:true)
                
                // Stock the current theme as NSUserDefaults
                GlobalSettings.sharedStore.currentThemeNumber = indexPath.row
                
                // ** RELOAD UI ELEMENTS **
                
                // Icons color
                var appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                if let appDelegateWindow = appdelegate.window {
                    appDelegateWindow.tintColor = selectedTheme.color
                }
                
                // Reload tableView
                // Will also update the separator inset
                tableView.reloadData()
                
                // On iPad, the currency picker is presented inside a popover : reloadData of the List View
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationCenterKeys.ThemeSelectorVC_CurrentThemeDidChangeNotification, object:nil)
                
            } else {
                // Animate deselection of cell
                tableView.deselectRowAtIndexPath(indexPath, animated:true)
            }
        }
    }
    
    
    // Cell gradient color
    func colorForIndex(index: Int) -> UIColor {
        
        let itemCount: Int = tableView.numberOfRowsInSection(0) - 1
        let value = CGFloat(index) / CGFloat(itemCount) * 0.6;
        
        return currentTheme.gradientColorForBaseValue(value)
    }
    
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = colorForIndex(indexPath.row)
        
        // Table View SEPARATOR INSET
        cell.separatorInset = currentTheme.themeSeparatorInset()
        cell.layoutMargins = currentTheme.themeSeparatorInset()
    }
    
    
}