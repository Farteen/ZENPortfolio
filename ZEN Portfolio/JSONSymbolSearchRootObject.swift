//
//  JSONSymbolSearchRootObject.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 17/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class JSONSymbolSearchRootObject : JSONSerializableProtocol {
    
    // Public property
    var symbols = [Stock]()
    
    // MARK: JSON parsing methods
    
    func readFromJSONDictionary(dictionary: NSDictionary) {
        
        // The top-level object contains a "ResultSet" dictionary
        let resultSet = dictionary["ResultSet"] as! NSDictionary
        
        if resultSet.count > 0 {
            // The ResultSet dictionary has an array of results, for each one, update the properties
            let result = resultSet["Result"] as! Array<NSDictionary>
            
            for entry in result {
                
                let symbol = entry["symbol"] as! String
                let name = entry["name"] as! String
                let type = entry["type"] as! String
                
                if type == "I" { // Exclude entries corresponding to type "Index"
                    println("Symbol: \(symbol) Type = Index! Excluded from list")
                    
                } else {
                    
                    if let market = entry["exchDisp"] as? String {
                        
                        // The entry is complete : create a Stock item
                        var stock = Stock(symbol: symbol, name: name, market: market as String, currency: "")
                        println("-Symbol: \(stock.symbol) - Market: \(stock.market) - type: \(type)")
                        symbols.append(stock)
                        
                    } else {
                        // Exclude entries without a market (because Yahoo won't give quotes if there is no market)
                        println("Symbol: \(symbol) No market! Excluded from list")
                    }
                }
            }
        }
    }
}