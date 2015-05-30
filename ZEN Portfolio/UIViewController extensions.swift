//
//  UIViewController extensions.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 29/03/2015.
//  Copyright (c) 2015 Frédéric ADDA. All rights reserved.
//

extension UIViewController {
    
    func setAnalyticsScreenName(screenName: String) {
        // May return nil if a tracker has not already been initialized with a
        // property ID.
        if let tracker = GAI.sharedInstance().defaultTracker {
            
            // This screen name value will remain set on the tracker and sent with
            // hits until it is set to a new value or to nil.
            tracker.set(kGAIScreenName, value:screenName)
            let build = GAIDictionaryBuilder.createScreenView().build() as [NSObject : AnyObject]
            tracker.send(build)
        }
    }

}