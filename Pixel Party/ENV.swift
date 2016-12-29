//
//  ENV.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/29/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import Foundation

func ENV(_ keyname:String) -> Any? {
    let filePath = Bundle.main.path(forResource: "ENV", ofType:"plist")
    let plist = NSDictionary(contentsOfFile:filePath!)
    
    return plist?.object(forKey: keyname)
}
