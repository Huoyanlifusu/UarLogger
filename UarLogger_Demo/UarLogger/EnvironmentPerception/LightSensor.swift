//
//  LightEstimate.swift
//  integration
//
//  Created by 张裕阳 on 2023/6/13.
//

import Foundation
import ARKit

class LightSensor {
    // 环境光强度
    var lightEstimate: CGFloat
    var lightColorTemp: CGFloat
    
    init(lightEstimate: CGFloat, lightColorTemp: CGFloat) {
        self.lightEstimate = lightEstimate
        self.lightColorTemp = lightColorTemp
    }
}
