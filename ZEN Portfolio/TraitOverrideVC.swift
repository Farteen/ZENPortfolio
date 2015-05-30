//
//  TraitOverrideVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 11/10/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



/** This is a container view controller. It is the root view controller of the application's window. It contains the Split View Controller as its only child view controller. Its purpose is to override UITraitCollection and force a custom behavior. */
class TraitOverrideViewController: UIViewController {
    
    /** A threshold above which we want to enforce regular size class, below that compact size class. */
    let CompactSizeClassWidthThreshold: CGFloat = 600.0 // More than 568 points wide = iPhone 6 or wider screen in landscape, in full screen mode
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        // If screen is wide enough, force a regular size class.
        var preferredTrait: UITraitCollection?
        if size.width as CGFloat > CompactSizeClassWidthThreshold {
            preferredTrait = UITraitCollection(horizontalSizeClass: .Regular)
        } else {
            preferredTrait = UITraitCollection(horizontalSizeClass: .Compact)
        }
        
        let childViewController = childViewControllers.first as! UIViewController
        setOverrideTraitCollection(preferredTrait, forChildViewController: childViewController)
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
}