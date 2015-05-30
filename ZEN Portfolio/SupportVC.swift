//
//  SupportVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 23/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


import MessageUI
//import StoreKit


class SupportViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: Private properties
    @IBOutlet private weak var rateAppButton: UIButton!
    @IBOutlet private weak var requestSupportButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var appVersionLabel: UILabel!
    
    
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set button titles
        rateAppButton.setTitle(NSLocalizedString("Support VC:rate app", comment: "Rate the app on the App Store"), forState: .Normal)
        requestSupportButton.setTitle(NSLocalizedString("Support VC:request support", comment: "Send a mail to the support"), forState: .Normal)
        shareButton.setTitle(NSLocalizedString("Support VC:share", comment: "Tell others about this app"), forState: .Normal)
        
        // App version number
        let versionString = NSLocalizedString("Support VC:version", comment: "Version")
        appVersionLabel.text = "\(versionString) \(bundleVersion)" // bundleVersion is a global property (in AppDelegate)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Support")
    }
    

    
    // MARK: Rate app
    @IBAction func rateApp(sender: UIButton) {
        
        // Option 1: SKStoreProductViewController opens the App Store page directly, without leaving the application ... but the "review" button is inactive !
        
        // Option 2: link opening the application page on the App Store (leaves the application)
        //        let iTunesLink = "itms-apps://itunes.apple.com/app/id\(APPSTORE_IDENTIFIER)"
        
        // Option 3: link opening the application page on the App Store and going directly on the "Review" tab on the App Store (leaves the application)
        let iTunesLink = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(Identifiers.AppStoreIdentifier)&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
        // APPSTORE_IDENTIFIER is a global property (in AppDelegate)
        
        UIApplication.sharedApplication().openURL(NSURL(string:iTunesLink)!)
    }
    
    
    // MARK: Send mail to support
    @IBAction func writeMailToSupport(sender: UIButton) {
        
        // Email Subject
        let emailTitle = NSLocalizedString("Support VC:e-mail title", comment: "Support request")
        // Email Content
        let issueDescriptionNotice = NSLocalizedString("Support VC:e-mail body", comment: "[Please describe the issue you encountered, if possible with screenshots]")
        let technicalInformation = "[\(UIDevice.currentDevice().model) (iOS \(UIDevice.currentDevice().systemVersion)) - ZEN Portfolio v\(bundleVersion)]"
        let messageBody = "\(issueDescriptionNotice)\n\(technicalInformation)"
        
        // To address
        let toRecipents: Array<String> = ["apps@novaera.fr"]
        
        // Create a mail composer
        var mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setSubject(emailTitle)
        mailComposer.setMessageBody(messageBody, isHTML: false)
        mailComposer.setToRecipients(toRecipents)
        
        // Present mail view controller on screen
        presentViewController(mailComposer, animated: true, completion:nil)
    }
    
    
    // MFMailComposeVC delegate methods
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        
        if error == nil {
            switch result.value {
            case MFMailComposeResultCancelled.value:
                println("Mail cancelled")
                // Close the Mail Interface
                dismissViewControllerAnimated(true, completion:nil)
                
            case MFMailComposeResultSaved.value:
                println("Mail saved")
                // Close the Mail Interface
                dismissViewControllerAnimated(true, completion:nil)
                
            case MFMailComposeResultSent.value:
                println("Mail sent")
                
                // Confirm that the e-mail has been sent
                let alertView = UIAlertController(
                    title:NSLocalizedString("Support VC:mail confirm title", comment: "Mail sent"),
                    message:NSLocalizedString("Support VC:mail sent", comment: "Thank you for your mail! We usually answer support requests within 48 hours."),
                    preferredStyle: .Alert)
                // cancel button
                let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: { action in
                    // Close the Mail Interface
                    self.dismissViewControllerAnimated(true, completion:nil)
                })
                
                alertView.addAction(cancelAction)
                
                // Show the alert view on the mail to send
                presentedViewController?.presentViewController(alertView, animated: true, completion:nil)
                
            case MFMailComposeResultFailed.value:
                println("Mail sent failure: \(error.localizedDescription)")
                
                // Close the Mail Interface
                dismissViewControllerAnimated(true, completion:nil)
                
            default:
                println("Other case")
            }
        } else {
            // Error occurred
            // Inform the user that the mail experienced an error
            let alertView = UIAlertController(
                title:NSLocalizedString("Error", comment : "Error"),
                message:error.localizedDescription,
                preferredStyle: .Alert)
            // cancel button
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: { action in
                // Close the Mail Interface
                self.dismissViewControllerAnimated(true, completion:nil)
            })
            
            alertView.addAction(cancelAction)
            
            presentViewController(alertView, animated: true, completion: nil)
        }
    }
    
    
    // MARK: Share app
    @IBAction func shareApp(sender: UIButton) {
        // Create a UIActivityViewController
        let text = NSLocalizedString("Support VC:share text", comment: "ZEN Portfolio is a simple and efficient stocks manager.\nhttp://itunes.apple.com/app/id576249340?mt=8")
        let image = UIImage(named:"AppIcon60x60")!
        
        var activityVC = UIActivityViewController(activityItems:[text, image], applicationActivities:nil)
        // Activity VC excluded activities
        activityVC.excludedActivityTypes = [UIActivityTypeAddToReadingList, UIActivityTypeAirDrop, UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToVimeo, UIActivityTypePrint,  UIActivityTypeSaveToCameraRoll]
        
        // Activity VC completion handler
        activityVC.completionWithItemsHandler = { (activityType: String!, completed: Bool, returnedItems:[AnyObject]!, error: NSError!) -> () in
            if error == nil {
                if completed == true {
                    let alertView = UIAlertController(
                        title:NSLocalizedString("Support VC:sharing confirm title", comment: "Action performed"),
                        message:NSLocalizedString("Support VC:sharing completed", comment: "Thank you for telling other people about Zen Portfolio!"),
                        preferredStyle: .Alert)
                    // cancel button
                    let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertView.addAction(cancelAction)
                    
                    self.presentViewController(alertView, animated: true, completion: nil)
                    
                }
            } else {
                // Error occurred
                // Inform the user that the sharing process experienced an error
                let alertView = UIAlertController(
                    title:NSLocalizedString("Error", comment : "Error"),
                    message:error.localizedDescription,
                    preferredStyle: .Alert)
                // cancel button
                let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: { action in
                    // Close the Interface
                    self.dismissViewControllerAnimated(true, completion:nil)
                })
                
                alertView.addAction(cancelAction)
                
                self.presentViewController(alertView, animated: true, completion: nil)
            }
        }
        
        activityVC.popoverPresentationController?.sourceView = sender
        activityVC.popoverPresentationController?.sourceRect = sender.frame
        
        if activityVC.respondsToSelector("popoverPresentationController") {
            // iOS 8+
            let presentationController = activityVC.popoverPresentationController
            presentationController?.sourceView = self.view
        }
        
        presentViewController(activityVC, animated: true, completion:nil)
        
    }
    

}


