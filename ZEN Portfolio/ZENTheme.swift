//
//  ZENTheme.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 16/06/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import UIKit

enum ZENTheme: Int
{
    case Void = 0, Stone, Orchidia, Forest, Sand, Sunrise, Sunset, Water
    
    var name: String {
        switch self {
        
        case .Void:
            return "Void"
        
        case .Stone:
            return "Stone"
        
        case .Orchidia:
            return "Orchidia"
        
        case .Forest:
            return "Forest"
        
        case .Sand:
            return "Sand"
        
        case .Sunrise:
            return "Sunrise"
        
        case .Sunset:
            return "Sunset"
        
        case .Water:
            return "Water"
        }
    }
    
    func gradientColorForBaseValue(value: CGFloat) -> UIColor {
        switch self {
        case .Void:
            return UIColor.whiteColor()
    
        case .Stone:
            // Red:(val + 0.3) green:(val + 0.4) blue:(val + 0.5) alpha:0.3

            // Same color with alpha = 1
            return UIColor( red:(142.0 + 150.0 * value)/255.0,
                            green:(155.0 + 150.0 * value)/255.0,
                            blue:(167.0 + 150.0 * value)/255.0,
                            alpha:1.0)
            
        case .Orchidia:
            // Red:(val + 0.5) green:(val + 0.2) blue:(val + 0.5) alpha:0.3
            
            // Same color with alpha = 1
            return UIColor( red:(160.0 + 160.0 * value)/255.0,
                            green:(128.0 + 160.0 * value)/255.0,
                            blue:(166.0 + 160.0 * value)/255.0,
                            alpha:1.0)
            
        case .Forest:
            // Red:(val + 0.1) green:(val + 0.3) blue:(val + 0.2) alpha:0.3
            
            // Same color with alpha = 1
            return UIColor( red:(132.0 + 140.0 * value)/255.0,
                            green:(157.0 + 140.0 * value)/255.0,
                            blue:(144.0 + 140.0 * value)/255.0,
                            alpha:1.0)
            
        case .Sand:
            // Red:(val + 0.6) green:(val + 0.6) blue:(val + 0.5) alpha:0.3
            
            // Same color with alpha = 1
            return UIColor( red:(197.0 + 130.0 * value)/255.0,
                            green:(197.0 + 130.0 * value)/255.0,
                            blue:(183.0 + 130.0 * value)/255.0,
                            alpha:1.0)
            
        case .Sunrise:
            // Red:(val + 0.3) green:(val + 0.3) blue:(val/2 + 0.4) alpha:0.3
            
            // Same color with alpha = 1
            return UIColor( red:(157.0 + 130.0 * value)/255.0,
                            green:(157.0 + 130.0 * value)/255.0,
                            blue:(171.0 + 130.0 * value/2)/255.0,
                            alpha:1.0)
            
        case .Sunset:
            // Red:(val + 0.4) green:(val + 0.3) blue:(val + 0.5) alpha:0.3
            
            // Same color with alpha = 1
            return UIColor( red:(169.0 + 140.0 * value)/255.0,
                            green:(155.0 + 140.0 * value)/255.0,
                            blue:(181.0 + 140.0 * value)/255.0,
                            alpha:1.0)
            
        case .Water:
            // Red:(val + 0.2) green:(val + 0.2) blue:(val + 0.7) alpha:0.25
            
            // Same color with alpha = 1
            return UIColor( red:(160.0 + 110.0 * value)/255.0,
                            green:(160.0 + 110.0 * value)/255.0,
                            blue:(210.0 + 090.0 * value)/255.0,
                            alpha:1.0)
            
            
        default: // default = Stone
            return UIColor( red:(142.0 + 150.0 * value)/255.0,
                            green:(155.0 + 150.0 * value)/255.0,
                            blue:(167.0 + 150.0 * value)/255.0,
                            alpha:1.0)
        }
    }
    
    func iconsColor() -> UIColor {
        switch self {
        case .Void, .Stone:
            return UIColor.zenStoneColor()
            
        case .Orchidia:
            return UIColor.zenOrchidiaColor()
            
        case .Forest:
            return UIColor.zenForestColor()
            
        case .Sand:
            return UIColor.zenSandColor()
            
        case .Sunrise:
            return UIColor.zenSunriseColor()
            
        case .Sunset:
            return UIColor.zenSunsetColor()
            
        case .Water:
            return UIColor.zenWaterColor()
            
        default:
            return UIColor.zenStoneColor()
            
        }
    }
    
    func themeSeparatorInset() -> UIEdgeInsets {
        switch self {
        case .Void:
            return UIEdgeInsetsMake(0, 15, 0, 0)
            
        default:
            return UIEdgeInsetsZero
        }
    }
}