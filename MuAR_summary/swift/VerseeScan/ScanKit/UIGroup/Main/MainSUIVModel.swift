//
//  MainSUIVModel.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/7/7.
//

import Foundation
import UIKit
import AVFoundation

extension MainSUIV {
    func newCapture() {
        Logger.shared.debugPrint("Accessing main menu...")
        if ScanConfig.url == nil {
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            ScanConfig.url = URL(string: documentsDirectory)
            Logger.shared.debugPrint("File URL configured.")
        }
        if !FileManager.default.fileExists(atPath: ScanConfig.url!.path) {
            do {
                try FileManager.default.createDirectory(atPath: ScanConfig.url!.path,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    // get first frame of mp4 video
    func getFirstFrameOfVideo(_ fileName: String) -> UIImage? {
        let mp4path = FileManager.default.urls(for: .documentDirectory,
                                               in:.userDomainMask)[0].path() + "/" + fileName + "/" + fileName + ".mp4"
        let asset = AVAsset(url: URL(filePath: mp4path))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(value: 0, timescale: 1)
        do {
            let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch let error {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func removeDataAfterUploading(_ projectURL: URL) {
        let fileManager = FileManager.default
        do {
            let absolutePath = projectURL.path
            try fileManager.removeItem(atPath: absolutePath)
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
        Logger.shared.debugPrint("Successfully remove files:" + projectURL.absoluteString)
    }
    
    static func getProjUrl(_ projectName: String) -> URL {
        let filemgr = FileManager.default
        let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
        let myDocumentsDirectory = dirPaths[0]
        let projectDir = myDocumentsDirectory.appendingPathComponent(projectName)
        return projectDir
    }
    
    static func checkDerictory(_ url: URL) -> Int {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return fileURLs.count
        } catch {
            fatalError("Unable to read files due to：\(error)")
        }
    }
}
