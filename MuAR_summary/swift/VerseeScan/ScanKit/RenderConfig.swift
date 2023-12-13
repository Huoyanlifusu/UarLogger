//
//  ARDataProvider.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/9.
//

import Foundation
import Metal

struct RenderConfig {
    // Set the destination resolution for the upscaled algorithm.
    static let upscaledWidth = 960
    static let upscaledHeight = 760
    
    // Set the original depth size.
    static let origDepthWidth = 160
    static let origDepthHeight = 128
    
    // Set the original color size.
    static let origColorWidth = 1920
    static let origColorHeight = 1440
    
    // Set the guided filter constants.
    static let guidedFilterEpsilon: Float = 0.004
    static let guidedFilterKernelDiameter = 5
}
