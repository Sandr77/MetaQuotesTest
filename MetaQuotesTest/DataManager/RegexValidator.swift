//
//  RegexValidator.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 27/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import Foundation

class RegexValidator {
    class func validate(string: String, regex: String, exact: Bool = false) -> Bool {
        var text = ""
        var minSymbols = 0
        var manySymbols = false
        var position = 0
        for c in regex {
            if text.count == 0 {
                if c == "*" {
                    manySymbols = true
                }
                else if c == "?" {
                    minSymbols += 1
                }
                else {
                    text += String(c)
                }
            }
            else {
                if c != "*" && c != "?" {
                    text += String(c)
                }
                else {
                    break
                }
            }
            position += 1
        }
        if text.count == 0 {
            if manySymbols  {
                if minSymbols > string.count {
                    return false
                }
                return true
            }
            return minSymbols == string.count
        }
        
        let range = (string as NSString).range(of: text)
        if range.location == NSNotFound {
            return false
        }
        var flagOk = false
        if minSymbols <= range.location {
            if manySymbols {
                flagOk = true
            }
            else if minSymbols == range.location {
                flagOk = true
            }
        }
        if flagOk == false && exact == true {
            return false
        }
        
        let newString = (string as NSString).substring(from: range.location + range.length)
        let newRegex = (regex as NSString).substring(from: position)
        if flagOk {
            return RegexValidator.validate(string: newString, regex: newRegex, exact: true) || RegexValidator.validate(string: newString, regex: regex)
        }
        
        return RegexValidator.validate(string: newString, regex: regex)
    }
    
    
}
