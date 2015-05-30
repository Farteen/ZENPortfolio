//
//  String extensions.swift
//  ZEN Portfolio
//
//  Created by Frédéric ADDA on 01/03/2015.
//  Copyright (c) 2015 Frédéric ADDA. All rights reserved.
//

extension String {
    
    /** Allow for subscript */
    subscript (i: Int) -> String {
        return String(Array(self)[i])
    }
    
    /** Allow for subscript with variadic parameter */
    subscript (r: Range<Int>) -> String {
        get {
            let subStart = advance(self.startIndex, r.startIndex, self.endIndex)
            let subEnd = advance(subStart, r.endIndex - r.startIndex, self.endIndex)
            return self.substringWithRange(Range(start: subStart, end: subEnd))
        }
    }

    
}