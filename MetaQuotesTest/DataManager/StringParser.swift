//
//  StringParser.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 25/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import Foundation

class StringParser {
    private var previousChunk = ""
    var regex = ""
    func parse(_ string: String) -> [String] {
        var result = [String]()
        let arr = (previousChunk + string).components(separatedBy: "\n")
        if arr.count == 1 {
            previousChunk += string
            return result
        }
        result.append(contentsOf: arr[0..<(arr.count - 1)])
        result = result.filter{RegexValidator.validate(string: $0, regex: regex)}
        previousChunk = arr.last!
        return result
    }
    
    func getLastString() -> String? {
        return RegexValidator.validate(string: previousChunk, regex: regex) ? previousChunk : nil
    }
}
