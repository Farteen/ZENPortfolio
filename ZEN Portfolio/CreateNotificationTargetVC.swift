    //
//  CreateNotificationTargetVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class CreateNotificationTargetViewController: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Public properties
    var stock: Stock!
    var notificationType: StockNotificationType!
    
    // MARK: Private properties
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var targetTextField: UITextField!
    @IBOutlet private weak var targetUnitLabel: UILabel!
    
    private var notificationTypeDescription = String()
    private var targetLevel = 0.0
    
    private var textFieldInError = false
    private var backButtonPressed = false
    
    // Decimal formatter (2 fraction digits)
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
        targetTextField.placeholder = NSLocalizedString("Create Stock Notif Target VC:placeholder", comment: "Enter target value");
        
        // Update UI elements (labels), in case outlets are not yet set at that time
        updateUI()
        
        // Set this View Controller as the navigation controller delegate
        navigationController?.delegate = self
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set the Textfield  as the first responder
        targetTextField.becomeFirstResponder()
        
        // Google Analytics
        setAnalyticsScreenName("Create Notification (Target)")
        
    }
    
    
    
    // MARK: custom methods
    func updateUI() {
        var myStockText = String() // depending on the notificationType, can be "Apple Inc.", "2 shares of Apple Inc.", or "my 2 shares of Apple Inc."
        
        // Fixed localized strings
        let sharesLocalizedString = NSLocalizedString("Sales Journal VC:shares", comment: "shares")
        let ofLocalizedString = NSLocalizedString("Stock Notif List VC:of", comment: "of ")
        let myLocalizedString = NSLocalizedString("Stock Notif List VC:my", comment: "my ")
        
        switch notificationType! {
            
        case .Price:
            notificationTypeDescription = NSLocalizedString("Create Stock Notif Main VC:share price", comment: "SHARE PRICE")
            myStockText = stock.name
            targetTextField.text = decimalFormatter.stringFromNumber(stock.currentSharePrice)
            targetUnitLabel.text = stock.currency
            
        case .StockValue:
            notificationTypeDescription = NSLocalizedString("Create Stock Notif Main VC:stock value", comment: "STOCK VALUE")
            myStockText = "\(stock.numberOfShares) \(sharesLocalizedString)\(ofLocalizedString)\(stock.name)"
            targetTextField.text = decimalFormatter.stringFromNumber(stock.valueInPortfolioCurrency)
            targetUnitLabel.text = GlobalSettings.sharedStore.portfolioCurrency
            
        case .GainOrLossValue:
            notificationTypeDescription = NSLocalizedString("Create Stock Notif Main VC:gain", comment: "GAIN OR LOSS")
            myStockText = "\(myLocalizedString)\(stock.numberOfShares) \(sharesLocalizedString)\(ofLocalizedString)\(stock.name)"
            targetTextField.text = decimalFormatter.stringFromNumber(stock.gainOrLossValue)
            targetUnitLabel.text = GlobalSettings.sharedStore.portfolioCurrency
            
        case .GainOrLossPercentage:
            notificationTypeDescription = NSLocalizedString("Create Stock Notif Main VC:gain %", comment: "GAIN OR LOSS %")
            myStockText = "\(myLocalizedString)\(stock.numberOfShares) \(sharesLocalizedString)\(ofLocalizedString)\(stock.name)"
            targetTextField.text = decimalFormatter.stringFromNumber(stock.gainOrLossPercentage * 100) // Present in %
            targetUnitLabel.text = "%"
        }
        
        headerLabel.text = String.localizedStringWithFormat(NSLocalizedString("Create Stock Notif Target VC:general text", comment: "Notify me when the *target* of *stock text* reaches:"), notificationTypeDescription, myStockText)
        view.backgroundColor = notificationType.color
    }
    
    
    
    // MARK: Navigation controller delegate
    override func willMoveToParentViewController(parent: UIViewController!) {
        // If there is no parent, then it means that the view controller has been removed from the stack, which happens when the back button has been pressed
        if parent == nil {
            backButtonPressed = true
        }
    }

    
    
    // MARK: Textfield delegate methods (and backgroundTapped)
    
    // This method is useful for iPad where there is no decimal keypad
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        targetTextField.resignFirstResponder() // Resigning first responder calls textFieldDidEndEditing:
        return true
    }
    
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        // Set a toolBar as the textField input accessory view
        createInputAccessoryForTextField(textField)
    }
    
    
    func createInputAccessoryForTextField(textField: UITextField) -> Void {
        
        if (notificationType == StockNotificationType.GainOrLossValue)  || (notificationType == StockNotificationType.GainOrLossPercentage) {

            var keyboardToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44))
            keyboardToolBar.barStyle = .BlackTranslucent
            keyboardToolBar.tintColor = UIColor.whiteColor()
            
            let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let positiveNegativeButton = UIBarButtonItem(title: "+/-", style: .Plain, target: self, action: "invertValueOfTextField")
            keyboardToolBar.setItems([flexSpace, positiveNegativeButton], animated: false)
            
            textField.inputAccessoryView = keyboardToolBar
        }
    }
    
    
    func invertValueOfTextField() {
        if let textFieldValue = decimalFormatter.numberFromString(targetTextField.text) {
            let negativeValue = Float(textFieldValue) * -1
            targetTextField.text = decimalFormatter.stringFromNumber(NSNumber(float: negativeValue))
        }
    }
    
    
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let decimalSeparator = NSLocale.currentLocale().objectForKey(NSLocaleDecimalSeparator) as! String
        
        let numberOfDecimalSeparators = textField.text.componentsSeparatedByString(decimalSeparator).count - 1
        if numberOfDecimalSeparators == 1 && string == decimalSeparator {
            // remove 2nd decimal separator in entry field
            textField.text = textField.text.stringByReplacingOccurrencesOfString(decimalSeparator, withString:"")
            return false
        }
        return true
    }

    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        // If the user pressed Back, then return without checking the content of the textfield
        if backButtonPressed == false {
            
            // Alert if the textField is empty
            if textField.text.isEmpty {
                var alertView = UIAlertController(title: NSLocalizedString("Stock Trading VC:control field title", comment: "Mandatory field"),
                    message: NSLocalizedString("Stock Trading VC:control field message", comment: "This field must be filled"),
                    preferredStyle: .Alert)
                
                // cancel button
                let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alertView.addAction(cancelAction)
                
                presentViewController(alertView, animated: true, completion: nil)
                
                // Prevent from saving
                textFieldInError = true
                return false
                
            } else {
                // Control that the number is entered correctly (if the number is not properly formatted, it will be nil)
                
                if decimalFormatter.numberFromString(textField.text) == nil {
                    let alertView = UIAlertController(title: NSLocalizedString("Stock Trading VC:incorrect entry title", comment: "Entry error"),
                        message: NSLocalizedString("Stock Trading VC:incorrect entry message", comment: "Please check that this field is not empty and does not contain incorrect characters"),
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
        }
        // Allow saving
        textFieldInError = false
        return true
    }


    func textFieldDidEndEditing(textField: UITextField) {
        if textField.text.isEmpty {
            targetLevel = 0.0
        } else {
            if let targetNumber = decimalFormatter.numberFromString(textField.text) {
                // update target level
                if notificationType == StockNotificationType.GainOrLossPercentage {
                    targetLevel = targetNumber.doubleValue / 100.0
                } else {
                    targetLevel = targetNumber.doubleValue
                }
            }
        }
    }


    // Tapping the background triggers end editing for the textField
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        targetTextField.endEditing(true)
    }

    
    // MARK: Save notification target
    // We cannot create a local notification yet : the notification type and target have to be kept on hold until the required condition is met (i.e. the share price, stock value, gain or loss value or gain or loss percentage has been reached) and the local notification is fired.
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        // Textfield resigns first responder
        view.endEditing(true)
        
        // Textfield currently edited should not be in error
        if textFieldInError == false {
            
            // Determine whether the comparison between the current item level and the target level should be ascending or not
            var compareAscending = false
            var yourStockText = String() // depending on the notificationType, can be "Apple Inc.", "2 shares of Apple Inc.", or "your 2 shares of Apple Inc."
            
            // Fixed localized strings
            let sharesLocalizedString = NSLocalizedString("Sales Journal VC:shares", comment: "shares")
            let ofLocalizedString = NSLocalizedString("Stock Notif List VC:of", comment: "of ")
            let myLocalizedString = NSLocalizedString("Stock Notif List VC:my", comment: "my ")
            let yourLocalizedString = NSLocalizedString("Stock Notif List VC:your", comment: "your ")
            
            switch notificationType! {
            case .Price: // Stock price
                compareAscending = targetLevel >= stock.currentSharePrice
                yourStockText = stock.name
                
            case .StockValue: // Stock value
                compareAscending = targetLevel >= stock.valueInPortfolioCurrency
                yourStockText = "\(stock.numberOfShares)  \(sharesLocalizedString)\(ofLocalizedString)\(stock.name)"
                
            case .GainOrLossValue: // Gain or loss value
                compareAscending = targetLevel >= stock.gainOrLossValue
                yourStockText = "\(yourLocalizedString)\(stock.numberOfShares) \(sharesLocalizedString)\(ofLocalizedString)\(stock.name)"
                
            case .GainOrLossPercentage: // Gain or loss %
                compareAscending = targetLevel >= stock.gainOrLossPercentage
                yourStockText = "\(yourLocalizedString)\(stock.numberOfShares) \(sharesLocalizedString)\(ofLocalizedString)\(stock.name)"
            }
            
            // If the stock does not have a unique identifier yet, give it one on the fly
            if stock.uniqueIdentifier == nil {
                stock.uniqueIdentifier = NSUUID().UUIDString
            }
            
            // Save notification target details as a StockNotification
            let notification = StockNotificationStore.sharedStore.createNotification(type: notificationType, forStockIdentifier:stock.uniqueIdentifier!, withTarget: targetLevel, compareAscending: compareAscending)
            // Save the notification to iCloud
            StockNotificationStore.sharedStore.addRecordToCloud(notification)
            
            // Issue message indicating that the notification is saved in the Notification Store
            var targetLevelText = String()
            if notificationType == .GainOrLossPercentage {
                targetLevelText = decimalFormatter.stringFromNumber(targetLevel * 100.0)! // Present in %
            } else {
                targetLevelText = decimalFormatter.stringFromNumber(targetLevel)!
            }
            
            var reachText = String()
            if compareAscending == true {
                reachText = NSLocalizedString("Stock Notif List VC:goes over", comment: "goes over ")
            } else {
                reachText = NSLocalizedString("Stock Notif List VC:goes under", comment: "goes under ")
            }
            
            let messageText = String.localizedStringWithFormat(NSLocalizedString("Create Stock Notif Target VC:logging message", comment: "You will be notified when the *target* of *yourStock* will *go over* *level*"), notificationTypeDescription, yourStockText, reachText, targetLevelText, targetUnitLabel.text!)
            
            
            let alertView = UIAlertController(title: NSLocalizedString("Create Stock Notif Target VC:created", comment: "New notification created"), message: messageText, preferredStyle: .Alert)
            
            // cancel button
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: { action in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            
            alertView.addAction(cancelAction)
            
            presentViewController(alertView, animated: true, completion: nil)
        }
    }


}