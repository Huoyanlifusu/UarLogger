//
//  Utility.swift
//  integration
//
//  Created by 张裕阳 on 2023/6/15.
//

import Foundation
import simd

class PointcloudData {
    private lazy var logStringPointCloud = initLogString()
    private lazy var logStringPixelPoint = initLogString()
    private lazy var logStringTransform = initLogString()
    
    private func initLogString() -> NSMutableString {
        return NSMutableString(string: "")
    }
    
    func updateFeaturePointString(_ x: Float, _ y: Float, _ z: Float) {
        self.logStringPointCloud.append(String(format: "%f,%f,%f\r\n", x, y, z))
    }
    
    func updatePixelPointString(_ x: Float, _ y: Float) {
        self.logStringPointCloud.append(String(format: "%f,%f\r\n", x, y))
    }
    
    func updateTransformString(_ transform: simd_float4x4) {
        let e00 = transform.columns.0.x
        let e01 = transform.columns.1.x
        let e02 = transform.columns.2.x
        let e03 = transform.columns.3.x
        
        let e10 = transform.columns.0.y
        let e11 = transform.columns.1.y
        let e12 = transform.columns.2.y
        let e13 = transform.columns.3.y
        
        let e20 = transform.columns.0.z
        let e21 = transform.columns.1.z
        let e22 = transform.columns.2.z
        let e23 = transform.columns.3.z
        
        let e30 = transform.columns.0.w
        let e31 = transform.columns.1.w
        let e32 = transform.columns.2.w
        let e33 = transform.columns.3.w
        self.logStringTransform.append(String(format: "%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f",
                                              e00, e01, e02, e03,
                                              e10, e11, e12, e13,
                                              e20, e21, e22, e23,
                                              e30, e31, e32, e33))
        writeStringToFile(logStringTransform, "camTrans")
    }
    
    func savePointCloudPositionString() {
        writeStringToFile(logStringPointCloud, "PointCloud")
    }
    
    func savePixelPointPositionString() {
        writeStringToFile(logStringPixelPoint, "PixelPoint")
    }
    
    private func writeStringToFile(_ string: NSMutableString, _ filename: String) {
        guard let url = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask).first else {
            return
        }
        let filePath = (url.path as NSString)
                                .appendingPathComponent((filename as NSString)
                                .appendingPathExtension("txt")!)
        do {
            try string.write(toFile: filePath, atomically: true,
                             encoding: String.Encoding.utf8.rawValue)
        } catch {
            print("Error writing string to file: \(error)")
        }
    }
}
