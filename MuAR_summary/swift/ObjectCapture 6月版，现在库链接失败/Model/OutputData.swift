//
//  OutputData.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/20.
//

import Foundation

class OutputData {
    private lazy var logStringRotation = initLogString()
    private lazy var logStringTranslation = initLogString()
    private lazy var logStringPointCloudPosition = initLogString()
    private lazy var logStringTransform = initLogString()
    
    private func initLogString() -> NSMutableString {
        return NSMutableString(string: "")
    }
    
    func updateRotationString(_ x: Float, _ y: Float, _ z: Float, _ w: Float, _ id: Int) {
        self.logStringRotation.append(String(format: "%d,%f,%f,%f,%f\r\n", id, x, y, z, w))
    }
    
    func updateTranslationString(_ x: Float, _ y: Float, _ z: Float, _ u: Float, _ v: Float, _ w: Float, _ id: Int) {
        self.logStringTranslation.append(String(format: "%d,%f,%f,%f\r\n", id, x, y, z))
    }
    
    func updateFeaturePointString(_ x: Float, _ y: Float, _ z: Float) {
        self.logStringPointCloudPosition.append(String(format: "%f,%f,%f\r\n", x, y, z))
    }
    
    // e01 denotes element in first row second column
    func updateTransformString(_ e00: Float, _ e01: Float, _ e02: Float, _ e03: Float,
                               _ e10: Float, _ e11: Float, _ e12: Float, _ e13: Float,
                               _ e20: Float, _ e21: Float, _ e22: Float, _ e23: Float,
                               _ e30: Float, _ e31: Float, _ e32: Float, _ e33: Float, _ id: Int) {
        self.logStringTransform.append(String(format: "%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\r\n", id,
                                              e00, e01, e02, e03,
                                              e10, e11, e12, e13,
                                              e20, e21, e22, e23,
                                              e30, e31, e32, e33))
    }
    
    func saveRotationString() {
        writeStringToFile(logStringRotation, "Rotation")
    }
    
    func saveTranslationString() {
        writeStringToFile(logStringTranslation, "Translation")
    }
    
    func savePointCloudPositionString() {
        writeStringToFile(logStringPointCloudPosition, "PointCloudPosition")
    }
    
    func saveTransformString() {
        writeStringToFile(logStringTransform, "Transform")
    }
    
    private func writeStringToFile(_ string: NSMutableString, _ filename: String) {
        guard let url = ScanConfig.objcapURL else {
            fatalError()
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
