//
//  UIColor+Hex.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 12/29/16.
//  Copyright © 2016 Ryan Laughlin. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex:Int) {
        self.init(red:(hex >> 16) & 0xff, green:(hex >> 8) & 0xff, blue:hex & 0xff)
    }
    
    // based on https://pbs.twimg.com/media/CuV6mBNXYAEYGPj.jpg:large
    static let palette = [UIColor(hex:0x140b1c),
                          UIColor(hex:0x452334),
                          UIColor(hex:0x2f346c),
                          UIColor(hex:0x844a32),
                          UIColor(hex:0x366226),
                          UIColor(hex:0x5d7ac9),
                          UIColor(hex:0xd14644),
                          UIColor(hex:0x87949d),
                          UIColor(hex:0x6da72c),
                          UIColor(hex:0xd5a79d),
                          UIColor(hex:0x6ec3ca),
                          UIColor(hex:0xd6d560),
                          UIColor(hex:0xdeeed1),
                          UIColor(hex:0x4f4b4d),
                          UIColor(hex:0x736f5c),
                          UIColor(hex:0xd57a25)]
}
