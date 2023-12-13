//
//  FeatureExtraction.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/5.
//

import Foundation
import ARKit
import CoreML

class FeatureExtractor {
    private var depthLst:[Float]?
    private var pixelLst:[CGPoint]?
    
    private var vc: ScanVC
    private let avg_err_queue = DispatchQueue(label: "avgerr")
    private let write_depth_to_map_queue = DispatchQueue(label: "writedepthtomap")
    
    private var isRecording = false
    
    init(vc: ScanVC) {
        self.vc = vc
    }
    
    func startRecording() {
        isRecording = true
    }
    
    func endRecording() {
        isRecording = false
    }
    
    func extractDepth(with frame: ARFrame, and dArray: MLMultiArray?) {
        guard let viewportSize = ScanConfig.viewportSize else {
            return
        }
        let pointCloud = frame.rawFeaturePoints
        var viewMatrix = frame.camera.viewMatrix(for: .portrait)
        if ScanConfig.isPad {
            viewMatrix = frame.camera.viewMatrix(for: .landscapeLeft)
        }
        depthLst = [Float]()
        pixelLst = [CGPoint]()
        // https://stackoverflow.com/questions/60731258/arkit-viewport-size-vs-real-screen-resolution
        guard let points = pointCloud?.points else { return }
        for point in points {
            // 投影矩阵
            // https://stackoverflow.com/questions/50957310/arkit-reproducing-the-project-point-function
            // https://stackoverflow.com/questions/47887080/arkit-project-point-with-previous-device-position
            // 深度公式应该是 K * [R|t] * p
            let viewPoint: simd_float4 = viewMatrix * (point.toSIMD())
            let depth = viewPoint.normalize().z * -1
            depthLst?.append(depth)
            // 投影方法
            // https://stackoverflow.com/questions/70309120/project-point-method-converting-rawfeaturepoint-to-screen-space
            var pixelPoint = frame.camera.projectPoint(point,
                                                       orientation: .portrait,
                                                       viewportSize: viewportSize)
            if ScanConfig.isPad {
                pixelPoint = frame.camera.projectPoint(point,
                                                       orientation: .landscapeLeft,
                                                       viewportSize: viewportSize)
            }
            pixelLst?.append(pixelPoint)
        }
        guard let dLst = depthLst, let pLst = pixelLst,
              pLst.count == dLst.count, dLst.count > 0 else {
            return
        }
        if isRecording {
            write_depth_to_map_queue.async { [self] in
                if let depthPic = writeDepthMapFromPointCloud(dLst, pLst) {
                    PixelBufferQueue.queue.append(depthPic)
                }
            }
        }
        // flatten 160 row 128 col array to 160 * 128 list
        if let fArray = dArray?.flatten().asArrayOfFloat {
            avg_err_queue.async { [self] in
                let avgError = compare(fArray, dLst, pLst)
                UIConfig.error = avgError
            }
        }
    }
    
    func compare(_ array: [Float], _ depthLst: [Float], _ pointLst: [CGPoint]) -> Float? {
        var sumErr: Float = 0
        for c in 0..<min(depthLst.count, pointLst.count) {
            if pointLst[c].x < 0 || pointLst[c].y < 0 { continue }
            let index = Int(pointLst[c].x * 160 / 1920 * 128) + Int(pointLst[c].y * 128 / 1440)
            if index >= array.count { continue }
            // fArray 数值在 1～2之间 为了对齐 直接做减法
            let error: Float = depthLst[c] - Float(array[index] - 1)
            sumErr += abs(error)
        }
        return sumErr/Float(depthLst.count)
    }
    
    func writeDepthMapFromPointCloud(_ depthLst: [Float], _ pointLst: [CGPoint]) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let width = 1920
        let height = 1440
        let options = [kCVPixelBufferCGImageCompatibilityKey: true,
               kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width, height,
                                         kCVPixelFormatType_DepthFloat32,
                                         options, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let float32Pointer = CVPixelBufferGetBaseAddress(pixelBuffer!)?.assumingMemoryBound(to: Float32.self)
        for (index, point) in pointLst.enumerated() {
            let x = Int(round(point.x))
            let y = Int(round(point.y))
            if x >= width || x < 0 || y >= height || y < 0 {
                continue
            }
            float32Pointer?[y * width + x] = depthLst[index]
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
}
