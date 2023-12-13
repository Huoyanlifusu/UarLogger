//
//  Photogrammetry.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/7/7.
//

import Foundation
import RealityKit

@available(iOS 17.0, *)
class Photogrammetry {
    var refinedData: RefinedData
    private var path: String
    init(path: String) {
        refinedData = RefinedData(filePath: path)
        self.path = path
    }
    
    private typealias Request = PhotogrammetrySession.Request
    private var detail: Request.Detail? = nil
    
    var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func initialization() {
        processwithURL(with: documentsDirectory)
    }
    
    private var preview: Request.Detail? = nil
    
    func processwithURL(with url: URL) {
        var config = PhotogrammetrySession.Configuration()
            config.sampleOrdering = .sequential
            config.featureSensitivity = .normal
            config.isObjectMaskingEnabled = false
        config.checkpointDirectory = url.appendingPathComponent(path).appendingPathComponent("checkpoint/")
        let imgURL = URL(fileURLWithPath: documentsDirectory.path + "/" + path + "/Images/", isDirectory: true)
        print(imgURL)
        var maybeSession: PhotogrammetrySession? = nil
        do {
            maybeSession = try PhotogrammetrySession(input: imgURL,
                                                     configuration: config)
            Logger.shared.debugPrint("Successfully created session.")
        } catch {
            Logger.shared.debugPrint("Error creating session: \(String(describing: error))")
            cleanFiles()
            maybeSession = nil
            return
        }
        
        guard let session = maybeSession else {
            Logger.shared.debugPrint("Error in copying session info.")
            cleanFiles()
            maybeSession = nil
            return
        }
        
        let waiter = Task {
            do {
                try session.process(requests: [
                    .pointCloud
                ])
                
                for try await output in session.outputs {
                    switch output {
                    case .processingComplete:
                        Logger.shared.debugPrint("Processing Complete!")
                    case .inputComplete:
                        Logger.shared.debugPrint("Input Complete!")
                    case .requestError(let request, let error):
                        Logger.shared.debugPrint("Error 501: ObjCap Model Request Error. Descriptions: \(request) - \(error.localizedDescription)")
                    case .requestComplete(let request, let result):
                        Logger.shared.debugPrint("Request Complete: \(request) - \(result)")
                        switch result {
                        case .poses(let poses):
                            writePosesToFile(poses)
                            Logger.shared.debugPrint("Pg_02 - All poses saved.")
                        case .pointCloud(let pointCloud):
                            writePointCloudToFile(pointCloud)
                            Logger.shared.debugPrint("Pg_02 - All pointclouds saved.")
                        case .modelFile(_):
                            continue
                        case .modelEntity(_):
                            continue
                        case .bounds(_):
                            continue
                        @unknown default:
                            Logger.shared.debugPrint("Error 402: Unknown case error.")
                        }
                    case .requestProgress(_, fractionComplete: _):
                        continue
                        //                    objCapViewModel.handleRequestProgress(fractionComplete)
                    case .processingCancelled:
                        Logger.shared.debugPrint("Processing Cancelled!")
                    case .invalidSample(id: let id, reason: let reason):
                        Logger.shared.debugPrint("Warning 501: ObjCap Sample Invalid. id: \(id) - reason: \(reason)")
                    case .skippedSample(id: let id):
                        Logger.shared.debugPrint("Skipped Sample, id: \(id)")
                    case .automaticDownsampling:
                        Logger.shared.debugPrint("Automatic downsampling.")
                    case .requestProgressInfo(let request, let info):
                        Logger.shared.debugPrint("Request ProgressInfo: \(request) - \(info)")
                    @unknown default:
                        Logger.shared.debugPrint("Error 402: Unknown case error.")
                    }
                }
            } catch {
                cleanFiles()
                Logger.shared.debugPrint("Error 007: reconstruction failed due to:")
                Logger.shared.debugPrint(error.localizedDescription)
            }
        }
        
        withExtendedLifetime((session, waiter)) {
            // Run the main process call on the request, then enter the main run
            // loop until you get the published completion event or error.
            do {
                let request = makeRequestFromArguments()
                Logger.shared.debugPrint("Using request: \(String(describing: request))")
                try session.process(requests: request)
                // Enter the infinite loop dispatcher used to process asynchronous
                // blocks on the main queue. You explicitly exit above to stop the loop.
                RunLoop.main.run()
            } catch {
                cleanFiles()
                maybeSession = nil
                Logger.shared.debugPrint("Process got error: \(String(describing: error))")
            }
        }
    }
    
    private func makeRequestFromArguments() -> [PhotogrammetrySession.Request] {
        let outputUrl = documentsDirectory.appendingPathComponent(path).appendingPathComponent("model/")
        if let detailSetting = detail {
            return [
                    PhotogrammetrySession.Request.pointCloud]
        } else {
            return [
                    PhotogrammetrySession.Request.pointCloud]
        }
    }
    
    private func writePosesToFile(_ poses: PhotogrammetrySession.Poses) {
        let samples = poses.posesBySample
        for Sample in samples {
            let id = Sample.key
            let pose = Sample.value
            let rotation = pose.rotation
            let translation = pose.translation
            let scale = pose.transform.scale
            let transform = pose.transform.matrix.columns
            // save as quaternion, x denotes the real part, y z w denotes the imag part
            refinedData.updateRotationString(rotation.real, rotation.imag.x, rotation.imag.y, rotation.imag.z, id)
            // save as x-y-z with scale factor u, v, w
            refinedData.updateTranslationString(translation.x, translation.y, translation.z, scale.x, scale.y, scale.z, id)
            // transform matrix save order: row first, then column
            refinedData.updateTransformString(transform.0.x, transform.1.x, transform.2.x, transform.3.x,
                                             transform.0.y, transform.1.y, transform.2.y, transform.3.y,
                                             transform.0.z, transform.1.z, transform.2.z, transform.3.z,
                                             transform.0.w, transform.1.w, transform.2.w, transform.3.w, id)
        }
        refinedData.saveRotationString()
        refinedData.saveTranslationString()
        refinedData.saveTransformString()
    }
    
    private func writePointCloudToFile(_ pointcloud: PhotogrammetrySession.PointCloud) {
        let points = pointcloud.points
        for point in points {
            refinedData.updateFeaturePointString(point.position.x, point.position.y, point.position.z)
        }
        refinedData.savePointCloudPositionString()
    }
    
    private func cleanFiles() {
        
        let fileManager = FileManager.default
        let currentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let directoryContents = try fileManager.contentsOfDirectory(atPath: currentPath)
            let combinedPath = currentPath + "/" + path
            let imgURL = URL(fileURLWithPath: combinedPath).appendingPathComponent("Images/")
            let checkpointURL = URL(fileURLWithPath: combinedPath).appendingPathComponent("checkpoint/")
//            try fileManager.removeItem(at: imgURL)
            try fileManager.removeItem(at: checkpointURL)
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }
    
}
