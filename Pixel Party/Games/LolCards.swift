//
//  LolCards.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/30/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import Foundation
import SwiftyJSON

class LolCards: Game {
    var timer: Timer? = Timer()
    var prompt: String? = nil
    var answers: [String: String] = [:]
    var votes: [String: Int] = [:]
    var points: [String: Int] = [:]
    
    let prompts = ["What is 5+5?", "Say something funny"]
    
    override func start(){
        // run in a separate thread, so that we can sleep if we wish
        DispatchQueue.global(qos: .background).async {
            self.showWelcome()
            Thread.sleep(forTimeInterval: 5)
            
            for _ in 1...5 {
                self.showPrompt()
                self.showScoreboardCountdown(10)

                self.showChoices()
                self.showScoreboardCountdown(10)
                
                self.showResult()
                Thread.sleep(forTimeInterval: 10)
            }
            
            // TODO: finish and return to lobby
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
                "content": "Let's play LOLCards!"
            ]
        ])
        
        updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.static.rawValue,
                "content": "Let's play LOLCards!"
            ]
        ])
    }
    
    func showPrompt() {
        prompt = prompts.sample()
        
        self.updatePlayers([
            "currentScreen": [
                "label": "prompt",
                "screenType": PlayerViewType.text.rawValue,
                "prompt": prompt,
                "placeholder": "Enter your answer"
            ]
        ])
    }
    
    func showChoices() {
        // TODO: use actual answers here
        
        self.updatePlayers([
            "currentScreen": [
                "label": "choice",
                "screenType": PlayerViewType.multipleChoice.rawValue,
                "prompt": "Pick your favorite answer",
                "choices": [
                    ["value": "0", "title": "Blue"],
                    ["value": "1", "title": "Red"],
                ]
            ]
        ])
    }
    
    func showResult() {
        // TODO: show who actually won
        // TODO: record who actually won (e.g. add it to the total points)
        
        updatePlayers([
            "currentScreen": [
                "label": "result",
                "screenType": PlayerViewType.static.rawValue,
                "content": "The winner was:<br>BLAH",
            ]
        ])
        
        updateScoreboard([
            "currentScreen": [
                "label": "result",
                "screenType": PlayerViewType.static.rawValue,
                "content": "The winner was:<br>BLAH",
            ]
        ])
    }
    
    override func messageReceived(fromPlayer player: String, message: JSON) {
        // Update scoreboard(s) with the received value
        // TODO: for submitted values, support data types other than String
        if let value = message["value"].string {
            answers[player] = value
//            updateScoreboard([
//                "currentScreen": [
//                    "screenType": ScoreboardViewType.static.rawValue,
//                    "content": "<b>Value:</b><br><br>\(value)"  // TODO: HTML escaping
//                ]
//            ])
        }
        
        // For the player, for now, wait 2 seconds and then generate a new page
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//            let responses = [
//                [
//                    "currentScreen": [
//                        "screenType": PlayerViewType.multipleChoice.rawValue,
//                        "prompt": "What's your favorite color?",
//                        "choices": [
//                            ["value": "0", "title": "Blue"],
//                            ["value": "1", "title": "Red"],
//                        ]
//                    ]
//                ],
//                [
//                    "currentScreen": [
//                        "screenType": PlayerViewType.text.rawValue,
//                        "prompt": "Who's your best friend?"
//                    ]
//                ],
//                [
//                    "currentScreen": [
//                        "screenType": PlayerViewType.static.rawValue,
//                        "content": "<b>testing!<br><br>score: 20</b>",
//                        "button": "some kind of optional button to continue"
//                    ]
//                ]
//            ]
//            
//            let randomResponse = responses.sample()
//            self.update(player, message: randomResponse)
//        }
    }
}
