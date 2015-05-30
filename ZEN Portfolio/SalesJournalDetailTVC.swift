//
//  SalesJournalDetailTVC.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 11/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


class SalesJournalDetailTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Public properties
    var sale: Sale! {
        didSet {
            
            var currency = sale?.currency
            // Special case for GBX (0,01 GBP)
            if currency == "GBX" { currency = "GBP" }
            
            if currency == GlobalSettings.sharedStore.portfolioCurrency {
                
                sections = [
                    Section(type: .General, items: [.NumberOfShares, .DatePurchase, .DateSale]),
                    Section(type: .Price, items: [.PricePurchase, .PriceSale]),
                    Section(type: .Valuation, items: [.ValuationPurchase, .ValuationSale]),
                    Section(type: .GainOrLoss, items: [.GainOrLossValue, .GainOrLossPercentage])
                ]
                
            } else { // currency != GlobalSettings.sharedStore.portfolioCurrency
                
                sections = [
                    Section(type: .General, items: [.NumberOfShares, .DatePurchase, .DateSale]),
                    Section(type: .Price, items: [.PricePurchase, .PriceSale]),
                    Section(type: .CurrencyRate, items: [.CurrencyRatePurchase, .CurrencyRateSale]),
                    Section(type: .Valuation, items: [.ValuationPurchase, .ValuationSale]),
                    Section(type: .GainOrLoss, items: [.GainOrLossValue, .GainOrLossPercentage])
                ]
            }
            
            if isViewLoaded() {
                // Update the UI
                updateView()
            }
        }
    }
    
    private var sections = [Section]()
    
    // MARK: Private struct and enum
    private struct Section {
        var type: SectionType
        var items: [Item]
    }
    
    private enum SectionType {
        case General
        case Price
        case CurrencyRate
        case Valuation
        case GainOrLoss
    }
    
    private enum Item {
        case NumberOfShares
        case DatePurchase
        case DateSale
        case PricePurchase
        case PriceSale
        case CurrencyRatePurchase
        case CurrencyRateSale
        case ValuationPurchase
        case ValuationSale
        case GainOrLossValue
        case GainOrLossPercentage
    }
    

    
    // MARK: Private properties
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    
    // Decimal formatter for Share price (2 fraction digits)
    private let sharePriceFormatter: NSNumberFormatter = {
        var decimalFormatter = NSNumberFormatter()
        decimalFormatter.numberStyle = .DecimalStyle
        decimalFormatter.minimumFractionDigits = 2
        decimalFormatter.maximumFractionDigits = 2
        decimalFormatter.locale = NSLocale.currentLocale()
        return decimalFormatter
    }()
    
    // Decimal formatter for Currency rate (4 fraction digits)
    private let currencyRateFormatter: NSNumberFormatter = {
        var rateFormatter = NSNumberFormatter()
        rateFormatter.numberStyle = .DecimalStyle
        rateFormatter.minimumFractionDigits = 4
        rateFormatter.maximumFractionDigits = 4
        rateFormatter.locale = NSLocale.currentLocale()
        return rateFormatter
    }()
    
    // Percentage formatter for Gain or loss % (2 fraction digits)
    private let percentageFormatter: NSNumberFormatter = {
        var percentFormatter = NSNumberFormatter()
        percentFormatter.numberStyle = .PercentStyle
        percentFormatter.minimumFractionDigits = 2
        percentFormatter.maximumFractionDigits = 2
        percentFormatter.locale = NSLocale.currentLocale()
        return percentFormatter
    }()
    
    // Date formatter
    private let dateFormatter: NSDateFormatter = {
        var formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()

    
    // MARK: View controller life cycle
    
    func updateView() {
        // Title
        title = NSLocalizedString("Sales Detail VC:title", comment: "Sales Details")

        tableView.reloadData()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // SEGMENTED CONTROL
        self.segmentedControl.momentary = true
        
        // Update view
        updateView()
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // SEGMENTEDCONTROL buttons enabled
        if SalesJournal.sharedStore.allEntries.count <= 1 { // if there is 0 or 1 entry, no neeed for a segmented control
            segmentedControl.hidden = true
            segmentedControl.enabled = false
            
        } else {
            // Disable "up" arrow for first stock item
            if sale === SalesJournal.sharedStore.allEntries.first {
                segmentedControl.setEnabled(false, forSegmentAtIndex:0)
            }
            // Disable "down" arrow for last stock item
            if sale === SalesJournal.sharedStore.allEntries.last {
                segmentedControl.setEnabled(false, forSegmentAtIndex:1)
            }
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Google Analytics
        setAnalyticsScreenName("Sale Detail")
    }

    
    
    // MARK: Custom methods
    @IBAction func segmentAction(sender: UISegmentedControl) {
        
        // The segmented control was clicked, handle it here
        
        // NB: sale can be unwrapped because the SegmentedControl is deactivated if there is no sale
        if let currentIndex = find(SalesJournal.sharedStore.allEntries, sale!) {
            
            if sender.selectedSegmentIndex == 0 { // "up" segment
                sale = SalesJournal.sharedStore.allEntries[currentIndex - 1]
                
                if currentIndex == 1 { // second entry -> first entry
                    segmentedControl.setEnabled(false, forSegmentAtIndex:0) // won't be able to go one up
                    segmentedControl.setEnabled(true, forSegmentAtIndex:1)  // will be able to go one down
                    // Reload table content
                    tableView.reloadData()
                   
                } else {
                    segmentedControl.setEnabled(true, forSegmentAtIndex:0) // will be able to go one up
                    segmentedControl.setEnabled(true, forSegmentAtIndex:1) // will be able to go one down
                    // Reload table content
                    tableView.reloadData()
                }
                
            } else if sender.selectedSegmentIndex == 1 { // "down" segment
                let numberOfArrayEntries = SalesJournal.sharedStore.allEntries.count
                sale = SalesJournal.sharedStore.allEntries[currentIndex + 1]
                
                if currentIndex == numberOfArrayEntries - 2 { // last but one entry -> last entry
                    segmentedControl.setEnabled(true, forSegmentAtIndex:0)  // will be able to go one up
                    segmentedControl.setEnabled(false, forSegmentAtIndex:1) // won't be able to go one down
                    // Reload table content
                    tableView.reloadData()
                } else {
                    segmentedControl.setEnabled(true, forSegmentAtIndex:0) // will be able to go one up
                    segmentedControl.setEnabled(true, forSegmentAtIndex:1) // will be able to go one down
                    // Reload table content
                    tableView.reloadData()
                }
            }
        }
    }

    
    // MARK: Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        
        var currency = sale.currency
        // Special case for GBX (0,01 GBP)
        if currency == "GBX" { currency = "GBP" }
        
        switch sections[section].type {
            
        case .General:
            return (sale.name != nil) ? "\(sale.symbol) - \(sale.name!)" : "\(sale.symbol)"
        case .Price:
            let sectionLocalizedString = NSLocalizedString("Detail VC:section share price", comment: "Share price")
            return "\(sectionLocalizedString) (\(sale.currency))"
        case .CurrencyRate:
            let sectionLocalizedString = NSLocalizedString("Detail VC:section currency rate", comment: "Currency rate")
            return "\(sectionLocalizedString) (\(GlobalSettings.sharedStore.portfolioCurrency)/\(currency))"
        case .Valuation:
            let sectionLocalizedString = NSLocalizedString("Detail VC:section stock valuation", comment: "Stock valuation")
            return "\(sectionLocalizedString) (\(GlobalSettings.sharedStore.portfolioCurrency))"
        case .GainOrLoss:
            return NSLocalizedString("Detail VC:section gain or loss", comment: "Gain or loss")
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("SaleDetailCell", forIndexPath: indexPath) as! UITableViewCell
        
        // Default cell text formatting
        cell.textLabel?.textColor = UIColor.blackColor()
        cell.detailTextLabel?.textColor = UIColor.zenGrayTextColor()
        
        // Disable cell selection
        cell.selectionStyle = .None
        
        switch sections[indexPath.section].items[indexPath.row] {
        
        case .NumberOfShares:
            cell.textLabel?.text = NSLocalizedString("Detail VC:number of shares", comment: "Number of shares")
                cell.detailTextLabel?.text = "\(sale.numberOfSharesSold)"

        case .DatePurchase:
            cell.textLabel?.text = NSLocalizedString("Stock Purchase VC:purchase date", comment: "Purchase date")
                if sale.purchaseDate != nil {
                    cell.detailTextLabel?.text = dateFormatter.stringFromDate(sale.purchaseDate!)
                } else {
                    cell.detailTextLabel?.text = "?"
                }

        case .DateSale:
            cell.textLabel?.text = NSLocalizedString("Stock Sell VC:sale date", comment: "Sale date")
                cell.detailTextLabel?.text = dateFormatter.stringFromDate(sale.saleDate)
            
        case .PricePurchase:
        cell.textLabel?.text = NSLocalizedString("Detail VC:purchase share price", comment: "Purchase share price")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(sale.purchaseSharePrice)
        case .PriceSale:
        cell.textLabel?.text = NSLocalizedString("Sales Detail VC:selling share price", comment: "Selling share price")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(sale.sellingSharePrice)
        
            
        case .CurrencyRatePurchase:
                cell.textLabel?.text = NSLocalizedString("Detail VC:purchase currency rate", comment: "Purchase currency rate")
                cell.detailTextLabel?.text = currencyRateFormatter.stringFromNumber(sale.purchaseCurrencyRate)

        case .CurrencyRateSale:
                cell.textLabel?.text = NSLocalizedString("Sales Detail VC:selling currency rate", comment: "Selling currency rate")
                cell.detailTextLabel?.text = currencyRateFormatter.stringFromNumber(sale.sellingCurrencyRate)
            
        case .ValuationPurchase:
            cell.textLabel?.text = NSLocalizedString("Detail VC:cost of stock", comment: "Purchase value")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(sale.purchaseValue)

        case .ValuationSale:
                cell.textLabel?.text = NSLocalizedString("Sales Detail VC:selling value", comment: "Selling value")
                cell.detailTextLabel?.text = sharePriceFormatter.stringFromNumber(sale.sellingValue)
        
        case .GainOrLossValue:
                cell.textLabel?.text = NSLocalizedString("Detail VC:gain or loss value", comment: "Gain or loss value")
                if let formattedGainOrLossValueString = sharePriceFormatter.stringFromNumber(sale.gainOrLossValue) {
                    if sale.gainOrLossValue > 0 {
                        cell.detailTextLabel?.text = "\(GlobalSettings.sharedStore.portfolioCurrency) +\(formattedGainOrLossValueString)"
                        cell.detailTextLabel?.textColor = UIColor.zenGreenColor()
                    } else {
                        cell.detailTextLabel?.text = "\(GlobalSettings.sharedStore.portfolioCurrency) \(formattedGainOrLossValueString)"
                        cell.detailTextLabel?.textColor = UIColor.zenRedColor()
                    }
                }

        case .GainOrLossPercentage:
                cell.textLabel?.text = NSLocalizedString("Detail VC:gain or loss percentage", comment: "Gain or loss percentage")
                if let formattedGainOrLossPercentageString = percentageFormatter.stringFromNumber(sale.gainOrLossPercentage) {
                    if sale.gainOrLossPercentage > 0 {
                        cell.detailTextLabel?.text = "+\(formattedGainOrLossPercentageString)"
                        cell.detailTextLabel?.textColor = UIColor.zenGreenColor()
                    } else {
                        cell.detailTextLabel?.text = formattedGainOrLossPercentageString
                        cell.detailTextLabel?.textColor = UIColor.zenRedColor()
                    }
                }
            
        }
        return cell
    }

    
}