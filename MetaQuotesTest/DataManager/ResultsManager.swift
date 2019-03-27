//
//  ResultsManager.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 25/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import Foundation
import UIKit

struct ResultString {
    var row: Int
    var text: String
    var fileOffset: UInt64
    init(row: Int, text: String, fileOffset: UInt64) {
        self.row = row
        self.text = text
        self.fileOffset = fileOffset
    }
}

protocol ResultManagerDelegate: class {
    func resultManagerLoadedNewResults(_ manager: ResultsManager)
    func resultManagerFinishedLoading(errorString: String?)
}

class ResultsManager: DataDownloaderDelegate {
    private init() {}
    static let shared = ResultsManager()
    
    weak var delegate: ResultManagerDelegate?
    
    var numberOfLoadedStrings = 0
    var finishedLoading = false
    var bufferedResults = ResultsBuffer()
    
    private var fileHandlerRead: FileHandle?
    private var fileHandlerWrite: FileHandle?

    private var path = NSHomeDirectory() + "/\(ResultsFilename)"
    private var dataDownloader: DataDownloader?
    private var parser: StringParser?
    
    private func checkFile() -> Bool {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        path = paths[0].path + "/\(ResultsFilename)"
        fileHandlerRead?.closeFile()
        fileHandlerWrite?.closeFile()
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            }
            catch {
                return false
            }
        }
        let result = FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        
        return result
    }
    
    func start(url: URL, regex: String, delegate: ResultManagerDelegate) -> Bool {
        dataDownloader?.cancel()
        dataDownloader?.delegate = nil
        dataDownloader = DataDownloader()

        guard checkFile() else {
            return false
        }
        do {
            fileHandlerRead = try FileHandle.init(forReadingFrom: URL.init(fileURLWithPath: path))
         }
        catch {
            return false
        }
        self.delegate = delegate
        fileHandlerWrite = FileHandle.init(forWritingAtPath: path)

 
        numberOfLoadedStrings = 0
        finishedLoading = false
        parser = StringParser()
        parser?.regex = regex
        bufferedResults.clear()
        bufferedResults.fileHandler = fileHandlerRead
        dataDownloader?.delegate = self
        dataDownloader?.start(url: url)
        
        return true
    }
    
    func stop() {
        dataDownloader?.cancel()
    }
    
    private func appendNewStrings(_ strings: [String]) {
        var offset: UInt64?
        var exception = tryBlock {
            offset = self.fileHandlerWrite!.offsetInFile
        }
        if exception != nil {
            DispatchQueue.main.async {
                self.delegate?.resultManagerFinishedLoading(errorString: "Error with write file handler")
            }
            dataDownloader?.cancel()
            return
        }
        var resStrings = [ResultString]()
        for s in strings {
            let resStr = ResultString(row: numberOfLoadedStrings, text: s, fileOffset: offset!)
            resStrings.append(resStr)
            numberOfLoadedStrings += 1
            exception = tryBlock {
                let data = (s + "\n").data(using: .ascii)
                self.fileHandlerWrite!.write(data!)
            }
            if exception != nil {
                DispatchQueue.main.async {
                    self.delegate?.resultManagerFinishedLoading(errorString: "Failed saving to log file")
                }
                dataDownloader?.cancel()
                break
            }
            offset = offset! + UInt64(s.count + 1)
        }
        bufferedResults.append(resStrings)
    }
    
    //MARK: DataDownloader delegate methods
    
    func dataDownloaderRecievedNewData(downloader: DataDownloader, data: Data, completion: @escaping ()->()) {
        let failBlock = {
            print("Parsing data failed")
            self.stop()

            DispatchQueue.main.async {
                self.delegate?.resultManagerFinishedLoading(errorString: "Parsing data failed. Probably it's not an ANSI file")
            }
        }
        if let string = String.init(data: data, encoding: .ascii) {
            print("downloaded data of size ", data.count)
            if string.data(using: .ascii) == nil {
                failBlock()
            }
            else {
                let foundStrings = parser!.parse(string)
                if foundStrings.count > 0 {
                    self.appendNewStrings(foundStrings)
                    print("found strings " + String(foundStrings.count))
                    DispatchQueue.main.async {
                        self.delegate?.resultManagerLoadedNewResults(self)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                            completion()
                        })
                    }
                }
                else {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
        else {
            failBlock()
        }
        
    }
    
    func dataDownloaderFinished(downloader: DataDownloader, error: Error?) {
        self.finishedLoading = true
        if let lastStr = parser?.getLastString() {
            self.appendNewStrings([lastStr])
        }
        DispatchQueue.main.async {
            self.delegate?.resultManagerFinishedLoading(errorString: error?.localizedDescription)
        }
    }
    
}

