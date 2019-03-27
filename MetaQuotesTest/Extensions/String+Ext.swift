//
//  String+Ext.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 27/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import Foundation

extension String {
    func isANSI() -> Bool {
        if self.count == 0 {
            return true
        }
        guard let cstring = self.cString(using: .ascii) else {
            return false
        }
        if cstring.count - 1 != self.count {
            return false
        }
        for c in cstring[0...(cstring.count - 2)] {
            if Int(c) < 32 || Int(c) > 126 {
                return false
            }
        }
        return true
    }
}
