//
//  mp4decomposer.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/7/7.
//

import Foundation
import UIKit
import AVFoundation
import RealityKit
import CoreLocation

@available(iOS 17.0, *)
class VideoDecomposer {
    let decomposerQueue = DispatchQueue(label: "decompose")
    
    var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var filePath: String!
    var imageDirectoryPath: String!
    private var videoUrl: URL!
    
    init(path: String) {
        self.filePath = path
        self.imageDirectoryPath = documentsDirectory.appendingPathComponent(path).appendingPathComponent("Images").path + "/"
        self.createImageDirectory(imageDirectoryPath)
        self.videoUrl = documentsDirectory.appendingPathComponent(filePath+"/"+filePath+".mp4")
    }
    
    var frameNum = 0
    
    private func createImageDirectory(_ path: String) {
        let manager = FileManager.default
        let exist = manager.fileExists(atPath: path)
        let url = URL(fileURLWithPath: path)
        if !exist {
            try! manager.createDirectory(at: url,
                                         withIntermediateDirectories: true,
                                         attributes: nil)
        }
    }
    
    private func imageFromVideo(url: URL, at time: TimeInterval, completion: @escaping (UIImage?) -> Void) {
        decomposerQueue.async {
            let asset = AVAsset(url: url)

            let assetIG = AVAssetImageGenerator(asset: asset)
            assetIG.appliesPreferredTrackTransform = true
            assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

            let cmTime = CMTime(seconds: time, preferredTimescale: 60)
            let thumbnailImageRef: CGImage
            do {
                thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
            } catch let error {
                print("Error: \(error)")
                return completion(nil)
            }
            DispatchQueue.main.async { [self] in
                let image = UIImage(cgImage: thumbnailImageRef, scale: 1.0, orientation: .right)
                completion(image)
            }
        }
    }
    
    private func modifyandSaveImage(_ image: UIImage, _ fileURL: URL) {
        let heic = image.heicData()! // set JPG quality here (1.0 is best)
//        let src = CGImageSourceCreateWithData(jpeg as CFData, nil)!
//        let uti = CGImageSourceGetType(src)!
        let filePath = (fileURL.path as NSString).appendingPathComponent("image_\(frameNum).heic")
//        let cfPath = CFURLCreateWithFileSystemPath(nil, filePath as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
//        let dest = CGImageDestinationCreateWithURL(cfPath!, uti, 1, nil)
//        
        // create GPS metadata from current location
//        let gCurLocation = CLLocation()
//        let gpsMeta = gCurLocation.exifMetadata() // gCurrentLocation is your CLLocation (exifMetadata is an extension)
//        let tiffProperties = [
//            kCGImagePropertyTIFFMake as String: "Camera vendor",
//            kCGImagePropertyTIFFModel as String: "Camera model"
//            // --(insert other properties here if required)--
//        ] as CFDictionary
//
//        let properties = [
//            kCGImagePropertyTIFFDictionary as String: tiffProperties,
//            kCGImagePropertyGPSDictionary: gpsMeta as Any
//            // --(insert other dictionaries here if required)--
//        ] as CFDictionary
//
//        CGImageDestinationAddImageFromSource(dest!, src, 0, properties)
//        if (CGImageDestinationFinalize(dest!)) {
//            print("Saved image with metadata!")
//        } else {
//            print("Error saving image with metadata")
//        }
        let url = URL(fileURLWithPath: filePath)
        try! heic.write(to: url)
    }
    
    func getAllImages() {
        let asset: AVAsset = AVAsset(url: videoUrl)
        let duration: Float64 = CMTimeGetSeconds(asset.duration)
        
        for index: Int in 0 ..< Int(duration) {
            let time = Double(index)
            imageFromVideo(url: videoUrl, at: time) { [self] image in
                modifyandSaveImage(image!, URL(fileURLWithPath: imageDirectoryPath))
                frameNum += 1
            }
        }
        Logger.shared.debugPrint("Pg_01 - All images are saved in directory.")
        frameNum = 0
    }
}
