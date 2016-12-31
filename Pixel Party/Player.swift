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
    var color: UIColor
    var session: WebSocketSession
    
    init(username: String, color: UIColor, session: WebSocketSession) {
        self.username = username
        self.color = color
        self.session = session
    }
}
