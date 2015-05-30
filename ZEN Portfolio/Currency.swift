//
//  Currencies.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class Currency {
    
    /** Currency symbol, according to the ISO currency codification */
    let symbol: String
    let description: String
    let flagImageName: String
    
    init(symbol: String, description: String, imageName: String) {
        self.symbol = symbol
        self.description = description
        self.flagImageName = imageName
    }
    
}
