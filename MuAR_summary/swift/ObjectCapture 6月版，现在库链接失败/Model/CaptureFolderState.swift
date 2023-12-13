//
//  CaptureFolderState.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/19.
//

import Combine
import Foundation

import os

class CaptureFolderState: ObservableObject {
    static private let workQueue = DispatchQueue(label: "CaptureFolderState.Work",
                                                 qos: .userInitiated)
    
    enum Error: Swift.Error {
        case invalidCaptureDir
    }
    
    @Published var captureDir: URL? = nil
    @Published var captures: [CaptureInfo] = []
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(url capturDir: URL) {
        self.captureDir = capturDir
//        requestLoad()
    }
    
    func requestLoad() {
        requestLoadCaptureInfo()
            .receive(on: DispatchQueue.main)
            .replaceError(with: [])
            .assign(to: \.captures, on: self)
            .store(in: &subscriptions)
    }
    
    private func requestLoadCaptureInfo() -> Future<[CaptureInfo], Error> {
        let future = Future<[CaptureInfo], Error> { promise in
            guard self.captureDir != nil else {
                promise(.failure(.invalidCaptureDir))
                return
            }
            CaptureFolderState.workQueue.async {
                var captureInfoResults: [CaptureInfo] = []
                do {
                    let imgUrls = try FileManager.default
                        .contentsOfDirectory(at: self.captureDir!, includingPropertiesForKeys: [],
                                             options: [.skipsHiddenFiles])
                        .filter { $0.isFileURL
                            && $0.lastPathComponent.hasSuffix(CaptureInfo.imageSuffix)
                        }
                    for imgUrl in imgUrls {
                        guard let photoIdString = try? CaptureInfo.photoIdString(from: imgUrl) else {
                            Logger.shared.debugPrint("Can't get photoIdString from url: \"\(imgUrl)\"")
                            continue
                        }
                        guard let captureId = try? CaptureInfo.extractId(from: photoIdString) else {
                            Logger.shared.debugPrint("Can't get id from from photoIdString: \"\(photoIdString)\"")
                            continue
                        }
                        captureInfoResults.append(CaptureInfo(id: captureId,
                                                              captureDir: self.captureDir!))
                    }
                    // Sort by the capture id.
                    captureInfoResults.sort(by: { $0.id < $1.id })
                    promise(.success(captureInfoResults))
                } catch {
                    promise(.failure(.invalidCaptureDir))
                    return
                }
            }
        }
        return future
    }
    
    static func createObjCapDirectory() -> URL? {
        guard let captureFolder = CaptureFolderState.capturesFolder() else {
            Logger.shared.debugPrint("Error 003: Can't get document dir!")
            return nil
        }
        ScanConfig.recordingID = Helper.getRecordingId()
        guard let recordingID = ScanConfig.recordingID else {
            Logger.shared.debugPrint("Error 006: Can't catch recordingID!")
            return nil
        }
        let recordingDataDirectoryUrl = captureFolder.appendingPathComponent(recordingID + "/",
                                                                             isDirectory: true)
        let reconstructionDataUrl = captureFolder.appendingPathComponent("Images/",
                                                                         isDirectory: true)
        let capturePath = recordingDataDirectoryUrl.path
        let checkpointPath = reconstructionDataUrl.path
        do {
            try FileManager.default.createDirectory(atPath: capturePath,
                                                    withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: checkpointPath,
                                                    withIntermediateDirectories: true)
        } catch {
            Logger.shared.debugPrint("Software Error 004: Can't create folder for saving object capture files. Descriptions: \(error.localizedDescription)")
        }
        
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }
        ScanConfig.objcapURL = recordingDataDirectoryUrl
        return recordingDataDirectoryUrl
    }
    
//    static func createCaptureDirectory() -> URL? {
//        guard let capturesFolder = CaptureFolderState.capturesFolder() else {
//            Logger.shared.debugPrint("Error 003: Can't get document dir!")
//            return nil
//        }
//        
//        let formatter = DateFormatter()
//        formatter.locale = Locale(identifier: "zh_Hant_HK")
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .medium
//        let timestamp = formatter.string(from: Date())
//        let newCaptureDir = capturesFolder.appendingPathComponent(timestamp + "/",
//                                                                  isDirectory: true)
//        Logger.shared.debugPrint("Creating object capture path \(String(describing: newCaptureDir))")
//        
//        let capturePath = newCaptureDir.path
//        do {
//            try FileManager.default.createDirectory(atPath: capturePath,
//                                                    withIntermediateDirectories: true)
//        }
//        catch {
//            Logger.shared.debugPrint("Software Error 004: Can't create object capture path. Descriptions: \(error.localizedDescription)")
//
//        }
//        var isDir: ObjCBool = false
//        let exists = FileManager.default.fileExists(atPath: capturePath, isDirectory: &isDir)
//        guard exists && isDir.boolValue else {
//            return nil
//        }
//        return newCaptureDir
//    }
//    
    static func capturesFolder() -> URL? {
        guard let documentsFolder =
                try? FileManager.default.url(for: .documentDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: nil,
                                             create: false) else {
            return nil
        }
        return documentsFolder
    }
}

