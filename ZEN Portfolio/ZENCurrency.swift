//
//  Currencies.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENCurrency: NSCoding {
    
    /** Currency symbol, according to the ISO currency codification */
    let symbol: String
    let description: String
    let flagImageName: String
    
    init(symbol: String, description: String, imageName: String) {
        self.symbol = symbol
        self.description = description
        self.flagImageName = imageName
    }
    
    // MARK: NSCoding
    init(coder aDecoder: NSCoder) {
        symbol = aDecoder.decodeObjectForKey("symbol") as String
        description = aDecoder.decodeObjectForKey("description") as String
        flagImageName = aDecoder.decodeObjectForKey("flagImageName") as String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(symbol, forKey:"symbol")
        aCoder.encodeObject(description, forKey:"description")
        aCoder.encodeObject(flagImageName, forKey:"flagImageName")
    }
}
