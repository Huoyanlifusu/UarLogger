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
    private var vc: ViewController?
    
    init(featurePointNum: Int, viewController: ViewController) {
        self.featurePointNum = featurePointNum
        self.vc = viewController
    }
    
    func featureCounter(_ frame: ARFrame, _ timeStamp: TimeInterval) {
        featurePointNum = frame.rawFeaturePoints?.points.count ?? 0
        vc?.featureLabel.text = "\(featurePointNum)个"
//        if featurePointNum >= 50 {
//            vc?.featureLabel.text = "Too much"
//        } else if featurePointNum >= 40 && featurePointNum < 50 {
//            vc?.featureLabel.text = "Much"
//        } else if featurePointNum >= 20 && featurePointNum < 40 {
//            vc?.featureLabel.text = "Normal"
//        } else if featurePointNum >= 10 && featurePointNum < 20 {
//            vc?.featureLabel.text = "Not enough"
//        } else {
//            vc?.featureLabel.text = "Few"
//        }
    }
    
    func featureCounter(_ frame: ARFrame) -> Int {
        return frame.rawFeaturePoints?.points.count ?? 0
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
