//
//  AirplayViewController.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/29/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import UIKit

class AirplayViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load a full-screen WebView to display a URL
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let webView = UIWebView(frame: appDelegate.secondaryWindow!.frame)
        webView.backgroundColor = UIColor.red
        webView.loadRequest(URLRequest(url: URL(string: ServerInstance.url!)!))
        view.addSubview(webView)
    }
}
