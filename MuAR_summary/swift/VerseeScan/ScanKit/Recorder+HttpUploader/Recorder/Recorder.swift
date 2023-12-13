//
//  recoder.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/14.
//

import CoreMedia

protocol Recorder {
    associatedtype T
    func prepareForRecording(dirPath: String, filename: String, fileExtension: String)
    func update(_: T, timestamp: CMTime?)
    func finishRecording()
}

protocol RecordingManager {
    var isRecording: Bool { get }
    func getSession() -> NSObject
    func startRecording()
    func endRecording()
}
