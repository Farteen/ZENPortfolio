//
//  EmptyView.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 17/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class EmptyView: UIView {
    
    // MARK: Public properties
    var message: String {
        get {
            return messageLabel.text!
        }
        set {
            messageLabel.text = newValue
        }
    }
    
    
    // MARK: Private properties
    private var messageLabel: UILabel
    
    // EmptyView dimensions (constants)
    private let EmptyViewSideMargin: CGFloat = 20.0
    private let EmptyViewHeight: CGFloat = 100.0

    
    // Required initializer
    required init(coder aDecoder: NSCoder) {
        self.messageLabel = UILabel()
        super.init(coder: aDecoder)
    }
    
    // Designated Initializer
    init(frame: CGRect, message: String) {
        
        // MessageLabel customization
        self.messageLabel = UILabel(frame:frame)
        self.messageLabel.text = message
        self.messageLabel.numberOfLines = 2
        self.messageLabel.textAlignment = .Center
        self.messageLabel.textColor = UIColor.darkGrayColor()
        self.messageLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)
        
        super.init(frame: frame)
        
        // EmptyView customization
        self.backgroundColor = UIColor.whiteColor()
        
        // Calculate message position
        self.messageLabel.frame = CGRect(
            x: self.bounds.origin.x + EmptyViewSideMargin,
            y: self.bounds.size.height / 2 - EmptyViewHeight / 2,
            width: self.bounds.size.width - 2 * EmptyViewSideMargin,
            height: EmptyViewHeight)
        
        // Add the message label as a subview of the emptyView
        self.addSubview(self.messageLabel)
    }
}