//
//  CreditsVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 22/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


class CreditsViewController: UIViewController {
    
    // Private property
    @IBOutlet private weak var scrollView: UIScrollView!
    
    // MARK: View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = NSLocalizedString("Prefs VC:Credits", comment: "Credits")
        
        // Background pattern
        view.backgroundColor = UIColor(patternImage: UIImage(named:"shattered")!)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Credits")
    }
    

}