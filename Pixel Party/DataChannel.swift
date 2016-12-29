//
//  DataChannel.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/29/16.
//  Based on https://raw.githubusercontent.com/googlecast/CastHelloText-ios/master/HelloTextGoogleCastSwift/TextChannel.swift
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import Foundation
import GoogleCast
import SwiftyJSON

// This custom channel class extends GCKCastChannel.
class DataChannel : GCKCastChannel {
    static let sharedInstance = DataChannel(namespace: "urn:x-cast:com.rofreg.Pixel-Party")
    
    override func didConnect() {
        super.didConnect()
        
        let jsonBlob = JSON(["url": "http://192.168.1.167:9080/"]).rawString()!
        sendTextMessage(jsonBlob, error: nil)
    }
    
    override func didReceiveTextMessage(_ message: String) {
        super.didReceiveTextMessage(message)
        
        print("Chromecast said: \(message)")
    }
}
