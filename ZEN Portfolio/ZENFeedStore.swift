//
//  ZENFeedStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 17/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENFeedStore {
    
    // MARK: Singleton
    // TODO: class var sharedStore = ZENFeedStore()
    class func sharedStore() -> ZENFeedStore! {
    struct Static {
        static var instance: ZENFeedStore?
        static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ZENFeedStore()
        }
        
        return Static.instance!
    }
    
    /*! Method to get stock quotes from Yahoo!Finance database. This method creates a NSURL combining a (rather complex) YQL query and the requested mnemonic codes. Then it creates a connection to get the data, and provides a completion block.
    * \param symbols An array of stocks symbols to fetch from Yahoo! Finance database.
    * \param completion A closure object to be executed when the fetch ends. This closure has no return value and takes 2 arguments : a JSONStockDetailObject containing the stocks details of the provided symbols, and an error code.
    */
    func fetchStockQuotes(symbols: Array<String>, completion:(JSONStockDetailRootObject?, NSError?)->()) {

        // This process is based on a CSV file fetched from Yahoo! Finance, transformed into JSON by a YQL query.
        
        /*  YQL Query, replace SYMBOLS by symbols to update
        
        http://query.yahooapis.com/v1/public/yql?
        q=select * from csv where url='http://download.finance.yahoo.com/d/quotes.csv?s="SYMBOLS"&f=sl1d1t1c1p2&e=.csv'
        and columns='symbol,price,date,time,changeValue,changePercentage'&format=json&diagnostics=true&callback=
        
        s  = Symbol
        l1 = Last Trade (Price Only)
        d1 = Last Trade Date
        t1 = Last Trade Time
        c1 = Change in Value
        p2 = Change in Percent
        
        */
        
        /* Full escaped link :
        http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20csv%20where%20url%3D'http%3A%2F%2Fdownload.finance.yahoo.com%2Fd%2Fquotes.csv%3Fs%3DEURUSD=X%2BAAPL%26f%3Dsl1d1t1c1p2%26e%3D.csv'%20and%20columns%3D'symbol%2Cprice%2Cdate%2Ctime%2CchangeValue%2CchangePercentage'&format=json&diagnostics=true&callback=
        */
        
        
        // STEP 1 : Fetch the CSV from Yahoo! Finance
        /*
        'http://download.finance.yahoo.com/d/quotes.csv?s="SYMBOLS"&f=sl1d1t1c1p2&e=.csv'
        (replace SYMBOLS with array of symbols)
        (NB : this string must already be HTML-encoded as it will be part of the super string query)
        */
        var csvString = String.htmlEncodingForURLString("'http://download.finance.yahoo.com/d/quotes.csv?s=")
        
        // Symbols separated by + (only character to get HTML-encoding, because currency rates - like EURUSD=X - should not be encoded)
        csvString += NSArray(array: symbols).componentsJoinedByString("%2B")
        
        csvString += String.htmlEncodingForURLString("&f=sl1d1t1c1p2&e=.csv'")
        
        
        // STEP 2 : Transform the CSV into a JSON file using YQL Query
        /*
        select * from csv where url=CSV and columns='symbol,price,date,time,changeValue,changePercentage'
        (replace CSV with URL for the csv file)
        (NB : this string also must already be HTML-encoded as it will be part of the super string query)
        */
        var yqlString = String.htmlEncodingForURLString("select * from csv where url=")
                        + csvString
                        + String.htmlEncodingForURLString(" and columns='symbol,price,date,time,changeValue,changePercentage'")
        
        
        // STEP 3 : Full URL string
        /*
        http://query.yahooapis.com/v1/public/yql?q=QUERY&format=json&diagnostics=true&callback=
        (replace QUERY with YQL Query)
        */
        var urlComponents = NSURLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "query.yahooapis.com"
        urlComponents.path = "/v1/public/yql"
        urlComponents.percentEncodedQuery = "q=" + yqlString + "&format=json&diagnostics=true&callback=" // already encoded !
        
        let url = urlComponents.URL
        
        let request = NSURLRequest(URL:url)
        
        // Create an empty channel
        var stockRootObject = JSONStockDetailRootObject()
        
        // Create a connection "actor" object that will transfer data from the server
        var connection = ZENStockConnection(request:request)
        
        // When the connection completes, this closure from the controller will be called
         connection.completionClosure = completion
        
        // Let the empty channel parse the returning data from the web service
        connection.jsonRootObject = stockRootObject
        
        // Begin the connection
        connection.start()

    }
    

    /*! Method to get a list of symbols corresponding to the search string from Yahoo!Finance database, with minimum information (name, symbol, market). This method creates a NSURL as expected by Yahoo!Finance API, including search code. Then it creates a connection to get the data, and provides a completion block.
    * \param searchString The search string to fetch from Yahoo! Finance database.
    * \param completion A closure object to be executed when the fetch ends. This closure has no return value and takes 2 arguments : a search string, and an error code.
    */
    func searchStockSymbol(searchString: String, completion:(JSONSymbolSearchRootObject?, NSError?) -> ()) {
        
        /* Full escaped link :
        http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=AAPL&callback=YAHOO.Finance.SymbolSuggest.ssCallback
        */
        
        var urlComponents = NSURLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "d.yimg.com"
        urlComponents.path = "/autoc.finance.yahoo.com/autoc"
        urlComponents.query = "query=" + searchString + "&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
        
        let url = urlComponents.URL
        
        let request = NSURLRequest(URL:url)
        
        // Create an empty channel
        var symbolRootObject = JSONSymbolSearchRootObject()
        
        // Create a connection "actor" object that will transfer data from the server
        var connection = ZENSymbolConnection(request:request)
        
        // When the connection completes, this closure from the controller will be called
        connection.completionClosure = completion
        
        // Let the empty channel parse the returning data from the web service
        connection.jsonRootObject = symbolRootObject
        
        // Begin the connection
        connection.start()
    }

    
}
