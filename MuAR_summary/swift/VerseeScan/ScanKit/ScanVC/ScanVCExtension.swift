//
//  ScanVCExtension.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/3.
//

import Foundation
import UIKit

// MARK: - Recording Related Methods
extension ScanVC {
    func beginRecording() async {
        ScanConfig.recordingID = Helper.getRecordingId()
        // 动态路径
        let recordingDataDirectoryUrl = ScanConfig.url!.appendingPathComponent(ScanConfig.recordingID!)
        if !FileManager.default.fileExists(atPath: recordingDataDirectoryUrl.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: recordingDataDirectoryUrl.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        ScanConfig.url = recordingDataDirectoryUrl
        backButton.isEnabled = false
        recordButton.layer.backgroundColor = UIColor.red.cgColor
        ScanConfig.isRecording = true
        await asyncMission()
        Logger.shared.debugPrint("Recording started.")
    }
    func asyncMission() async {
        arManager.startRecording()
        Logger.shared.debugPrint("AR Manager started recording data.")
        cmManager.startRecording()
        Logger.shared.debugPrint("Core Motion Manager started recording data.")
        clManager.startRecording()
        Logger.shared.debugPrint("Core Location Manager started recording data.")
    }
    func recordingEnded() {
        ScanConfig.isRecording = false
        coreQueue.sync { [self] in
            arManager.endRecording()
            Logger.shared.debugPrint("AR Manager stopped recording data.")
            cmManager.endRecording()
            Logger.shared.debugPrint("Cor Motion Manager stopped recording data.")
            clManager.endRecording()
            Logger.shared.debugPrint("Core Location Manager stopped recording data.")
        }
        showProgressRing()
        backButton.isEnabled = true
        recordButton.layer.backgroundColor = UIColor.green.cgColor
    }
    
    func recordingInteruptted() {
        ScanConfig.isRecording = false
        backButton.isEnabled = true
        recordButton.layer.backgroundColor = UIColor.green.cgColor
        let fileManager = FileManager.default
        let currentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let directoryContents = try fileManager.contentsOfDirectory(atPath: currentPath)
            for path in directoryContents {
                if ScanConfig.url != nil && ScanConfig.url!.lastPathComponent == path {
                    let combinedPath = currentPath + "/" + path
                    try fileManager.removeItem(atPath: combinedPath)
                }
            }
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
        Logger.shared.debugPrint("Recording was interrupted.")
    }
    
    // dynamic path
    func configDirectory() {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        ScanConfig.url = URL(string: documentsDirectory)
        Logger.shared.debugPrint("File URL configured.")
    }
    
    var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
