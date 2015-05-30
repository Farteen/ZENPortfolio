//
//  UIColor extensions.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import UIKit

extension UIColor {
    
    // MARK: custom colors used in the UI
    class func zenGreenColor() -> UIColor! {
        return UIColor(red:0.0/255.0, green:208.0/255.0, blue:78.0/255.0, alpha:1.0)
    }
    
    class func zenRedColor() -> UIColor! {
        return UIColor(red:255.0/255.0, green:59.0/255.0, blue:78.0/255.0, alpha:1.0)
    }
    
    class func zenGrayColor() -> UIColor! {
        return UIColor(red:133.0/255.0, green:133.0/255.0, blue:139.0/255.0, alpha:1.0)
    }

    class func zenGrayTextColor() -> UIColor! {
        return UIColor(red:111.0/255.0, green:111.0/255.0, blue:115.0/255.0, alpha:1.0)
    }
    
}
