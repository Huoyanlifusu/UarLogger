//
//  UploadConfig.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/21.
//

import Foundation

struct UploadConfig {
    static var errorCount: Int = 0
    
    static let httpHead = "http://"
    static var httpHostName: String = "139.9.95.203"
    static var httpServerPort: String = "8080"
    static var httpOrigin: String = httpHead + httpHostName + ":" + httpServerPort
    
    static var deleteFilesAfterUploading: Bool = true
    static var isUploadingInBackgroundThread: Bool = false
    static var currentUploadingURL: URL?
    static var uploadingProgress: Float = 0.0
}
