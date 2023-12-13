//
//  MainSUIVViewmodel.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/7/7.
//

import Foundation

extension MainSUIV {
    class MainSUIVViewmodel: HttpRequestHandlerDelegate {
        @Published var currentFileNumber:Float = 0
        @Published var allFileNumber:Float = 1
        @Published var httpProgress: Float = 0.0
        
        @Published var isUploading: Bool = false
        @Published var finishUploadingSuccessfully = false
        @Published var isShowingFailure = false
        
        @Published var currentFilename: String = ""
        
        private let deferQueue = DispatchQueue(label: "defer")
        
        func uploadFile(_ filename: String) {
            let projectURL = getProjUrl(filename)
            isUploading = true
            UploadConfig.isUploadingInBackgroundThread = true
            UploadConfig.currentUploadingURL = projectURL
            DispatchQueue.global(qos: .background).async { [self] in
                httpUpload(projectURL)
            }
        }
        
        func httpUpload(_ projectURL: URL) {
            let httpRequestHandler = HttpRequestHandler(delegate: self)
            allFileNumber = Float(checkDerictory(projectURL))
            if allFileNumber == 0 {
                print("No file in such directory.")
                isUploading = false
            } else {
                finishUploadingSuccessfully = false
                httpRequestHandler.upload(toUpload: projectURL)
            }
        }
        
        func didReceiveUploadProgressUpdate(progress: Float) {
            httpProgress = progress
            UploadConfig.uploadingProgress = progress
            if progress >= 1 {
                if currentFileNumber < allFileNumber {
                    currentFileNumber += 1
                    if currentFileNumber < allFileNumber {
                        deferQueue.asyncAfter(deadline: .now()+0.1) { [self] in
                            httpProgress = 0
                            UploadConfig.uploadingProgress = 0
                        }
                    }
                }
            }
        }
        
        func didCompletedUploadWithError() {
            httpProgress = 0
            isUploading = false
            currentFileNumber = 0
            isShowingFailure = true
            DispatchQueue.main.async { [self] in
                UploadConfig.isUploadingInBackgroundThread = false
                UploadConfig.uploadingProgress = 0
            }
        }
        
        func didCompletedUploadWithoutError() {
            httpProgress = 0
            isUploading = false
            currentFileNumber = 0
            isShowingFailure = false
            finishUploadingSuccessfully = true
            DispatchQueue.main.async {
                UploadConfig.isUploadingInBackgroundThread = false
                UploadConfig.uploadingProgress = 0
            }
            
            if UploadConfig.deleteFilesAfterUploading {
                guard let fileURL = UploadConfig.currentUploadingURL else {
                    return
                }
                removeDataAfterUploading(fileURL)
                UploadConfig.currentUploadingURL = nil
            }
        }
        
        func didReceiveReuploadRequest(_ fileUrls: [URL]) {
            let httpRequestHandler = HttpRequestHandler(delegate: self)
            httpRequestHandler.uploadAllFilesOneByOne(fileUrls: fileUrls)
        }
    }
}
