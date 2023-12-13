//
//  ProjectDetailsSUIV.swift
//  ScanKit
//
//  Created by Kenneth Schröder on 29.09.21.
//

import SwiftUI
import MapKit

func getProjUrl(_ projectName: String) -> URL {
    let filemgr = FileManager.default
    let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
    let myDocumentsDirectory = dirPaths[0]
    let projectDir = myDocumentsDirectory.appendingPathComponent(projectName)
    return projectDir
}

func getMetaData(_ projectDir: URL, _ projectName: String) {
    let jsonDecoder = JSONDecoder()
    let metaFilePath = projectDir.appendingPathComponent(projectName+".json")
    do {
        let data = try Data(contentsOf: metaFilePath)
        if let _ = try? jsonDecoder.decode(MultiScanMetaData.self, from: data) {
            print("success")
        }
    } catch {
        print("Reading meta data failed!")
    }
}

struct ProjectDetailsSUIV: View {
    var projectName: String
    var projectUrl: URL
    var dirSize: String = "calculation failed"
    @State private var httpServer: String = UploadConfig.httpHostName
    @State private var httpPort: String = UploadConfig.httpServerPort
    @State private var httpProgress: Float = 0.0
    @State private var isUploading = false
    @State private var isShowingFailure = false
    @State private var finishUploadingSuccessfully = false
    
    @State private var currentFileNumber:Float = 0
    @State private var allFileNumber:Float = 1
    
    private let deferQueue = DispatchQueue(label: "defer")
    
    init(projectName: String) {
        self.projectName = projectName
        self.projectUrl = getProjUrl(projectName)
//        getMetaData(projectUrl, projectName)
        let fm = FileManager()
        do {
            let size = try fm.allocatedSizeOfDirectory(at: projectUrl)
            let bcf = ByteCountFormatter()
            self.dirSize = bcf.string(fromByteCount: Int64(size))
        } catch let error {
            print("Failed to calculate project directory size, error \(error)")
        }
    }
    
    //单个项目界面UI
    var body: some View {
        VStack {
            List {
                Section(header: Text("Storage")) {
                    HStack {
                        Text("Project Size")
                        Spacer()
                        Text(String(dirSize))
                    }
                }
                Section(header: Text("Time")) {
                    HStack {
                        Text("Scan Start")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Scan End")
                        Spacer()
                        Text("-")
                    }
                }
                Section(header: Text("Location")) {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Longitude")
                        Spacer()
                        Text("-")
                    }
                }
                Section(header: Text("Settings")) {
                    HStack {
                        Text("Testing Mode")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Save Point Cloud")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Save RGB Video")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("RGB Quality")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Save Depth Data")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Save Confidence Data")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Save ARWorldMap")
                        Spacer()
                        Text("-")
                    }
                    HStack {
                        Text("Detect QR Codes")
                        Spacer()
                        Text("-")
                    }
                }
                //                Section(header: Text("HTTP Upload")) {
                //                    HStack {
                //                        Text("Host")
                //                        Spacer()
                //                        TextField("Server IP", text: $httpServer).onChange(of: httpServer) { newValue in
                //                            UploadConfig.httpHostName = newValue
                //                        }
                //                    }
                //                    HStack {
                //                        Text("Port")
                //                        Spacer()
                //                        TextField("Server Port", text: $httpPort).onChange(of: httpPort) { newValue in
                //                            UploadConfig.httpServerPort = newValue
                //                        }
                //                    }
                //                    HStack {
                //                        Spacer()
                //                        if (UploadConfig.isUploadingInBackgroundThread || isUploading) && !isShowingFailure {
                //                            VStack {
                //                                if currentFileNumber >= allFileNumber && httpProgress >= 1 {
                //                                    HStack {
                //                                        Text("Verifying...")
                //                                        Spacer()
                //                                    }
                //                                } else {
                //                                    ProgressView("Now uploading file \(Int(currentFileNumber+1)) of \(Int(allFileNumber))",
                //                                                 value: currentFileNumber,
                //                                                 total: allFileNumber)
                //                                    ProgressView("Upload progress: \(String(format: "%.2f", httpProgress*100)) %",
                //                                                 value: httpProgress,
                //                                                 total: 1.0)
                //                                    .scaleEffect(x: 1, y: 1, anchor: .center)
                //                                    .progressViewStyle(.linear)
                //                                }
                //                            }
                //                        }
                //                        else {
                //                            Button("Upload") {
                //                                isUploading = true
                //                                DispatchQueue.global(qos: .background).async {
                //                                    UploadConfig.isUploadingInBackgroundThread = true
                //                                    httpUpload()
                //                                }
                //                            }
                //                        }
                //                        Spacer()
                //                    }.alert(isPresented: $isShowingFailure) {
                //                        Alert(title: Text("Upload failed!"),
                //                              message: Text("Please check your HTTP configuration."),
                //                              dismissButton: .default(Text("Got it!")))
                //                    }.alert(isPresented: $finishUploadingSuccessfully) {
                //                        Alert(title: Text("Successfully Uploaded!"),
                //                              message: Text("Data has been received by server."),
                //                              dismissButton: .default(Text("Got it!")))
                //                    }
                //                }
                //            }
            }
            Button("Open in Files App") { // https://stackoverflow.com/questions/64591298/how-can-i-open-default-files-app-with-myapp-folder-programmatically
                let path = projectUrl.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
                let url = URL(string: path)!
                UIApplication.shared.open(url)
            }
            Spacer()
        }
        .navigationTitle(projectName)
    }
}

struct ProjectDetailsSUIV_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailsSUIV(projectName: "PreviewTestTest")
    }
}

extension ProjectDetailsSUIV: HttpRequestHandlerDelegate {
    func didReceiveUploadProgressUpdate(progress: Float) {
        httpProgress = progress
        UploadConfig.uploadingProgress = progress
        if progress >= 1 {
            if currentFileNumber < allFileNumber {
                currentFileNumber += 1
                if currentFileNumber < allFileNumber {
                    deferQueue.asyncAfter(deadline: .now()+0.1) {
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
        DispatchQueue.main.async {
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
            removeDataAfterUploading()
        }
    }
    
    func didReceiveReuploadRequest(_ fileUrls: [URL]) {
        let httpRequestHandler = HttpRequestHandler(delegate: self)
        httpRequestHandler.uploadAllFilesOneByOne(fileUrls: fileUrls)
    }
}

extension ProjectDetailsSUIV {
    func httpUpload() {
        let httpRequestHandler = HttpRequestHandler(delegate: self)
        allFileNumber = Float(checkDerictory(projectUrl))
        if allFileNumber == 0 {
            print("No file in such directory.")
            isUploading = false
        } else {
            finishUploadingSuccessfully = false
            httpRequestHandler.upload(toUpload: projectUrl)
        }
    }
    
    func checkDerictory(_ url: URL) -> Int {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return fileURLs.count
        } catch {
            fatalError("Unable to read files due to：\(error)")
        }
    }
    
    func removeDataAfterUploading() {
        let fileManager = FileManager.default
        do {
            let absolutePath = projectUrl.path
            try fileManager.removeItem(atPath: absolutePath)
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
        print("Successfully remove" + projectUrl.absoluteString + "files")
    }
}
