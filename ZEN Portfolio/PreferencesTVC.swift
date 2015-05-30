//
//  PreferencesVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 20/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import CloudKit

class PreferencesTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Private properties
    @IBOutlet private weak var portfolioCurrencyLabel: UILabel!
    @IBOutlet private weak var portfolioCurrencyValue: UILabel!
    @IBOutlet private weak var buttonCycleLabel: UILabel!
    @IBOutlet private weak var automaticUpdateLabel: UILabel!
    @IBOutlet private weak var automaticUpdateSwitch: UISwitch!
    @IBOutlet private weak var cloudActivationSwitch: UISwitch!
    @IBOutlet private weak var cloudActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var notificationsLabel: UILabel!
    @IBOutlet private weak var notificationsValue: UILabel!
    @IBOutlet private weak var themeLabel: UILabel!
    @IBOutlet private weak var themeValue: UILabel!
    @IBOutlet private weak var supportLabel: UILabel!
    @IBOutlet private weak var creditsLabel: UILabel!
    
    private var lastSelectedIndexPath: NSIndexPath?
    
    
    
    //    var isPresentedInAPopover = false
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Title
        title = NSLocalizedString("Prefs VC:title", comment: "Preferences")
        
        // Static cells localized texts
        portfolioCurrencyLabel.text = NSLocalizedString("Prefs VC:Currency settings", comment: "Portfolio Currency")
        buttonCycleLabel.text = NSLocalizedString("Prefs VC:Button cycle settings", comment: "Main screen buttons")
        automaticUpdateLabel.text = NSLocalizedString("Prefs VC:Update settings", comment: "Automatic update on/off")
        notificationsLabel.text = NSLocalizedString("Prefs VC:Notifications", comment: "Notifications")
        themeLabel.text = NSLocalizedString("Prefs VC:Theme settings", comment: "Theme")
        creditsLabel.text = NSLocalizedString("Prefs VC:Credits", comment: "Credits")
        supportLabel.text = NSLocalizedString("Prefs VC:Support", comment: "Support")
        
        // Switches initial state
        automaticUpdateSwitch.on = GlobalSettings.sharedStore.automaticUpdate
        cloudActivationSwitch.on = CloudManager.sharedManager.cloudActivated
        
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fade out the line after selection
        if lastSelectedIndexPath != nil {
            tableView.deselectRowAtIndexPath(lastSelectedIndexPath!, animated:true)
        }
        
        // Static cells value update
        portfolioCurrencyValue.text = GlobalSettings.sharedStore.portfolioCurrency
        themeValue.text = GlobalSettings.sharedStore.currentTheme.description
        notificationsValue.text = String(StockNotificationStore.sharedStore.allNotifications.count)
        
        // Hide "Done" button when the Preferences View controller is presented in a Popover
        // TODO: using userInterfaceIdiom is not recommended anymore in iOS8
        if traitCollection.userInterfaceIdiom == .Pad {
            //        if isPresentedInAPopover {
            navigationItem.rightBarButtonItem = nil
        }
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Preferences")
        
        // Check the logon status for iCloud
        CKContainer.defaultContainer().accountStatusWithCompletionHandler { (status, error) in
            if status == .Available {
                dispatch_async(dispatch_get_main_queue(), {
                    self.cloudActivationSwitch.enabled = true
                })
            } else {
                // Prevent from changing the iCloud activation if the iCloud account is not logged on
                dispatch_async(dispatch_get_main_queue(), {
                    self.cloudActivationSwitch.enabled = false
                    
                    TSMessage.showNotificationInViewController(self,
                        title: NSLocalizedString("iCloud:not loggedin", comment:"Not logged in to iCloud"),
                        subtitle: NSLocalizedString("iCloud:not loggedin explanation", comment:"iCloud activation switch cannot be changed until you log in to your iCloud account"),
                        type: TSMessageNotificationType.Warning)
                    
                })
                
            }
        }

    }
    
    
    // MARK: Table view datasource methods
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var footerString = String()
        
        if section == 1 { // Footer for automatic update explanation
            
            if GlobalSettings.sharedStore.automaticUpdate {
                footerString = String.localizedStringWithFormat(NSLocalizedString("Automatic update switch:on", comment: "Stocks updated only if older than x mn."), "\(GlobalSettings.sharedStore.updateFrequency)")
            } else {
                footerString = NSLocalizedString("Automatic update switch:off", comment: "Stocks never updated automatically.")
            }
            
        } else if section == 2 { // Footer for Cloud explanation
            if CloudManager.sharedManager.cloudActivated {
                footerString = NSLocalizedString("Cloud switch:on", comment: "Your stocks, sales journal and notifications are saved in the Cloud and synced across all your devices.")
            } else {
                footerString = NSLocalizedString("Cloud switch:off", comment: "Your stocks, sales journal and notifications are saved on this device only.")
            }
            
        } else if section == 3 { // Footer for Notifications explanation
            footerString = NSLocalizedString("Notifications footer", comment: "Notifications need Background app refresh to be activated.")
        }
        return footerString
    }
    
    
    // MARK: Table view delegate methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // After selection, deselect the line
        //    tableView.deselectRowAtIndexPath(indexPath, animated:true)
        lastSelectedIndexPath = indexPath
    }
    
    
    
    // MARK: Custom methods
    @IBAction func automaticUpdateSwitch(sender: UISwitch) {
        GlobalSettings.sharedStore.automaticUpdate = sender.on
        
        // Reload section footer text
        tableView.reloadData()
    }
    
    
}



