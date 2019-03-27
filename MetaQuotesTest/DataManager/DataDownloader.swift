//
//  DataDownloader.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 25/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import Foundation

protocol DataDownloaderDelegate: class {
    func dataDownloaderRecievedNewData(downloader: DataDownloader, data: Data, completion: @escaping ()->())
    func dataDownloaderFinished(downloader: DataDownloader, error: Error?)
}

class DataDownloader: NSObject, URLSessionDataDelegate {
    
    weak var delegate: DataDownloaderDelegate?
    
    let  queue = OperationQueue()
    var dataTask: URLSessionDataTask?
    func start(url: URL) {
        queue.maxConcurrentOperationCount = 1
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
        dataTask = session.dataTask(with: URLRequest(url: url))
        dataTask!.resume()
    }
    
    func cancel() {
        dataTask?.cancel()
    }
    
    //MARK: URLSessionDataDelegate methods
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        queue.isSuspended = true
        DispatchQueue.global().async {
            self.delegate?.dataDownloaderRecievedNewData(downloader: self, data: data, completion: {
                self.queue.isSuspended = false
            })
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("Downloading finished successfully")
        self.delegate?.dataDownloaderFinished(downloader: self, error: nil)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("Downloading canceled")
        self.delegate?.dataDownloaderFinished(downloader: self, error: error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.delegate?.dataDownloaderFinished(downloader: self, error: error)
        error == nil ? print("Download finished") : print("Download error or canceled")
    }
    
}
