//
//  StockListTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 24/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import UIKit

class StockListTableViewCell: UITableViewCell {
    
    // MARK: Public properties
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var variableTextButton: UIButton!
    
    // Define List view controller as the controller of the cell (weak)
    weak var controller: StockListTableViewController!
    
    
    // MARK: Private properties
    private let CornerRadius: CGFloat = 5.0
    private let DarkenColorRatio: CGFloat = 30.0
    private var alreadySelected = false
    
    
    // MARK: View initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup button corner radius
        variableTextButton.layer.cornerRadius = CornerRadius
        variableTextButton.layer.masksToBounds = true
    }
    
    
    @IBAction func tappedButton(sender: UIButton) {
        // The cell receives the IBAction and transmits it to the controller, a.k.a. the StockListTVC.
        controller.toggleValues(self)
    }
    
    // MARK: highlighted / selected states
    
    override func setHighlighted(highlighted: Bool, animated: Bool)  {
        // Save the color of the variableTextButton before super.setHighlighted(animated)
        let initialColor = variableTextButton.backgroundColor
        
        super.setHighlighted(highlighted, animated:animated)
        
        if highlighted == true {
            if alreadySelected == false {
                // If the cell is highlighted (iPhone mainly because it is a temporary state when pushing the DetailVC)
                // change the variableTextButton background to a darker color
                variableTextButton.backgroundColor  = UIColor.darkenColor(initialColor, withRatio:DarkenColorRatio)
            }
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        // Save the color of the variableTextButton before [super setSelected: animated:]
        let initialColor = variableTextButton.backgroundColor
        
        super.setSelected(selected, animated:animated)
        
        if selected == true {
            // If the cell is selected (iPad mainly because it is a permanent state when presenting the DetailVC in the SplitViewController's detail view)
            if alreadySelected == false {
                
                // change the variableTextButton background to a darker color
                variableTextButton.backgroundColor  = UIColor.darkenColor(initialColor, withRatio:DarkenColorRatio)
                
                alreadySelected = true
            }
            
        } else {
            alreadySelected = false
        }
    }


}


private extension UIColor {
    // Make color darker
    class func darkenColor(initialColor: UIColor!, withRatio ratio: CGFloat) -> UIColor {
        
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        // If the current color is in the RGB space, get its red, green and blue components
        if initialColor.getRed(&red, green:&green, blue:&blue, alpha:&alpha) {
            
            // Make the RGB components darker
            red -= ratio/255.0
            green -= ratio/255.0
            blue -= ratio/255.0
            
            return UIColor(red:red, green:green, blue:blue, alpha:alpha)
        } else {
            return initialColor
        }
    }
}