//
//  UIConfig.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/9.
//

import Foundation
import UIKit

struct UIConfig {
    static let depthPicWidth = 480 * scale
    static let depthPicHeight = 640 * scale
    static let scale = 1.2
    static var error: Float?
    static let screenWidth = UIScreen.main.bounds.width
    static let mainViewSpacing: CGFloat = 20
}
