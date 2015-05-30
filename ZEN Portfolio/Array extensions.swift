//
//  Array extensions.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 07/07/2014.
//  Copyright (c) 2014 Frédéric ADDA. All rights reserved.
//

import Foundation

extension Array {
    
    var firstElement: T! {
    if !isEmpty {
        return self[0]
        }
        return nil
    }
    
    var lastElement: T! {
    if !isEmpty {
        return self[count - 1]
        }
        return nil
    }
    
}