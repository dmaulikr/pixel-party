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
    
    var scoreboard: Dictionary<String, Any> = [:] {
        didSet { self.updateScoreboardInstances() }
    }
    var scoreboardInstances: [WebSocketSession] = []
    
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
            // For testing, print all messages to the console
            print(text)
            
            let data = text.data(using: String.Encoding.utf8)
            var json = JSON(data: data!)
            let action = json["action"].string
            let clientType = json["clientType"].string
            
            if clientType == "scoreboard" {
                // If initializing, add this scoreboard to our list of scoreboards
                if action == "INIT" {
                    self.scoreboardInstances.append(session)
                }
                
                // Return current scoreboard contents
                session.writeText(JSON(self.scoreboard).rawString()!)
                return
            }
            
            // Otherwise, we're talking to an individual player
            if action == "INIT" {
                let response = JSON([
                    "currentScreen": [
                        "screenType": "LOBBY",
                        "gameInProgress": self.currentGame != nil
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
                
                // Update all scoreboards, make sure they know about the new users
                self.updateScoreboardInstances()
            } else if action == "START_GAME" && self.currentGame == nil {
                self.currentGame = LolCards(players: Array(self.players.keys), delegate: self)
                self.currentGame?.start()
            } else if action == "SUBMIT" && self.currentGame != nil {
                if let playerName = self.players.key(forValue: session) {
                    self.currentGame?.messageReceived(fromPlayer: playerName, message: json)
                }
            } else {
                // Idk what happened, better not change anything on the client side
            }
        }, { (session, binary) in
            session.writeBinary(binary)
        })
        
        try! server.start(ENV("Port") as! UInt16)
    }
    
    func updateScoreboardInstances(){
        // Update all scoreboardInstances with the latest information
        var scoreboardInstanceUpdate = self.scoreboard
        
        // Automatically include information about all players
        scoreboardInstanceUpdate["users"] = self.players.map({ (player: (username: String, session: WebSocketSession)) -> [String: Any] in
            return ["username": player.username]
        })
        
        // Send that info to all individual scoreboard instances
        let jsonMessage = JSON(scoreboardInstanceUpdate).rawString()!
        for scoreboardInstance in scoreboardInstances {
            scoreboardInstance.writeText(jsonMessage)
        }
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
    func update(_ player: String, message: Dictionary<String, Any>){
        let jsonMessage = JSON(message).rawString()!
        players[player]?.writeText(jsonMessage)
    }
}

extension Dictionary where Value: Equatable {
    func key(forValue val: Value) -> Key? {
        return self.filter{ $1 == val }.first?.key
    }
}
