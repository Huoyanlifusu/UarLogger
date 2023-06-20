//
//  FeatureSensor.swift
//  integration
//
//  Created by 张裕阳 on 2023/6/13.
//

import Foundation
import ARKit

class FeatureSensor {
    // 环境光强度
    var featurePointNum: Int
    private let pointcloudData = PointcloudData()
    
    init(featurePointNum: Int) {
        self.featurePointNum = featurePointNum
    }
    
    func featureExtractor(_ frame: ARFrame, _ timeStamp: TimeInterval) {
        featurePointNum = frame.rawFeaturePoints?.points.count ?? 0
        if featurePointNum > 20 {
            Logger.shared.debugPrint("特征丰富")
        }
        if featurePointNum > 10 {
            extractPoints(frame.camera, frame.rawFeaturePoints!)
        }
        else {
            Logger.shared.debugPrint("特征匮乏")
        }
    }
    
    func extractPoints(_ camera: ARCamera, _ pointCloud: ARPointCloud?) {
        guard let pointCloud = pointCloud else {
            return
        }
        var n = 0
        var index = 0
        while n < 6 {
            if index >= pointCloud.points.count {
                break
            }
            let i = pointCloud.points.index(pointCloud.points.startIndex, offsetBy: index)
            let point = pointCloud.points[i]
            if point.z < -10 || point.z > -0.1 {
                index += 1
                continue
            }
            let pixel = camera.projectPoint(point,
                                            orientation: .portrait,
                                            viewportSize: ScanConfig.viewportsize)
            pointcloudData.updateFeaturePointString(point.x, point.y, point.z)
            pointcloudData.updatePixelPointString(Float(pixel.x), Float(pixel.y))
            n += 1
            index += 1
            if n == 6 {
                pointcloudData.savePointCloudPositionString()
                pointcloudData.savePixelPointPositionString()
                pointcloudData.updateTransformString(camera.transform)
                break
            }
        }
    }
}
