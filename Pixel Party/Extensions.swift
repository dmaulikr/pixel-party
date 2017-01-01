//
//  Extensions.swift
//  Pixel Party
//
//  Created by Ryan Laughlin on 1/1/17.
//  Copyright © 2017 Ryan Laughlin. All rights reserved.
//

import Foundation

extension Array {
    func sample() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}
