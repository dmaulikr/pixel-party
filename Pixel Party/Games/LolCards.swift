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
    
    override func start(){
        updateScoreboard([
            "currentScreen": [
                "screenType": ScoreboardViewType.static.rawValue,
                "content": "<strong>Let's play LOLCards!</strong>"
            ]
        ])
        
        updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.static.rawValue,
                "content": "<strong>Let's play LOLCards!</strong>"
            ]
        ])
        
        // Start a timer
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(LolCards.showQuestion), userInfo: nil, repeats: true)
        }
        // Can be cancelled with self.timer?.invalidate()
    }
    
    func showQuestion() {
        self.updatePlayers([
            "currentScreen": [
                "screenType": PlayerViewType.text.rawValue,
                "prompt": "Say something funny",
                "placeholder": "Blah blah blah"
            ]
        ])
    }
    
    override func messageReceived(fromPlayer player: String, message: JSON) {
        // Update scoreboard(s) with the received value
        // TODO: for submitted values, support data types other than String
        if let value = message["value"].string {
            updateScoreboard([
                "currentScreen": [
                    "screenType": ScoreboardViewType.static.rawValue,
                    "content": "<b>Value:</b><br><br>\(value)"  // TODO: HTML escaping
                ]
            ])
        }
        
        // For the player, for now, wait 2 seconds and then generate a new page
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let responses = [
                [
                    "currentScreen": [
                        "screenType": PlayerViewType.multipleChoice.rawValue,
                        "prompt": "What's your favorite color?",
                        "choices": [
                            ["value": "0", "title": "Blue"],
                            ["value": "1", "title": "Red"],
                        ]
                    ]
                ],
                [
                    "currentScreen": [
                        "screenType": PlayerViewType.text.rawValue,
                        "prompt": "Who's your best friend?"
                    ]
                ],
                [
                    "currentScreen": [
                        "screenType": PlayerViewType.static.rawValue,
                        "content": "<b>testing!<br><br>score: 20</b>",
                        "todo": "some kind of optional button to continue?"
                    ]
                ]
            ]
            
            let randomResponse = responses[Int(arc4random_uniform(UInt32(responses.count)))]
            self.update(player, message: randomResponse)
        }
    }
}
