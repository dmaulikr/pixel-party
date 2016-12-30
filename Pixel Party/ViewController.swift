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
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
    @IBOutlet var outputView: UIWebView!
    @IBOutlet var joinGameLabel: UILabel!
    @IBOutlet var airplayButton: MPVolumeView!
    
    var server = HttpServer() // Must keep a reference to the server to keep it running
    var scoreboards: [WebSocketSession] = []
    var players: Dictionary<String, WebSocketSession> = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up AirPlay button
        airplayButton.showsRouteButton = true
        airplayButton.showsVolumeSlider = false
        updateAirplayButton()
        
        // Update AirPlay visibility when available routes change
        NotificationCenter.default.addObserver(self, selector:(#selector(ViewController.updateAirplayButton)), name:NSNotification.Name.MPVolumeViewWirelessRoutesAvailableDidChange, object:nil)
        
        setJoinGameLabel()
        setUpServer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: Game URL generation
    
    func setJoinGameLabel(){
        guard let gameUrl = ServerInstance.baseUrl else {
            joinGameLabel.text = "An error occurred that prevented the server from starting."
            return
        }
        
        // Assemble the two lines of the "join game" label
        let attributedString = NSMutableAttributedString(string: "To join the game, go to:\n",
                                                         attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12)])
        let serverAddress = NSMutableAttributedString(string: gameUrl,
                                                      attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)])
        attributedString.append(serverAddress)
        
        // Make them center-aligned and increase line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .center
        attributedString.addAttribute(
            NSParagraphStyleAttributeName,
            value: paragraphStyle,
            range: NSMakeRange(0, attributedString.length)
        )
        
        // Display the result
        joinGameLabel.attributedText = attributedString
        
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
        server["/scoreboard"] = { (request: HttpRequest) -> HttpResponse in
            guard let indexPage = try? String(contentsOfFile:(Bundle.main.resourcePath! + "/Public/scoreboard.html"), encoding: String.Encoding.utf8) else {
                return .notFound
            }
            
            return .ok(.html(indexPage))
        }
        server["/javascripts/:path"] = shareFilesFromDirectory(Bundle.main.resourcePath! + "/Public/javascripts")
        server["/sounds/:path"] = shareFilesFromDirectory(Bundle.main.resourcePath! + "/Public/sounds")
        server["/stylesheets/:path"] = shareFilesFromDirectory(Bundle.main.resourcePath! + "/Public/stylesheets")
        
        // WebSocket functionality
        server["/socket"] = websocket({ (session, text) in
            // For testing, print all inputs to the mobile screen
            DispatchQueue.main.async {
                print(text)
                // self.outputView.loadHTMLString(text, baseURL: nil)
            }
            
            let data = text.data(using: String.Encoding.utf8)
            var json = JSON(data: data!)
            let action = json["action"].string
            
            if action == "INIT" {
                if json["clientType"] == "scoreboard" {
                    self.scoreboards.append(session)
                    return
                }
                
                let response = JSON([
                    "currentScreen": [
                        "screenType": "LOBBY"
                    ]
                ])
                session.writeText(response.rawString()!)
            } else if let username = json["username"].string, action == "JOIN" {
                // If there is an existing session for this username, replace it
                if let _ = self.players[username] {
                    // TODO: fix bug when trying to reconnect from a disconnected client
                    // This is a workaround - the player has to try to re-join twice, but it works
                    self.players.removeValue(forKey: username)
                    return
                }
                self.players[username] = session
                
                let response = JSON([
                    "username": username,
                    "joined": true,
                    "currentScreen": [
                        "screenType": "LOBBY"
                    ]
                ])
                session.writeText(response.rawString()!)
            } else if action == "START_GAME" {
//                let response = JSON([
//                    "currentScreen": [
//                        "screenType": "STATIC",
//                        "content": "<b>testing!<br><br>score: 20</b>"
//                    ]
//                ])
                let response = JSON([
                    "currentScreen": [
                        "screenType": "TEXT",
                        "prompt": "What's your favorite color?"
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
        
        outputView.loadRequest(URLRequest(url: URL(string: ServerInstance.baseUrl!)!))
        
        // Update scoreboards every few seconds
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(ViewController.updateScoreboards), userInfo: nil, repeats: true)
    }
    
    func updateScoreboards(){
        for scoreboard in scoreboards {
            let usersData = players.map({ (player: (username: String, session: WebSocketSession)) -> [String: Any] in
                return ["username": player.username]
            })
            let response = JSON(["users": usersData])
            scoreboard.writeText(response.rawString()!)
        }
    }

//    func ping(){
//        for (username, session) in openSessions {
//            let response = JSON(["heartbeat": Int(arc4random())])
//            session.writeText(response.rawString()!)
//            print("\(NSDate()): Pinging \(username)")
//        }
//    }
    
    func updateAirplayButton(){
        airplayButton.isHidden = !airplayButton.areWirelessRoutesAvailable
    }
}
