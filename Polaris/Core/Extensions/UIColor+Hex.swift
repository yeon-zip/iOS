//
//  UIColor+Hex.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
