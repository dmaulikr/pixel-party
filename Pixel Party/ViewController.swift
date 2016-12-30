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

enum PlayerViewType: String {
    case `static` = "STATIC"
    case text = "TEXT"
    case multipleChoice = "MULTIPLE_CHOICE"
}

enum ScoreboardViewType: String {
    case `static` = "STATIC"
    case scoreboard = "SCOREBOARD"
}
    
class ViewController: UIViewController {
    @IBOutlet var outputView: UIWebView!
    @IBOutlet var joinGameLabel: UILabel!
    @IBOutlet var airplayButton: MPVolumeView!
    
    var server = HttpServer() // Must keep a reference to the server to keep it running
    var scoreboards: [WebSocketSession] = []
    var players: Dictionary<String, WebSocketSession> = [:]
    var currentGame: Game? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up AirPlay button
        airplayButton.showsRouteButton = true
        airplayButton.showsVolumeSlider = false
        updateAirplayButton()
        
        // Update AirPlay visibility when available routes change
        NotificationCenter.default.addObserver(self, selector:(#selector(ViewController.updateAirplayButton)), name:NSNotification.Name.MPVolumeViewWirelessRoutesAvailableDidChange, object:nil)
        
        setUpServer()
        setUpClient()
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
                        "screenType": "LOBBY",
                        "gameInProgress": self.currentGame != nil
                    ]
                ])
                session.writeText(response.rawString()!)
                
                // Also update all scoreboards
                let usersData = self.players.map({ (player: (username: String, session: WebSocketSession)) -> [String: Any] in
                    return ["username": player.username]
                })
                let scoreboardUpdate = JSON(["users": usersData])
                
                for scoreboard in self.scoreboards {
                    scoreboard.writeText(scoreboardUpdate.rawString()!)
                }
            } else if action == "START_GAME" && self.currentGame == nil {
                self.currentGame = LolCards(players: Array(self.players.keys), delegate: self)
                self.currentGame?.start()
            } else if action == "SUBMIT" && self.currentGame != nil {
                // TODO: figure out who this message is actually from
                self.currentGame?.messageReceived(fromPlayer: self.players.keys.first!, message: json)
            } else {
                // Idk what happened, better not change anything on the client side
            }
        }, { (session, binary) in
            session.writeBinary(binary)
        })
        
        try! server.start(ENV("Port") as! UInt16)
    }
    
    
    // MARK: Local client logic
    
    func setUpClient(){
        // Display the server URL in the app
        updateJoinGameLabel()
        
        // Load the player view in the app
        outputView.loadRequest(URLRequest(url: URL(string: ServerInstance.baseUrl!)!))
    }
    
    func updateJoinGameLabel(){
        guard let gameUrl = ServerInstance.baseUrl else {
            joinGameLabel.text = "An error occurred that prevented\nthe server from starting."
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
    
    func updateAirplayButton(){
        // Hide the AirPlay button unless there are actual AirPlay devices
        airplayButton.isHidden = !airplayButton.areWirelessRoutesAvailable
    }
}

extension ViewController: GameDelegate {
    func updateScoreboards(_ message: Dictionary<String, Any>){
        let jsonMessage = JSON(message).rawString()!
        for scoreboard in scoreboards {
            scoreboard.writeText(jsonMessage)
        }
    }
    
    func update(_ player: String, message: Dictionary<String, Any>){
        // TODO
        let jsonMessage = JSON(message).rawString()!
        for (_, playerSession) in players {
            playerSession.writeText(jsonMessage)
        }
    }
}
