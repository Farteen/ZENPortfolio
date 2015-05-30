//
//  StockConnection.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 19/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//


import UIKit

class StockConnection {
    
    // MARK: Public properties
    var request: NSURLRequest
    var session: NSURLSession
    var completionClosure: ((object: JSONStockDetailRootObject?, error: NSError?) -> ())?
    var jsonRootObject: JSONStockDetailRootObject?
    
    // MARK: Private properties
    private let BackgroundFetchTimeOut: NSTimeInterval = 30 // seconds
    
    // MARK: Functions
    init(request: NSURLRequest) {
        self.request = request
        
        var config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = BackgroundFetchTimeOut
        self.session = NSURLSession(configuration:config)
    }
    
    func start() {
        // Start network activity indicator
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var dataTask = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) in
            
            if error == nil {
                // Convert received data to JSON
                let httpResp = response as! NSHTTPURLResponse
                
                if httpResp.statusCode == 200 {
                    var jsonError: NSError?
                    
                    // If you received a 200 response, then convert the data into JSON using iOS built-in JSON deserialization
                    // Turn JSON data into basic model objects
                    let dictionary = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments, error:&jsonError) as! NSDictionary
                    
                    if jsonError == nil { // No Json parsing error
                        
                        // Have the root object construct itself from basic model objects
                        if let jsonRootObject = self.jsonRootObject {
                            jsonRootObject.readFromJSONDictionary(dictionary)
                            
                            // Then, pass the root object to the completion closure
                            // - this is the closure that the controller supplied.
                            if let existingCompletionClosure = self.completionClosure {
                                existingCompletionClosure(object: jsonRootObject, error: nil)
                            }
                            
                            // update the UI in the main thread
                            dispatch_async(dispatch_get_main_queue(), {
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            })
                        }
                        
                    } else { // JSON error exists (can be implicitely unwrapped)
                        // Pass the error from the connection to the completion closure
                        if let existingCompletionClosure = self.completionClosure {
                            existingCompletionClosure(object: nil, error: jsonError!)
                        }
                    }
                    
                } else { // HTTP bad response
                    // Other HTTP response than 200
                    println("HTTP error : \(httpResp.statusCode)")
                    let httpLocalizedError = NSLocalizedString("HTTP bad response", comment: "HTTP bad response")
                    
                    let httpErrorDetail = [ NSLocalizedDescriptionKey : httpLocalizedError + String(httpResp.statusCode) ]
                    let httpError = NSError(domain:"HTTP Error", code:httpResp.statusCode, userInfo:httpErrorDetail)
                    
                    if let existingCompletionClosure = self.completionClosure {
                        existingCompletionClosure(object: nil, error: httpError)
                    }
                }
                
            } else { // Data task error
                // Pass the error from the connection to the completion closure
                if let existingCompletionClosure = self.completionClosure {
                    existingCompletionClosure(object: nil, error: error)
                }
            }
            
            // update the UI in the main thread
            dispatch_async(dispatch_get_main_queue(), {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            
        })
        
        // a task defaults to a suspended state, so you need to call the resume method to start it running
        dataTask.resume()
        
    }
    
}