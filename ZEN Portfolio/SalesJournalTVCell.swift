//
//  SalesJournalTVCell.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 11/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class SalesJournalTableViewCell: UITableViewCell {
    
    // MARK: Public property
    var sale: Sale! {
        didSet {
            updateCell()
        }
    }
    
    // MARK: Public properties
    @IBOutlet private weak var saleYearLabel: UILabel!
    @IBOutlet private weak var saleMonthLabel: UILabel!
    @IBOutlet private weak var saleDayLabel: UILabel!
    @IBOutlet private weak var saleDetailLabel: UILabel!
    
    // Decimal formatter for price or value (2 fraction digits)
    private let decimalFormatter: NSNumberFormatter = {
        var decFormatter = NSNumberFormatter()
        decFormatter.numberStyle = .DecimalStyle
        decFormatter.minimumFractionDigits = 2
        decFormatter.maximumFractionDigits = 2
        decFormatter.locale = NSLocale.currentLocale()
        return decFormatter
        }()

    
    func updateCell() {
        // ** SALE DATE
        // 2-digit integer formatter
        let twoDigitIntegerFormatter = NSNumberFormatter()
        twoDigitIntegerFormatter.minimumIntegerDigits = 2
        
        // Date components
        let components = NSCalendar.currentCalendar().components(.CalendarUnitDay | .CalendarUnitMonth | .CalendarUnitYear, fromDate:sale.saleDate)
        saleYearLabel.text = "\(components.year)"
        saleMonthLabel.text = twoDigitIntegerFormatter.stringFromNumber(components.month)
        saleDayLabel.text = twoDigitIntegerFormatter.stringFromNumber(components.day)
        
        
        // ** SALE DETAILS
        
        // * Fixed string components
        let saleOfLocalizedString = NSLocalizedString("Sales Journal VC:sale of", comment: "Sale of ")
        let sharesLocalizedString = NSLocalizedString("Sales Journal VC:shares", comment: "shares")
        let atLocalizedString = NSLocalizedString("Sales Journal VC:at", comment: "\nat")
        let gainLocalizedString = NSLocalizedString("Sales Journal VC:gain", comment: "\nGain:")
        let lossLocalizedString = NSLocalizedString("Sales Journal VC:loss", comment: "\nLoss:")
        
        
        // * Variable string components
        
        let numberOfSharesSoldText = "\(sale.numberOfSharesSold)"
        let sellingSharePriceFormattedText = decimalFormatter.stringFromNumber(sale.sellingSharePrice)!
        
        // Does not include the gain or loss value
        var salesText = "\(saleOfLocalizedString)\(numberOfSharesSoldText) \(sharesLocalizedString) \(sale.symbol)\(atLocalizedString)\(sellingSharePriceFormattedText) \(sale.currency)"
        
        // Gain or loss value (attributed)
        var gainOrLossValueString = decimalFormatter.stringFromNumber(fabs(sale.gainOrLossValue))! + " \(GlobalSettings.sharedStore.portfolioCurrency)"
        
        var attGainOrLossValue: NSAttributedString
        let boldAttributes = [ NSFontAttributeName : UIFont.boldSystemFontOfSize(16.0) ]
        
        if sale.gainOrLossValue >= 0 {
            saleDetailLabel.textColor = UIColor.zenGreenColor()
            salesText += gainLocalizedString
            gainOrLossValueString = "+ " + gainOrLossValueString
            attGainOrLossValue = NSAttributedString(string: gainOrLossValueString, attributes:boldAttributes)
            
        } else {
            saleDetailLabel.textColor = UIColor.zenRedColor()
            salesText += lossLocalizedString // loss
            gainOrLossValueString = "- " + gainOrLossValueString
            attGainOrLossValue = NSAttributedString(string: gainOrLossValueString, attributes:boldAttributes)
        }
        
        // * Concatenate the attributed strings
        var attSalesText = NSMutableAttributedString(string: salesText)
        attSalesText.appendAttributedString(attGainOrLossValue)
        
        saleDetailLabel.attributedText = attSalesText
        saleDetailLabel.highlightedTextColor = UIColor.darkGrayColor()

    }
}