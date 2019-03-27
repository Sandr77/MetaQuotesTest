//
//  ViewController.swift
//  MetaQuotesTest
//
//  Created by Andrey Snetkov on 25/03/2019.
//  Copyright © 2019 Andrey Snetkov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ResultManagerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var regexTextField: UITextField!
    @IBOutlet weak var startStopButton: UIButton!
    
    var currentNumberOfResults = 0
    
    private var rowHeights = [Int: CGFloat]()
    private var isLoadingNow = false
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentNumberOfResults
    }
    

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeights[indexPath.row] ?? 42
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        rowHeights[indexPath.row] = cell.bounds.size.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordTableViewCellId") as! RecordTableViewCell
        cell.resultString = ResultsManager.shared.bufferedResults.resultForRow(indexPath.row)
        
        DispatchQueue.main.async {
            self.addRowsIfPossible()
        }
        return cell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlTextField.text = ""
        urlTextField.autocorrectionType = .no
        urlTextField.autocapitalizationType = .none
        regexTextField.autocapitalizationType = .none
        regexTextField.autocorrectionType = .no
        
        tableView.register(UINib.init(nibName: "RecordTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "RecordTableViewCellId")
        tableView.rowHeight = UITableView.automaticDimension
        
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hideKeyboard))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        urlTextField.inputAccessoryView = keyboardToolbar
        regexTextField.inputAccessoryView = keyboardToolbar
        regexTextField.delegate = self
    }
    
    
    func addRowsIfPossible() {
        if let lastCellStr = (tableView.visibleCells.last as? RecordTableViewCell)?.resultString {
            if lastCellStr.row < ResultsManager.shared.numberOfLoadedStrings - 1 && lastCellStr.row > currentNumberOfResults - TableViewAddStringsNumber {
                var toAdd = ResultsManager.shared.numberOfLoadedStrings - currentNumberOfResults
                if toAdd > TableViewAddStringsNumber {
                    toAdd = TableViewAddStringsNumber
                }
                if toAdd > 0 {
                    addStrings(toAdd)
                }
            }
        }
        else {
            if currentNumberOfResults > TableViewAddStringsNumber {
                return
            }
            var toAdd = ResultsManager.shared.numberOfLoadedStrings - currentNumberOfResults
            if toAdd > TableViewAddStringsNumber {
                toAdd = TableViewAddStringsNumber
            }
            if toAdd > 0 {
                addStrings(toAdd)
            }
        }
    }
    
    func addStrings(_ number: Int) {
        var indexesToAdd = [IndexPath]()
        var c = currentNumberOfResults
        
        for _ in 0..<number {
            indexesToAdd.append(IndexPath.init(row: c, section: 0))
            c += 1
        }
        
        tableView.beginUpdates()
        currentNumberOfResults = c
        self.tableView.insertRows(at: indexesToAdd, with: .top)
        tableView.endUpdates()
    }

    @IBAction func startStopPressed() {
        if isLoadingNow {
            ResultsManager.shared.stop()
            return
        }
        hideKeyboard()
        
        guard let url = URL.init(string: urlTextField.text!) else {
            self.reportError("Please enter valid URL")
            return
        }
        currentNumberOfResults = 0
        tableView.reloadData()
        if ResultsManager.shared.start(url: url, regex: regexTextField.text!, delegate: self) == false {
            reportError("Something went wrong")
        }
        else {
            isLoadingNow = true
            startStopButton.setTitle("STOP", for: .normal)
        }
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func reportError(_ text: String) {
        let alertController = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        let okButton = UIAlertAction.init(title: "OK", style: .default, handler: {action in
            alertController.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(okButton)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: regex textfield delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.isANSI()
    }

    //MARK: ResultManagerDelegate
    
    func resultManagerLoadedNewResults(_ manager: ResultsManager) {
        addRowsIfPossible()
    }
    
    func resultManagerFinishedLoading(errorString: String?) {
        if errorString != nil {
            reportError(errorString!)
        }
        isLoadingNow = false
        startStopButton.setTitle("START", for: .normal)
    }



}

