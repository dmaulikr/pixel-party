//
//  Player.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/31/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import UIKit
import Swifter

class Player {
    var username: String
    var color: String
    var session: WebSocketSession
    
    init(username: String, color: String, session: WebSocketSession) {
        self.username = username
        self.color = color
        self.session = session
    }
    
    func toDictionary() -> Dictionary<String, Any> {
        return [
            "username": username,
            "color": color
        ]
    }
}
