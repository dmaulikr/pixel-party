//
//  Game.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/30/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import Foundation
import SwiftyJSON

class Game {
    let players: [String]
    var delegate: GameDelegate
    
    init(players: [String], delegate: GameDelegate) {
        self.players = players
        self.delegate = delegate
    }
    
    func start(){
        fatalError("Subclasses must implement start()")
    }
    
    func messageReceived(fromPlayer player: String, message: JSON){
        fatalError("Subclass must handle messages in some way")
    }
    
    func updatePlayers(_ message: Dictionary<String, Any>){
        for player in players {
            delegate.update(player, message: message)
        }
    }
    
    func updateScoreboard(_ message: Dictionary<String, Any>){
        delegate.scoreboard = message
    }
    
    func update(_ player: String, message: Dictionary<String, Any>){
        delegate.update(player, message: message)
    }
}

protocol GameDelegate {
    var scoreboard: Dictionary<String, Any> { get set }
    func update(_ player: String, message: Dictionary<String, Any>)
}
