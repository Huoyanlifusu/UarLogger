//
//  ScanConfig.swift
//  integration
//
//  Created by 张裕阳 on 2023/6/13.
//

import Foundation
import UIKit

struct ScanConfig {
    static var supportLidar: Bool = false
    static var viewportsize: CGSize = CGSize(width: 390, height: 844)
    static var fileURL: URL?
    static var isRecording: Bool = false
}
