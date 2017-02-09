//
//  PollGame.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/30/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import Foundation
import SwiftyJSON

enum PollGameMode {
    case prompt
    case vote
    case result
}

class PollGame: Game {
    var prompt: String? = nil
    var answers: [String: String] = [:]
    var votes: [String: Int] = [:]
    var points: [String: Int] = [:]
    var mode: PollGameMode = .prompt
    
    let textPrompts = ["What's your favorite animal?", "What's your favorite color?"]
    let imagePrompts = ["Show everyone a big smile!", "Show everyone a vacation photo"]
    
    override func start(){
        // run in a separate thread, so that we can sleep if we wish
        DispatchQueue.global(qos: .background).async {
            
            while (true){
                self.showWelcome()
                Thread.sleep(forTimeInterval: 3)
                
                // Initialize points
                self.points = [:]
                self.players.forEach{ self.points[$0] = 0 }
                
                for turn in 1...4 {
                    self.answers = [:]
                    self.votes = [:]
                    
                    if (turn % 2 == 0){
                        self.mode = .prompt
                        self.showTextPrompt()
                        self.showScoreboardCountdown(5)
                        while (self.answers.count < self.players.count){
                            Thread.sleep(forTimeInterval: 1)
                        }
                        
                        self.mode = .vote
                        self.showChoices()
                        self.showScoreboardCountdown(5)
                    } else {
                        self.mode = .prompt
                        self.showImagePrompt()
                        self.showScoreboardCountdown(5)
                        while (self.answers.count < self.players.count){
                            Thread.sleep(forTimeInterval: 1)
                        }
                        
                        self.mode = .vote
                        self.showImages()
                        self.showScoreboardCountdown(10)
                    }
                    
                    self.mode = .result
                    self.showResult()
                    Thread.sleep(forTimeInterval: 5)
                }
            }
            
            // TODO: show who won the whole game
            // TODO: return to lobby
        }
    }
    
    func showScoreboardCountdown(_ countdownLength: Int) {
        for secondsLeft in (0...countdownLength).reversed() {
            updateScoreboard([
                "currentScreen": [
                    "screenType": ScoreboardViewType.static.rawValue,
                    "content": "Time left: \(secondsLeft)"
                ]
            ])
            Thread.sleep(forTimeInterval: 1)
        }
    }
    
    func showWelcome(){
        updateScoreboard([
            "currentScreen": [
                "screenType": ScoreboardViewType.static.rawValue,
                "content": "Let's play the poll game!"
            ]
        ])
        
        updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.static.rawValue,
                "content": "Let's play the poll game!"
            ]
        ])
    }
    
    func showTextPrompt() {
        prompt = textPrompts.sample()
        
        self.updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.text.rawValue,
                "prompt": prompt,
                "placeholder": "Enter your answer"
            ]
        ])
    }
    
    func showImagePrompt() {
        prompt = imagePrompts.sample()
        
        self.updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.picture.rawValue,
                "prompt": prompt,
                "placeholder": "Enter your answer"
            ]
        ])
    }
    
    func showChoices() {
        let choices = answers.map { key, value in
            return ["value": key, "title": value]
        }
        
        self.updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.multipleChoice.rawValue,
                "prompt": "Pick your favorite answer",
                "choices": choices
            ]
        ])
    }
    
    func showImages() {
        let imagesHtml = answers.map { key, value in
            return "\(key): <img src='\(value)'>"
        }.joined(separator: "<br>")

        self.updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.static.rawValue,
                "content": imagesHtml
            ]
        ])
    }
    
    func showResult() {
        // TODO: show who actually won
        // TODO: record who actually won (e.g. add it to the total points)
        
        let result = votes.map{ key, value in
            return "\(key): \(value)"
        }.joined(separator: "<br>")
        
        updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.static.rawValue,
                "content": "The votes were:<br>\(result)",
            ]
        ])
        
        updateScoreboard([
            "currentScreen": [
                "screenType": PlayerViewType.static.rawValue,
                "content": "The votes were:<br>\(result)",
            ]
        ])
    }
    
    override func messageReceived(fromPlayer player: String, message: JSON) {
        // Update scoreboard(s) with the received value
        guard let value = message["value"].string else {
            return
        }
        
        if self.mode == .prompt {
            answers[player] = value
        } else if self.mode == .vote {
            votes[value] = (votes[value] == nil ? 1 : votes[value]! + 1)
        }
    }
}
