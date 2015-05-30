//
//  CreateNotificationMainVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class CreateNotificationMainViewController: UIViewController {
    
    // MARK: Public properties
    var stock: Stock!
    
    // MARK: Private properties
    @IBOutlet private weak var notificationPriceButton: UIButton!
    @IBOutlet private weak var notificationStockValueButton: UIButton!
    @IBOutlet private weak var notificationGainOrLossValueButton: UIButton!
    @IBOutlet private weak var notificationGainOrLossPercentageButton: UIButton!
    
    
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Create Stock Notif Main VC:title", comment: "Create notification")
        
        let buttonTitleCommonText = NSLocalizedString("Create Stock Notif Main VC:general text", comment: "Create a notification based on the *target*")
        
        let buttonTitleSharePriceText = String.localizedStringWithFormat(buttonTitleCommonText, NSLocalizedString("Create Stock Notif Main VC:share price", comment: "SHARE PRICE"))
        notificationPriceButton.setTitle(buttonTitleSharePriceText, forState: .Normal)
        
        let buttonTitleStockValueText = String.localizedStringWithFormat(buttonTitleCommonText, NSLocalizedString("Create Stock Notif Main VC:stock value", comment: "STOCK VALUE"))
        notificationStockValueButton.setTitle(buttonTitleStockValueText, forState: .Normal)
        
        let buttonTitleGainOrLossValueText = String.localizedStringWithFormat(buttonTitleCommonText, NSLocalizedString("Create Stock Notif Main VC:gain value", comment: "GAIN OR LOSS VALUE"))
        notificationGainOrLossValueButton.setTitle(buttonTitleGainOrLossValueText, forState: .Normal)

        let buttonTitleGainOrLossPercentageText = String.localizedStringWithFormat(buttonTitleCommonText, NSLocalizedString("Create Stock Notif Main VC:gain %", comment: "GAIN OR LOSS %"))
        notificationGainOrLossPercentageButton.setTitle(buttonTitleGainOrLossPercentageText, forState: .Normal)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
                
        // Check if local notifications are allowed
        if UIApplication.sharedApplication().currentUserNotificationSettings().types == .None {
            // It's pointless to create Stock Notifications if notifications are disabled. Therefore invite the user to change his settings
            var alertView = UIAlertController(title: NSLocalizedString("Create Stock Notif Main VC:permissions title", comment: "No permissions!"),
                message: NSLocalizedString("Create Stock Notif Main VC:notification status", comment: "Please allow Portfolio to send local notifications"),
                preferredStyle: .Alert)
            
            // cancel button
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .Cancel, handler: nil)
            alertView.addAction(cancelAction)
            
            // settings button
            let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .Default, handler: { action in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
            alertView.addAction(settingsAction)
            
            presentViewController(alertView, animated: true, completion: nil)
        }
        
        // Check if background app refresh is allowed
        if UIApplication.sharedApplication().backgroundRefreshStatus == .Denied { // Don't ask if the status is restricted
            // It's pointless to create Stock Notifications if background app refresh is disabled. Therefore invite the user to change his settings
            var alertView = UIAlertController(title: NSLocalizedString("Create Stock Notif Main VC:permissions title", comment: "No permissions!"),
                message: NSLocalizedString("Create Stock Notif Main VC:background refresh", comment: "Please allow Portfolio to use background app refresh"),
                preferredStyle: .Alert)
            
            // cancel button
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button title"), style: .Cancel, handler: nil)
            alertView.addAction(cancelAction)
            
            // settings button
            let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings"), style: .Default, handler: { action in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
            alertView.addAction(settingsAction)
            
            presentViewController(alertView, animated: true, completion: nil)
        }

    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Create Notification (Main)")
    }
    

    
    @IBAction func notificationButtonTapped(sender: UIButton) {
        performSegueWithIdentifier("SetNotificationTarget", sender: sender)
    }
    
    
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if let identifier = segue.identifier {
            switch identifier {
                
            case "SetNotificationTarget":
                if let targetVC = segue.destinationViewController as? CreateNotificationTargetViewController {
                    if let button = sender as? UIButton {
                        if let existingNotificationType = StockNotificationType(rawValue: button.tag) {
                            targetVC.notificationType = existingNotificationType
                            targetVC.stock = stock
                        }
                    }
                }
                
            default: break
            }
        }
    }
    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        println("Closing Create Notification Main VC")
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
}