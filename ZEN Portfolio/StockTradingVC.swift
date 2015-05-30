//
//  StockTradingVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 08/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


import UIKit

// Caution : superclass of StockPurchaseViewController / StockSellViewController : all properties and functions used in subclasses must be public !
class StockTradingViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Public properties (must be exposed for subclasses!)
    var stock: Stock! {
        didSet {
            var currency = stock.currency
            // Special case for GBX (0,01 GBP)
            if currency == "GBX" { currency = "GBP" }
            
            if currency == GlobalSettings.sharedStore.portfolioCurrency {
                sections = [
                    Section(type: .TradingInfoEntry, items: [.NumberOfShares, .Price, .Date]),
                    Section(type: .CurrentInfoDisplay, items: [.DisplayPrice])
                ]
                
            } else { // currency != GlobalSettings.sharedStore.portfolioCurrency
                sections = [
                    Section(type: .TradingInfoEntry, items: [.NumberOfShares, .Price, .ExchangeRate, .Date]),
                    Section(type: .CurrentInfoDisplay, items: [.DisplayPrice, .DisplayExchangeRate])
                ]
            }
        }
    }
    
    var tradingNumberOfShares = 0
    var tradingSharePrice = 0.0
    var tradingCurrencyRate = 0.0
    var tradingDate = NSDate()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var marketLabel: UILabel!
    
    
    // Constants for the cell identifiers (must not be private because used in sub-classes)
    struct Storyboard {
        static let TextFieldCellReuseIdentifier = "TextFieldCell"
        static let DateCellReuseIdentifier = "DateCell"
        static let DatePickerReuseIdentifier = "DatePickerCell"
        static let DisplayInfoCellReuseIdentifier = "DisplayInfoCell"
        static let DatePickerTag = 99 // set on the "tag" property of the DatePicker view
    }
    
    
    var sections = [Section]() // Must not be private because used in sub-classes

    // MARK: tableView struct and enum (must not be private because used in sub-classes)
    struct Section {
        var type: SectionType
        var items: [Item]
    }
    
    enum SectionType {
        case TradingInfoEntry
        case CurrentInfoDisplay
    }
    
    enum Item {
        case NumberOfShares
        case Price
        case ExchangeRate
        case Date
        case DatePicker
        case DisplayPrice
        case DisplayExchangeRate
    }

    // Properties for text field management
    
    /** Currently edited textField */
    weak var selectedTextField: UITextField? // weak because the textField is already owned by the cell / tableView

    var cancelButtonPressed = false
    var textFieldInError = false
    
    // Properties for date picker
    var datePickerIndexPath: NSIndexPath? // keep track which indexPath points to the cell with UIDatePicker
    var pickerCellRowHeight: CGFloat = 0.0
    
    
    
    // Formatter for number of shares (no digit)
    // Should not be set as private, since they are used by subclasses
    let numberOfSharesFormatter: NSNumberFormatter = {
        var intFormatter = NSNumberFormatter()
        intFormatter.numberStyle = .DecimalStyle
        intFormatter.maximumFractionDigits = 0
        intFormatter.locale = NSLocale.currentLocale()
        return intFormatter
        }()
    
    // Decimal formatter for Share price (2 fraction digits)
    let sharePriceFormatter: NSNumberFormatter = {
        var decimalFormatter = NSNumberFormatter()
        decimalFormatter.numberStyle = .DecimalStyle
        decimalFormatter.minimumFractionDigits = 2
        decimalFormatter.maximumFractionDigits = 2
        decimalFormatter.locale = NSLocale.currentLocale()
        return decimalFormatter
        }()
    
    // Decimal formatter for Currency rate (4 to 6 fraction digits) *
    let currencyRateFormatter: NSNumberFormatter = {
        var rateFormatter = NSNumberFormatter()
        rateFormatter.numberStyle = .DecimalStyle
        rateFormatter.minimumFractionDigits = 4
        rateFormatter.maximumFractionDigits = 4
        rateFormatter.locale = NSLocale.currentLocale()
        return rateFormatter
        }()
    
    // Date formatter
    let dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter
        }()
    
    
    // MARK: Private properties
    private var initialTableViewOffset: CGPoint?
    private let StandardButtonHeight: CGFloat = 44
    
    
    // MARK: View controller life cycle
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    override func viewDidLoad() {
        
        // Title
        navigationItem.title = stock.symbol
        
        // Update field texts and labels
        nameLabel.text = stock.name
        symbolLabel.text = stock.symbol
        marketLabel.text = stock.market
        
        // Self-sizing cells
        tableView.estimatedRowHeight = tableView.rowHeight // retrieve value from storyboard
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // NOTIFICATION CENTER
        // If the local changes while in the background, we need to be notified so we can update the date format in the table view cells
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "localeChanged:", name: NSCurrentLocaleDidChangeNotification, object: nil)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Save the current tableView offset
        initialTableViewOffset = tableView.contentOffset
    }
    
    
    deinit {
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
    // MARK: Table view data source methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    
    // POLYMORPHISM: overriden in subclass!
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return UITableViewCell() // should never be used
    }
    
    
    // MARK: Helper methods for Date picker
    
    /** Determines if the cell for the given indexPath has a cell below it with a UIDatePicker. */
    func hasPickerForIndexPath(indexPath: NSIndexPath) -> Bool {
        
        if let datePickerCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection:indexPath.section)) as UITableViewCell? {
            if let datePicker = datePickerCell.viewWithTag(Storyboard.DatePickerTag) as? UIDatePicker {
                return true
            }
        }
        return false
    }
    
    
    /** Adds or removes a UIDatePicker cell below the given indexPath.
    The indexPath to reveal the UIDatePicker. */
    func toggleDatePickerForSelectedIndexPath(indexPath: NSIndexPath) {
        
        let dateCell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell?
        
        tableView.beginUpdates()
        
        let targetIndexPath = NSIndexPath(forRow: (indexPath.row + 1), inSection:indexPath.section)
        
        // check if 'indexPath' has an attached date picker below it
        if hasPickerForIndexPath(indexPath) {
            // found a picker below it, so remove it
            if var firstSection = sections.first {
                firstSection.items.removeLast()
                sections.removeAtIndex(0)
                sections.insert(firstSection, atIndex: 0)
            }
            tableView.deleteRowsAtIndexPaths([targetIndexPath], withRowAnimation: .Fade)
            
            // Set the datePickerIndexPath to nil
            datePickerIndexPath = nil
            
            // Set the tableView offset back to the initial state
            if initialTableViewOffset != nil {
                tableView.setContentOffset(initialTableViewOffset!, animated:true)
            }
            
            // Put the dateCell date text back to black
            dateCell?.detailTextLabel?.textColor = UIColor.blackColor()
            
            
        } else  {
            // didn't find a picker below it, so we should insert it
            if var firstSection = sections.first {
                firstSection.items.append(.DatePicker)
                sections.removeAtIndex(0)
                sections.insert(firstSection, atIndex: 0)
            }
            tableView.insertRowsAtIndexPaths([targetIndexPath], withRowAnimation: .Fade)
            
            // Offset the tableView so that the date cell and the picker are fully displayed
            if let dateCellFrame = dateCell?.frame {
                tableView.setContentOffset(CGPoint(x: 0, y: dateCellFrame.origin.y), animated:true)
            }
            // Put the dateCell date text in blue, so that the user knows where to tap to dismiss
            dateCell?.detailTextLabel?.textColor = UIColor.blueColor()
            
            
            // Store datePickerIndexPath
            datePickerIndexPath = targetIndexPath
            
            // inform our date picker of the current date to match the current cell
            updateDatePicker()
            
        }
        
        tableView.endUpdates()
    }
    
    /** Updates the UIDatePicker's value to match with the date of the cell above it. */
    func updateDatePicker() {
        if datePickerIndexPath != nil {
            if let datePickerCell = self.tableView.cellForRowAtIndexPath(datePickerIndexPath!) {
                
                if let targetedDatePicker = datePickerCell.viewWithTag(Storyboard.DatePickerTag) as? UIDatePicker {
                    
                    // We found a UIDatePicker in this cell, so update its date value from the cell above
                    if let dateCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: datePickerIndexPath!.row - 1, inSection: datePickerIndexPath!.section)) as UITableViewCell? {
                        if let date = dateFormatter.dateFromString((dateCell.textLabel?.text)!) {
                            targetedDatePicker.setDate(date, animated: false)
                        }
                    }
                }
            }
        }
    }
    
    
    /** User chose to change the date by changing the values inside the UIDatePicker. */
    @IBAction func dateAction(sender: UIDatePicker) {
        
        if datePickerIndexPath != nil {
            // Update the cell's date "above" the date picker cell
            var dateCellIndexPath = NSIndexPath(forRow: datePickerIndexPath!.row - 1, inSection: datePickerIndexPath!.section)
            
            if dateCellIndexPath != nil {
                if var dateCell = self.tableView.cellForRowAtIndexPath(dateCellIndexPath!) as UITableViewCell? {
                    
                    // update our data model
                    tradingDate = sender.date
                    
                    // update the cell's date string
                    dateCell.detailTextLabel?.text = dateFormatter.stringFromDate(sender.date)
                }
            }
        }
    }
    
    
    // MARK: Table view delegate methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Resign first responder if a textField was previously selected
        selectedTextField?.resignFirstResponder()
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell?.reuseIdentifier == Storyboard.DateCellReuseIdentifier {
            
            // The current edited textField must not be in error
            if textFieldInError == false {
                
                // Show / Hide the date picker
                toggleDatePickerForSelectedIndexPath(indexPath)
            }
        }
        
        // always deselect the row containing the date
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
        
    }
    
    
    // MARK: Textfield delegate methods (and backgroundTapped)
    
    // This method is useful for iPad where there is no decimal keypad  
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Resigning first responder calls textFieldDidEndEditing
        return true
    }
    
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        // Resign first responder, which removes the decimal keypad
        view.endEditing(true)
        
        // A new textfield cannot get edited as long as the previous selected textField is in error
        return !textFieldInError
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
                
        if textField.tag == 0 || textField.tag == 1 || textField.tag == 2 {
            selectedTextField = textField
            
            
            // Offset the tableView so that the textField is not hidden by the keyboard
            
            // Get the UITableViewCell containing the textField
            if let cell = cellContainingView(textField) { // helper method
                
                //        NSLog(@"TableView contentOffset y: %f", self.tableView.contentOffset.y);
                //        NSLog(@"UITableViewCell frame y : %f", cell.frame.origin.y);
                
                /*
                The CONTENTOFFSET property is always the current location of the top-left corner of the scroll bounds, whether scrolling is in progress or not.
                Therefore:
                - setting a POSITIVE contentOffset.x to a tableView will scroll the tableView LEFT, while a NEGATIVE contentOffset.x will scroll it RIGHT.
                - setting a POSITIVE contentOffset.y to a tableView will scroll the tableView UP, while a NEGATIVE contentOffset.y will scroll it DOWN.
                */
                
                tableView.setContentOffset(CGPoint(x: 0, y: cell.frame.origin.y), animated:true)
            }
            
            // Set a toolBar as the textField input accessory view, with a "Done" button (only for iPhone, because iPad keyboard already has a "return" key)
            // TODO: using userInterfaceIdiom is not recommended anymore in iOS8
            if traitCollection.userInterfaceIdiom == .Phone {
                createInputAccessoryForTextField(selectedTextField!)
            }
        }
    }
    
    /** Helper method to go up the view hierarchy of a given UIView until the UITableViewCell containing it is found.
    Works with iOS7 too (there are now 3 levels in a UITableViewCell view hierarchy : UITableViewCell > UITableViewCellScrollView > contentView) */
    func cellContainingView(var view: UIView!) -> UITableViewCell! {
        
        while view != nil {
            if view is UITableViewCell {
                return view as! UITableViewCell
            } else {
                view = view.superview!
            }
        }
        return nil
    }
    
    
    func createInputAccessoryForTextField(textField: UITextField) -> Void {
        var keyboardToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: StandardButtonHeight))
        keyboardToolBar.barStyle = .BlackTranslucent
        keyboardToolBar.tintColor = UIColor.whiteColor()
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: textField, action: "resignFirstResponder")
        keyboardToolBar.setItems([flexSpace, doneButton], animated: false)
        
        textField.inputAccessoryView = keyboardToolBar
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
        
        if textField.tag == 0 { // Number of shares
            // remove decimal separator in entry field
            var replacedText = (textField.text as NSString).stringByReplacingCharactersInRange(range, withString:string)
            textField.text = replacedText.stringByReplacingOccurrencesOfString(decimalSeparator, withString:"")
            return false
        }
        else if textField.tag == 1 || textField.tag == 2 { // Purchase/Sell share price or sell currency rate
            // remove 2nd decimal separator in entry field
            let numberOfDecimalSeparators = textField.text.componentsSeparatedByString(decimalSeparator).count - 1
            
            if numberOfDecimalSeparators == 1 && string == decimalSeparator {
                let replacedText = (textField.text as NSString).stringByReplacingCharactersInRange(range, withString:"")
                textField.text = replacedText
                return false
            }
        }
        return true
    }
    
    
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        // If the user pressed Cancel, then return without checking the content of the textfield
        if !cancelButtonPressed {
            var textFieldValueNumber = NSNumber()
            
            if textField.tag == 0 {  // Number of shares
                textFieldValueNumber = numberOfSharesFormatter.numberFromString(textField.text)!
            } else if textField.tag == 1 {  // Purchase share price
                textFieldValueNumber = sharePriceFormatter.numberFromString(textField.text)!
            } else if textField.tag == 2 { // Purchase currency rate
                textFieldValueNumber = currencyRateFormatter.numberFromString(textField.text)!
            }
            
            if textFieldValueNumber == 0 || textField.text == "" { // forbid 0
                let alertView = UIAlertController(title: NSLocalizedString("Stock Trading VC:control field title", comment: "Mandatory field"),
                    message: NSLocalizedString("Stock Trading VC:control field message", comment: "This field must not be zero"),
                    preferredStyle: .Alert)
                // cancel button
                let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alertView.addAction(cancelAction)
                
                presentViewController(alertView, animated: true, completion: nil)
                
                
                // Prevent from saving
                textFieldInError = true
                return false
            }
        }
        // Allow saving
        textFieldInError = false
        return true
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        selectedTextField = nil
        
        // Set the tableView offset back to the initial state
        if initialTableViewOffset != nil {
            tableView.setContentOffset(initialTableViewOffset!, animated:true)
        }
    }
    
    
    // Tapping the background triggers end editing for the textField
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        selectedTextField?.endEditing(true)
    }
    
    
    // MARK: notification center methods
    func localeChanged(notification: NSNotification) {
        // The user changed the locale (region format) in Settings, so we are notified here to update the date format in the table view cells
        tableView.reloadData()
    }
    
}