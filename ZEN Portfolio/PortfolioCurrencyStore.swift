//
//  PortfolioCurrencyStore.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 10/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//



class PortfolioCurrencyStore {
    
    // MARK: Singleton
    static let sharedStore = PortfolioCurrencyStore()

    
    // MARK: Properties
    
    /** Array of all currencies (symbol, description, flagImageName) allowed allowed as a portfolio currency */
    let allCurrencies = [
        Currency(symbol:"ARS", description:"Argentine Peso",     imageName:"Argentina-flag.png"),
        Currency(symbol:"AUD", description:"Australian Dollar",  imageName:"Australia-flag.png"),
        Currency(symbol:"BGN", description:"Bulgarian Lev",      imageName:"Bulgaria-flag.png"),
        Currency(symbol:"BOB", description:"Bolivian Boliviano", imageName:"Bolivia-flag.png"),
        Currency(symbol:"BRL", description:"Brazilian Real",     imageName:"Brazil-flag.png"),
        Currency(symbol:"CAD", description:"Canadian Dollar",    imageName:"Canada-flag.png"),
        Currency(symbol:"CHF", description:"Swiss Franc",        imageName:"Switzerland-flag.png"),
        Currency(symbol:"CLP", description:"Chilean Peso",       imageName:"Chile-flag.png"),
        Currency(symbol:"CNY", description:"Chinese Yuan",       imageName:"China-flag.png"),
        Currency(symbol:"COP", description:"Colombian Peso",     imageName:"Colombia-flag.png"),
        Currency(symbol:"CRC", description:"Costa Rica Colon",   imageName:"Costa-Rica-flag.png"),
        Currency(symbol:"CZK", description:"Czech Koruna",       imageName:"Czech-Republic-flag.png"),
        Currency(symbol:"DKK", description:"Danish Krone",       imageName:"Denmark-flag.png"),
        Currency(symbol:"ECS", description:"Ecuador Sucre",      imageName:"Ecuador-flag.png"),
        Currency(symbol:"EEK", description:"Estonian Kroon",     imageName:"Estonia-flag.png"),
        Currency(symbol:"EUR", description:"Euro",               imageName:"European-Union-flag.png"),
        Currency(symbol:"GBP", description:"British Pound",      imageName:"United-Kingdom-flag.png"),
        Currency(symbol:"GTQ", description:"Guatemala Quetzal",  imageName:"Guatemala-flag.png"),
        Currency(symbol:"HKD", description:"Hong Kong Dollar",   imageName:"Hong-Kong-flag.png"),
        Currency(symbol:"HRK", description:"Croatian Kuna",      imageName:"Croatia-flag.png"),
        Currency(symbol:"HUF", description:"Hungarian Forint",   imageName:"Hungary-flag.png"),
        Currency(symbol:"IDR", description:"Indonesian Rupiah",  imageName:"Indonesia-flag.png"),
        Currency(symbol:"ILS", description:"Israeli Shekel",     imageName:"Israel-flag.png"),
        Currency(symbol:"INR", description:"Indian Rupee",       imageName:"India-flag.png"),
        Currency(symbol:"ISK", description:"Iceland Krona",      imageName:"Iceland-flag.png"),
        Currency(symbol:"JMD", description:"Jamaican Dollar",    imageName:"Jamaica-flag.png"),
        Currency(symbol:"JPY", description:"Japanese Yen",       imageName:"Japan-flag.png"),
        Currency(symbol:"KRW", description:"South Korean Won",   imageName:"Korea-flag.png"),
        Currency(symbol:"LTL", description:"Lithuanian Lita",    imageName:"Lithuania-flag.png"),
        Currency(symbol:"LVL", description:"Latvian Lat",        imageName:"Latvia-flag.png"),
        Currency(symbol:"MAD", description:"Moroccan Dirham",    imageName:"Morocco-flag.png"),
        Currency(symbol:"MDL", description:"Moldovan Leu",       imageName:"Moldova-flag.png"),
        Currency(symbol:"MTL", description:"Maltese Lira",       imageName:"Malta-flag.png"),
        Currency(symbol:"MXN", description:"Mexican Peso",       imageName:"Mexico-flag.png"),
        Currency(symbol:"NIO", description:"Nicaragua Cordoba",  imageName:"Nicaragua-flag.png"),
        Currency(symbol:"NOK", description:"Norwegian Krone",    imageName:"Norway-flag.png"),
        Currency(symbol:"NZD", description:"New-Zealand Dollar", imageName:"New-Zealand-flag.png"),
        Currency(symbol:"PAB", description:"Panama Balboa",      imageName:"Panama-flag.png"),
        Currency(symbol:"PEN", description:"Peruvian Nuevo Sol", imageName:"Peru-flag.png"),
        Currency(symbol:"PLN", description:"Polish Zloty",       imageName:"Poland-flag.png"),
        Currency(symbol:"PYG", description:"Paraguayan Guarani", imageName:"Paraguay-flag.png"),
        Currency(symbol:"RON", description:"Romanian New Leu",   imageName:"Romania-flag.png"),
        Currency(symbol:"RUB", description:"Russian Rouble",     imageName:"Russia-flag.png"),
        Currency(symbol:"SEK", description:"Swedish Krona",      imageName:"Sweden-flag.png"),
        Currency(symbol:"SGD", description:"Singapore Dollar",   imageName:"Singapore-flag.png"),
        Currency(symbol:"SIT", description:"Slovenian Tolar",    imageName:"Slovenia-flag.png"),
        Currency(symbol:"SKK", description:"Slovak Koruna",      imageName:"Slovakia-flag.png"),
        Currency(symbol:"THB", description:"Thai Baht",          imageName:"Thailand-flag.png"),
        Currency(symbol:"TRY", description:"Turkish Lira",       imageName:"Turkey-flag.png"),
        Currency(symbol:"TWD", description:"Taiwan Dollar",      imageName:"Taiwan-flag.png"),
        Currency(symbol:"UAH", description:"Ukraine Hryvnia",    imageName:"Ukraine-flag.png"),
        Currency(symbol:"USD", description:"United States Dollar", imageName:"United-States-flag.png"),
        Currency(symbol:"UYU", description:"Uruguayan New Peso", imageName:"Uruguay-flag.png"),
        Currency(symbol:"ZAR", description:"South African Rand", imageName:"South-Africa-flag.png")
    ]
    
    /** Array of all currency symbols allowed as a portfolio currency */
    var allCurrencySymbols: Array<String> {
    var symbolsArray = [String]()
        for currency in allCurrencies {
            symbolsArray.append(currency.symbol)
        }
        return symbolsArray
    }
    
}
