//
//  ResultsBuffer.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 25/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import Foundation
import UIKit

class ResultsBuffer {
    private var results = [ResultString]()
    
    private var fromRow = 0
    private var toRow = 0
   
    var count: Int {
        get {
            return results.count
        }
    }
    var totalNumberOfStrings = 0
    var fileHandler: FileHandle?

    func clear() {
        results = Array()
        fromRow = 0
        toRow = 0
        totalNumberOfStrings = 0
    }
    
    func resultForRow(_ row: Int) -> ResultString? {
        
        if row >= fromRow && row <= toRow {
            return results[row - fromRow]
        }
        else {
            if row < fromRow {
                self.readBefore()
                if row < fromRow {
                    return nil
                }
                else {
                    return results[row - fromRow]
                }
            }
            else {
                self.readAfter()
                if row > toRow {
                    return nil
                }
                else {
                    return results[row - fromRow]
                }
            }
        }
    }
    
    func append(_ arr: [ResultString]) {
        if arr.isEmpty {
            return
        }
        let lastRow = toRow
        let toAppend = arr.filter{abs($0.row - lastRow) < MaxDelta}
        if toAppend.count > 0 {
            DispatchQueue.main.sync {
                if toRow == 0 || toRow == toAppend.first!.row - 1{
                    results.append(contentsOf: toAppend)
                    toRow = toAppend.last!.row
                }
            }
         }
        totalNumberOfStrings = arr.last!.row + 1
    }
    
    func clearOldStrings(current: Int, fromBeginnig: Bool) {
        if current - fromRow > MaxDelta && fromBeginnig {
            results.removeAll(where: {$0.row < current - MaxDelta})
            fromRow = results.first!.row
        }
        else if toRow - current > MaxDelta && fromBeginnig == false {
            results.removeAll(where: {$0.row > current + MaxDelta})
            toRow = results.last!.row
        }
    }
    
    func readBefore() {
        let str = results.first!
        if str.row == 0 {
            return
        }
        var newPosition: UInt64!
        var bytesToRead = BufferBytesToReadFromLog
        if str.fileOffset < BufferBytesToReadFromLog - 1 {
            newPosition = 0
            bytesToRead = str.fileOffset
        }
        else {
            newPosition = str.fileOffset - (BufferBytesToReadFromLog)
        }
        
        var newStrings = [ResultString]()

        fileHandler!.seek(toFileOffset: newPosition)
        if let data = fileHandler?.readData(ofLength: Int(bytesToRead)) {
            let content = String.init(data: data, encoding: .ascii)
            let components = content!.components(separatedBy: "\n")
            if components.count > 1 {
                var curOffset = str.fileOffset - 1
                for i in 0..<(components.count - (newPosition == 0 ? 1 : 2)) {  //skipping last and first (if not start of file)
                    let s = components[components.count - i - 2]
                    curOffset -= UInt64(s.count)
                    let newString = ResultString.init(row: str.row - (i + 1), text: s, fileOffset: curOffset)
                    newStrings.insert(newString, at: 0)
                    if curOffset > 0 {
                        curOffset -= 1
                    }
                }
            }
        }
        results.insert(contentsOf:newStrings, at: 0)
        fromRow = results.first!.row
        clearOldStrings(current: str.row, fromBeginnig: false)
        
    }
    
    func readAfter() {
        let str = results.last!
        if str.row >= totalNumberOfStrings - 1 {
            return
        }
        var newStrings = [ResultString]()
        
        var curOffset = str.fileOffset + UInt64(str.text.count + 1)
        fileHandler!.seek(toFileOffset: curOffset)
        if let data = fileHandler?.readData(ofLength: Int(BufferBytesToReadFromLog)) {
            let content = String.init(data: data, encoding: .ascii)
            let components = content!.components(separatedBy: "\n")
            
            for i in 0..<(components.count - 1) {
                let s = components[i]
                let newString = ResultString.init(row: str.row + (i + 1), text: s, fileOffset: curOffset)
                curOffset += (UInt64(s.count) + 1)
                newStrings.append(newString)
            }
            results.append(contentsOf: newStrings)
            toRow = results.last!.row
            if fileHandler!.offsetInFile == fileHandler!.seekToEndOfFile() {
                let newString = ResultString.init(row: toRow + 1, text: components.last!, fileOffset: curOffset)
                results.append(newString)
                toRow += 1
            }
        }
        clearOldStrings(current: str.row, fromBeginnig: true)
        
    }
    
}
