//
//  ScanConfig.swift
//  ScanKit
//
//  Created by Kenneth Schröder on 14.08.21.
//

import Foundation

class ScanConfig {
    // Scan Configurations
    static var url: URL? // General capture files url
    static var downloadURL: URL? // Download files url
    static var objcapURL: URL? // Object capture files url
    static var recordingID: String?
    static var userName: String?
    static var sceneDescription: String?
    static var sceneType: String?
    static var underlayIndex: Int = 1
    static var viewIndex: Int = 0
    static var viewshedActive: Bool = true
    static var torchActive: Bool = false
    static var numGridPoints: Int = 49_152
    static var renderedParticleSize: Float = 15
    static var renderedParticleConfidenceThreshold: Int = 2
    static let maxPointsPerVisualBuffer: Int = 262_144
    static let maxPointsPerRecordingBuffer: Int = 2_097_152 /// 2^21
    static let viewshedMaxCount: Int = 49_152 /// TODO might need adjustment with better lidar data/newer devices from apple
    static let sobelDepthThreshold:Float = 0.05 /// if the corresponding value of a particle on the depth sobel texture is above this value, it will be marked as unselected and later deleted (because it lies on an edge on the depth image)
    static let sobelYThreshold:Float = 0.5 /// if the corresponding value of a particle on the Y sobel texture is above this value, it will be kept (because it lies on an edge on the Y image and is likely important for details)
    static let sobelYEdgeSamplingRate:Float = 0.5
    static let sobelSurfaceSamplingRate:Float = 0.01 /// if a particle doesn't lie on an edge in both sobel textures, it most likely lies on a flat surface, thus it is randomly marked as unselected (and later on deleted) with a probability of this value
    static let maxPointDepth:Float = 5.0 /// particles more than this far away from the camera at the time of recording will be deleted
    static let minPointDepth:Float = 0.0 /// particles less than this far away from the camera at the time of recording will be deleted
    static var savePointCloud: Bool = true
    
    // versee scan settings
    static var isRecording: Bool = false
    static var developerMode: Bool = false
    static var isPad: Bool = false
    static var viewportSize: CGSize?
}