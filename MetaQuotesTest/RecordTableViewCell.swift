//
//  RecordTableViewCell.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 25/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import Foundation
import UIKit

class RecordTableViewCell: UITableViewCell {
    var resultString: ResultString? {
        didSet {
            self.textLabel?.text = resultString?.text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textLabel?.numberOfLines = 0
    }
}
