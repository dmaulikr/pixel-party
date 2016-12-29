//
//  ViewController.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/28/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import UIKit
import Swifter
import SwiftyJSON
import GoogleCast

class ViewController: UIViewController {
    @IBOutlet var outputView: UIWebView!
    @IBOutlet var joinGameLabel: UILabel!
    
    var server = HttpServer() // Must keep a reference to the server to keep it running
    var openSessions: Dictionary<String, WebSocketSession> = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setJoinGameLabel()
        setUpServer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: Game URL generation
    
    func setJoinGameLabel(){
        guard let gameUrl = gameUrl else {
            joinGameLabel.text = "An error occurred that prevented the server from starting."
            return
        }
        
        // Assemble the two lines of the "join game" label
        let attributedString = NSMutableAttributedString(string: "To join this game, go to:\n",
                                                         attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
        let serverAddress = NSMutableAttributedString(string: gameUrl,
                                                      attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16)])
        attributedString.append(serverAddress)
        
        // Make them center-aligned and increase line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center
        attributedString.addAttribute(
            NSParagraphStyleAttributeName,
            value: paragraphStyle,
            range: NSMakeRange(0, attributedString.length)
        )
        
        // Display the result
        joinGameLabel.attributedText = attributedString
        
    }
    
    var gameUrl: String? {
        guard let ipAddress = ipAddress else {
            return nil
        }
        
        return "http://\(ipAddress):\(ENV("Port")!)"
    }
    
    // Return IP address of WiFi interface (en0) as a String
    // via http://stackoverflow.com/questions/30748480/swift-get-devices-ip-address
    var ipAddress: String? {
        var address : String?
        
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    
                    // Convert interface address to a human readable string:
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        
        return address
    }
    
    
    // MARK: Server logic
    
    func setUpServer(){
        // Basic web server functionality
        server["/"] = { (request: HttpRequest) -> HttpResponse in
            guard let indexPage = try? String(contentsOfFile:(Bundle.main.resourcePath! + "/Public/index.html"), encoding: String.Encoding.utf8) else {
                return .notFound
            }
            
            return .ok(.html(indexPage))
        }
        server["/javascripts/:path"] = shareFilesFromDirectory(Bundle.main.resourcePath! + "/Public/javascripts")
        server["/stylesheets/:path"] = shareFilesFromDirectory(Bundle.main.resourcePath! + "/Public/stylesheets")
        
        // WebSocket functionality
        server["/socket"] = websocket({ (session, text) in
            // For testing, print all inputs to the mobile screen
            // DispatchQueue.main.async {
            //     self.outputView.loadHTMLString(text, baseURL: nil)
            // }
            
            let data = text.data(using: String.Encoding.utf8)
            var json = JSON(data: data!)
            let action = json["action"].string
            
            if action == "INIT" {
                let response = JSON([
                    "currentScreen": [
                        "screenType": "LOBBY"
                    ]
                    ])
                session.writeText(response.rawString()!)
            } else if let username = json["username"].string, action == "JOIN" {
                self.openSessions[username] = session
                
                let response = JSON([
                    "username": username,
                    "currentScreen": [
                        "screenType": "LOBBY"
                    ]
                    ])
                session.writeText(response.rawString()!)
            } else if action == "START_GAME" {
                let response = JSON([
                    "currentScreen": [
                        "screenType": "STATIC",
                        "content": "<b>testing!<br><br>score: 20</b>"
                    ]
                    ])
                session.writeText(response.rawString()!)
            } else {
                // Idk what happened, better not change anything on the client side
                session.writeText("{}")
            }
        }, { (session, binary) in
            session.writeBinary(binary)
        })
        
        try! server.start(ENV("Port") as! UInt16)
        
        outputView.loadRequest(URLRequest(url: URL(string: gameUrl!)!))
        
        // Ping every 5 seconds to keep connections alive
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(ViewController.ping), userInfo: nil, repeats: true)
    }
    
    func ping(){
        for (username, session) in openSessions {
            let response = JSON(["heartbeat": Int(arc4random())])
            session.writeText(response.rawString()!)
            print("\(NSDate()): Pinging \(username)")
        }
    }
}
