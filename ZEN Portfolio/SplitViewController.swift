//
//  SplitViewController.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 11/10/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

/** This is a subclass of the UISplitViewController, conforming to the UISplitViewControllerDelegate. */
class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    // MARK: View Life Cycle
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        
        delegate = self
        preferredPrimaryColumnWidthFraction = 0.45 // default is 40%
        preferredDisplayMode = .AllVisible
    }

    
    
    // UISplitViewControllerDelegate methods
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController!, ontoPrimaryViewController primaryViewController: UIViewController!) -> Bool {
        
        // Collapse by showing the PrimaryViewController, i.e. the StockListTVC
        return true
    }
    
}