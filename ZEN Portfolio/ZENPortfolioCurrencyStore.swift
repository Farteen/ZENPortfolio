//
//  ZENPortfolioCurrencyStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

class ZENPortfolioCurrencyStore {
    
    // MARK: Singleton
    class func sharedStore() -> ZENPortfolioCurrencyStore! {
        struct Static {
            static var instance: ZENPortfolioCurrencyStore?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = ZENPortfolioCurrencyStore()
        }
        
        return Static.instance!
    }
    
    
    // MARK: Properties
    
    /** Array of all currencies (symbol, description, flagImageName) allowed allowed as a portfolio currency */
    let allCurrencies = [
        ZENCurrency(symbol:"ARS", description:"Argentine Peso",     imageName:"Argentina-flag.png"),
        ZENCurrency(symbol:"AUD", description:"Australian Dollar",  imageName:"Australia-flag.png"),
        ZENCurrency(symbol:"BGN", description:"Bulgarian Lev",      imageName:"Bulgaria-flag.png"),
        ZENCurrency(symbol:"BOB", description:"Bolivian Boliviano", imageName:"Bolivia-flag.png"),
        ZENCurrency(symbol:"BRL", description:"Brazilian Real",     imageName:"Brazil-flag.png"),
        ZENCurrency(symbol:"CAD", description:"Canadian Dollar",    imageName:"Canada-flag.png"),
        ZENCurrency(symbol:"CHF", description:"Swiss Franc",        imageName:"Switzerland-flag.png"),
        ZENCurrency(symbol:"CLP", description:"Chilean Peso",       imageName:"Chile-flag.png"),
        ZENCurrency(symbol:"CNY", description:"Chinese Yuan",       imageName:"China-flag.png"),
        ZENCurrency(symbol:"COP", description:"Colombian Peso",     imageName:"Colombia-flag.png"),
        ZENCurrency(symbol:"CRC", description:"Costa Rica Colon",   imageName:"Costa-Rica-flag.png"),
        ZENCurrency(symbol:"CZK", description:"Czech Koruna",       imageName:"Czech-Republic-flag.png"),
        ZENCurrency(symbol:"DKK", description:"Danish Krone",       imageName:"Denmark-flag.png"),
        ZENCurrency(symbol:"ECS", description:"Ecuador Sucre",      imageName:"Ecuador-flag.png"),
        ZENCurrency(symbol:"EEK", description:"Estonian Kroon",     imageName:"Estonia-flag.png"),
        ZENCurrency(symbol:"EUR", description:"Euro",               imageName:"European-Union-flag.png"),
        ZENCurrency(symbol:"GBP", description:"British Pound",      imageName:"United-Kingdom-flag.png"),
        ZENCurrency(symbol:"GTQ", description:"Guatemala Quetzal",  imageName:"Guatemala-flag.png"),
        ZENCurrency(symbol:"HKD", description:"Hong Kong Dollar",   imageName:"Hong-Kong-flag.png"),
        ZENCurrency(symbol:"HRK", description:"Croatian Kuna",      imageName:"Croatia-flag.png"),
        ZENCurrency(symbol:"HUF", description:"Hungarian Forint",   imageName:"Hungary-flag.png"),
        ZENCurrency(symbol:"IDR", description:"Indonesian Rupiah",  imageName:"Indonesia-flag.png"),
        ZENCurrency(symbol:"ILS", description:"Israeli Shekel",     imageName:"Israel-flag.png"),
        ZENCurrency(symbol:"INR", description:"Indian Rupee",       imageName:"India-flag.png"),
        ZENCurrency(symbol:"ISK", description:"Iceland Krona",      imageName:"Iceland-flag.png"),
        ZENCurrency(symbol:"JMD", description:"Jamaican Dollar",    imageName:"Jamaica-flag.png"),
        ZENCurrency(symbol:"JPY", description:"Japanese Yen",       imageName:"Japan-flag.png"),
        ZENCurrency(symbol:"KRW", description:"South Korean Won",   imageName:"Korea-flag.png"),
        ZENCurrency(symbol:"LTL", description:"Lithuanian Lita",    imageName:"Lithuania-flag.png"),
        ZENCurrency(symbol:"LVL", description:"Latvian Lat",        imageName:"Latvia-flag.png"),
        ZENCurrency(symbol:"MAD", description:"Moroccan Dirham",    imageName:"Morocco-flag.png"),
        ZENCurrency(symbol:"MDL", description:"Moldovan Leu",       imageName:"Moldova-flag.png"),
        ZENCurrency(symbol:"MTL", description:"Maltese Lira",       imageName:"Malta-flag.png"),
        ZENCurrency(symbol:"MXN", description:"Mexican Peso",       imageName:"Mexico-flag.png"),
        ZENCurrency(symbol:"NIO", description:"Nicaragua Cordoba",  imageName:"Nicaragua-flag.png"),
        ZENCurrency(symbol:"NOK", description:"Norwegian Krone",    imageName:"Norway-flag.png"),
        ZENCurrency(symbol:"NZD", description:"New-Zealand Dollar", imageName:"New-Zealand-flag.png"),
        ZENCurrency(symbol:"PAB", description:"Panama Balboa",      imageName:"Panama-flag.png"),
        ZENCurrency(symbol:"PEN", description:"Peruvian Nuevo Sol", imageName:"Peru-flag.png"),
        ZENCurrency(symbol:"PLN", description:"Polish Zloty",       imageName:"Poland-flag.png"),
        ZENCurrency(symbol:"PYG", description:"Paraguayan Guarani", imageName:"Paraguay-flag.png"),
        ZENCurrency(symbol:"RON", description:"Romanian New Leu",   imageName:"Romania-flag.png"),
        ZENCurrency(symbol:"RUB", description:"Russian Rouble",     imageName:"Russia-flag.png"),
        ZENCurrency(symbol:"SEK", description:"Swedish Krona",      imageName:"Sweden-flag.png"),
        ZENCurrency(symbol:"SGD", description:"Singapore Dollar",   imageName:"Singapore-flag.png"),
        ZENCurrency(symbol:"SIT", description:"Slovenian Tolar",    imageName:"Slovenia-flag.png"),
        ZENCurrency(symbol:"SKK", description:"Slovak Koruna",      imageName:"Slovakia-flag.png"),
        ZENCurrency(symbol:"THB", description:"Thai Baht",          imageName:"Thailand-flag.png"),
        ZENCurrency(symbol:"TRY", description:"Turkish Lira",       imageName:"Turkey-flag.png"),
        ZENCurrency(symbol:"TWD", description:"Taiwan Dollar",      imageName:"Taiwan-flag.png"),
        ZENCurrency(symbol:"UAH", description:"Ukraine Hryvnia",    imageName:"Ukraine-flag.png"),
        ZENCurrency(symbol:"USD", description:"United States Dollar", imageName:"United-States-flag.png"),
        ZENCurrency(symbol:"UYU", description:"Uruguayan New Peso", imageName:"Uruguay-flag.png"),
        ZENCurrency(symbol:"ZAR", description:"South African Rand", imageName:"South-Africa-flag.png")
    ]
    
    /** Array of all currency symbols allowed as a portfolio currency */
    var allCurrencySymbols: Array<String> {
    var symbolsArray = String[]()
        for currency in allCurrencies {
            symbolsArray += currency.symbol
        }
        return symbolsArray
    }
    
}
