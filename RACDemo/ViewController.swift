//
//  ViewController.swift
//  RACDemo
//
//  Created by apple2 on 16/3/1.
//  Copyright © 2016年 shiyuwudi. All rights reserved.
//

import UIKit
import ReactiveCocoa

let apikey = "000888ad4ab1d462b654a75fdccbca4d"
let firstUrl = "http://apis.baidu.com/songshuxiansheng/real_time/search_news"


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var dataArray = [JSON]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let searchStrings = textField.rac_textSignal()
            .toSignalProducer()
            .map { text in text as! String }
        let searchResults = searchStrings
            .flatMap(.Latest) { (query: String) -> SignalProducer<(NSData, NSURLResponse), NSError> in
                let URLRequest = self.searchRequestWithEscapedQuery(query)
                return NSURLSession.sharedSession()
                    .rac_dataWithRequest(URLRequest)
                    .retry(2)
                    .flatMapError { error in
                        print("Network error occurred: \(error)")
                        return SignalProducer.empty
                }
            }
            .map { (data, URLResponse) -> JSON in
                let string = String(data: data, encoding: NSUTF8StringEncoding)!
                return self.parse(string)
            }
            .observeOn(UIScheduler())
        searchResults.startWithNext { bigJson in
            self.dataArray.removeAll()
            let arr = bigJson["retData"]["data"].arrayValue
            for smallJson in arr {
                self.dataArray.append(smallJson)
            }
            self.tableView.reloadData()
        }
        
    }
    
    func searchRequestWithEscapedQuery(var keyword:String) -> NSURLRequest {
        keyword = keyword.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        guard let url = NSURL(string: "\(firstUrl)?keyword=\(keyword)&page=1&count=20") else {
            return NSURLRequest()
        }
        let req = NSMutableURLRequest(URL: url)
        req.HTTPMethod = "GET"
        req.setValue(apikey, forHTTPHeaderField: "apikey")
        return req
    }
    
    func parse(jsonStr:String) -> JSON {
        let json = JSON.parse(jsonStr)
        return json
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value2, reuseIdentifier: "123")
        let json = dataArray[indexPath.row]
        cell.textLabel?.text = json["title"].stringValue
        cell.detailTextLabel?.text = json["abstract"].stringValue
        return cell
    }


}