// MARK: iCloud management
extension PreferencesTableViewController {
    
    @IBAction func cloudActivationSwitch(sender: UISwitch) {
        
        CloudManager.sharedManager.cloudActivated = sender.on
        self.cloudActivationSwitch.hidden = true
        cloudActivityIndicator.startAnimating()
        
        if sender.on {
            // Try to activate iCloud
            moveDataToCloud({ transferError in
                if transferError == nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        TSMessage.showNotificationInViewController(self,
                            title: NSLocalizedString("iCloud:activated", comment: "iCloud activated"),
                            subtitle: nil,
                            type: TSMessageNotificationType.Success)
                        
                        // Stop the activity indicator
                        self.cloudActivityIndicator.stopAnimating()
                        // Display the switch
                        self.cloudActivationSwitch.hidden = false
                        // Reload section footer text
                        self.tableView.reloadData()

                    })
                    
                    // TODO: Remove the error description after debug
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        TSMessage.showNotificationWithTitle(NSLocalizedString("iCloud:failed to activate", comment: "iCloud activation failed"),
                            subtitle: transferError.localizedDescription,
                            type: TSMessageNotificationType.Error)
                        // Turn the switch back to off
                        sender.on = false
                        
                        // Stop the activity indicator
                        self.cloudActivityIndicator.stopAnimating()
                        // Display the switch
                        self.cloudActivationSwitch.hidden = false

                    })
                }
            })
            
        } else {
            // Try to deactivate iCloud
            moveDataBackToLocal({ transferError in
                if transferError == nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        TSMessage.showNotificationWithTitle(NSLocalizedString("iCloud:deactivated", comment: "iCloud de-activated"),
                            subtitle: nil,
                            type: TSMessageNotificationType.Success)
                        
                        // Stop the activity indicator
                        self.cloudActivityIndicator.stopAnimating()
                        // Display the switch
                        self.cloudActivationSwitch.hidden = false
                        // Reload section footer text
                        self.tableView.reloadData()
                        
                    })
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        TSMessage.showNotificationInViewController(self,
                            title: NSLocalizedString("iCloud:failed to de-activate", comment: "Failed to de-activate iCloud"),
                            subtitle: nil,
                            type: TSMessageNotificationType.Error)
                        
                        // Turn the switch back to on
                        sender.on = false
                        
                        // Stop the activity indicator
                        self.cloudActivityIndicator.stopAnimating()
                        // Display the switch
                        self.cloudActivationSwitch.hidden = false
                        
                    })
                }
            })
        }
        
    }
    
    
    
    /** Move all the stocks from local to iCloud servers */
    func moveDataToCloud(completionHandler: (transferError: NSError!) -> ()) {
        
        let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
        
        // Check if there is already a StockStore CKRecord
        // We presume that if iCloud is used, then there is at least a StockStore CKRecord in iCloud (even empty)
        var query = CKQuery(recordType: "StockStore", predicate: NSPredicate(value: true))
        privateDatabase.performQuery(query, inZoneWithID: nil, completionHandler: { (records, error) in
            if error != nil {
                println("Error fetching stockStore: \(error.localizedDescription)")
                completionHandler(transferError: error)
                
            } else {
                
                // ** case 1 ** There is already an existing StockStore record in iCloud
                if records.count > 0 {
                    
                    // If there is already local data
                    if (StockStore.sharedStore.allStocks.count > 0) || (SalesJournal.sharedStore.allEntries.count > 0) || (StockNotificationStore.sharedStore.allNotifications.count > 0) {
                        
                        // Ask the user which version he wants to keep
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            // TODO: translate that
                            var alertView = UIAlertController(
                                title: NSLocalizedString("iCloud:conflicting records", comment: "ConflictingRecords"),
                                message: NSLocalizedString("iCloud:conflict explanation" , comment: "There are records saved both in iCloud and on local. Which ones would you like to keep?"),
                                preferredStyle: UIAlertControllerStyle.Alert)
                            
                            // ** cancel button
                            let cancelAction = UIAlertAction(title: NSLocalizedString("iCloud:do not activate", comment: "Don't activate iCloud"), style: .Cancel, handler: { action in
                                
                                CloudManager.sharedManager.cloudActivated = false
                                
                                // Update UI
                                self.cloudActivationSwitch.on = false
                                
                                // Stop the activity indicator
                                self.cloudActivityIndicator.stopAnimating()
                                // Display the switch
                                self.cloudActivationSwitch.hidden = false
                                
                            })
                            alertView.addAction(cancelAction)
                            
                            // ** Local data replaces iCloud
                            let overwriteWithLocalAction = UIAlertAction(title: NSLocalizedString("iCloud:local data", comment: "Overwrite iCloud with local data"), style: .Destructive, handler: { action in
                                // Erase all records in iCloud
                                CloudManager.sharedManager.deleteAllRecordsFromCloud({ deletionError in
                                    if deletionError != nil {
                                        completionHandler(transferError: deletionError)
                                        
                                    } else {
                                        // Then copy data to iCloud
                                        CloudManager.sharedManager.copyDataToCloud({ copyError in
                                            if copyError != nil {
                                                completionHandler(transferError: copyError)
                                                
                                            } else {
                                                // Finally, move stocks file from Document to Cache
                                                CloudManager.sharedManager.moveDataFromLocalArchiveToCache()
                                                completionHandler(transferError: nil)
                                            }
                                            
                                        })
                                    }
                                })
                                
                            })
                            alertView.addAction(overwriteWithLocalAction)
                            
                            // ** iCloud replaces Local data
                            let overwriteWithCloud = UIAlertAction(title: NSLocalizedString("iCloud:iCloud data", comment: "Overwrite local data with iCloud"), style: .Destructive, handler: { action in
                                // Load stocks from iCloud
                                CloudManager.sharedManager.loadDataFromCloud({ loadingError in
                                    if loadingError != nil {
                                        completionHandler(transferError: loadingError)
                                        
                                    } else {
                                        // Then save to Local Storage
                                        CloudManager.sharedManager.saveDataToLocalArchivePath()
                                        // Finally, move stocks file from Document to Cache
                                        CloudManager.sharedManager.moveDataFromLocalArchiveToCache()
                                        completionHandler(transferError: nil)
                                    }
                                })
                            })
                            alertView.addAction(overwriteWithCloud)
                            
                            
                            
                            self.presentViewController(alertView, animated: true, completion: nil)
                        }) // end of dispatch to main queue
                        
                    } else { // No data on local storage yet
                        // Load stocks from iCloud
                        CloudManager.sharedManager.loadDataFromCloud({ loadingError in
                            if loadingError != nil {
                                completionHandler(transferError: loadingError)
                                
                            } else {
                                // Then save to Local Storage
                                CloudManager.sharedManager.saveDataToLocalArchivePath()
                                // Finally, move stocks file from Document to Cache
                                CloudManager.sharedManager.moveDataFromLocalArchiveToCache()
                                completionHandler(transferError: nil)
                            }
                        })
                    }
                    
                    
                } else {
                    // ** case 2 ** There is no existing StockStore: we can presume there is no store at all in the Cloud
                    // Copy data to iCloud
                    CloudManager.sharedManager.copyDataToCloud({ copyError in
                        if copyError != nil {
                            completionHandler(transferError: copyError)
                            
                        } else {
                            // Finally, move stocks file from Document to Cache
                            CloudManager.sharedManager.moveDataFromLocalArchiveToCache()
                            completionHandler(transferError: nil)
                            
                        }
                    })
                    
                }
            }
        })
    }
    
    
    
    /** Move all the stocks from iCloud servers back to local storage */
    func moveDataBackToLocal(completionHandler: (transferError: NSError!) -> ()) {
        
        // Save stocks to Local Storage (they are already up-to-date)
        CloudManager.sharedManager.saveDataToLocalArchivePath()
        // Then, delete the Cache
        CloudManager.sharedManager.deleteCache()
        
        // Ask the user what he wants to do with the records in iCloud
        var questionAlertView = UIAlertController(
            title: NSLocalizedString("iCloud:records left", comment: "Records still in iCloud"),
            message:  NSLocalizedString("iCloud:records left explanation", comment: "There are still records saved in iCloud. Would you like to keep them (to use them later or on another device), or delete them definitely?"),
            preferredStyle: UIAlertControllerStyle.Alert)
        
        // ** cancel button
        let cancelAction = UIAlertAction(title: NSLocalizedString("iCloud:leave records", comment: "Leave records on iCloud"), style: .Cancel, handler: { action in
            completionHandler(transferError: nil)
        })
        questionAlertView.addAction(cancelAction)
        
        
        let deleteAction = UIAlertAction(title: NSLocalizedString("iCloud:delete records", comment: "Delete all records from iCloud"), style: .Destructive, handler: { action in
            CloudManager.sharedManager.deleteAllRecordsFromCloud({ deletionError in
                if deletionError != nil {
                    
                    // Tell the user that the stocks couldn't be suppressed
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        var alertView = UIAlertController(
                            title: NSLocalizedString("Error", comment: "Error"),
                            message: NSLocalizedString("iCloud:could not suppress", comment: "The records could not be suppressed from iCloud. iCloud will be de-activated anyway."),
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        // ** cancel button
                        let dismissAction = UIAlertAction(title: "OK", style: .Cancel, handler: { action in
                            completionHandler(transferError: nil) // deactivate iCloud anyway
                        })
                        alertView.addAction(dismissAction)
                        self.presentViewController(alertView, animated: true, completion: nil)
                        
                    })
                    
                } else {
                    completionHandler(transferError: nil)
                }
            })
        })
        questionAlertView.addAction(deleteAction)
        self.presentViewController(questionAlertView, animated: true, completion: nil)
    }
    
}