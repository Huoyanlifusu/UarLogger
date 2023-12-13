//
//  ARManager.swift
//  ScanKit
//
//  Created by Kenneth Schröder on 14.08.21.
//
// ARManager Session's delegate
import Foundation
import ARKit
import CoreMedia

class ARManager: NSObject, ARSessionDelegate {
    private var viewController: ScanVC
    private var session: ARSession
    private var featureExtractor: FeatureExtractor
    private let depthRecorder = DepthRecorder()
    private var rgbRecorder: RGBRecorder! = nil
    private let cameraInfoRecorder = CameraInfoRecorder()
    private var numFrames: Int = 0
    private var dirUrl: URL!
    private var dirRecordingID: String!
    var isRecording: Bool = false
    private var cameraIntrinsic: simd_float3x3?
    private var colorFrameResolution: [Int] = []
    private var depthFrameResolution: [Int] = []
    private var frequency: Int?
    private var username: String?
    private var sceneDescription: String?
    private var sceneType: String?
    private let imageQueue = DispatchQueue(label: "captureImage")
    private let featureQueue = DispatchQueue(label: "captureDepth")
    private let sessionQueue = DispatchQueue(label: "ar camera recording queue", attributes: .concurrent)
    private let collectorQueue = DispatchQueue(label: "collectData")
    private let renderQueue = DispatchQueue(label: "render")
    private let context = CIContext()
    // init
    init(viewController: ScanVC, arsession: ARSession) {
        self.viewController = viewController
        self.session = arsession
//        collector = RawDataCollector(viewController: viewController)
        featureExtractor = FeatureExtractor(vc: viewController)
    }
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.",
                                                    message: errorMessage,
                                                    preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.viewController.resetTracking()
            }
            alertController.addAction(restartAction)
            self.viewController.present(alertController, animated: true, completion: nil)
        }
    }
    // interruption begin
    func sessionWasInterrupted(_ session: ARSession) {
        // TODO Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    // interruption end
    func sessionInterruptionEnded(_ session: ARSession) {
        // TODO Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    // frame update
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let scaledPixelBuffer = CIImage(cvPixelBuffer: frame.capturedImage)
                .oriented(.right)
                .resize(size: CGSize(width: 480,
                                     height: 640))
                .toPixelBuffer(context: context,
                               gray: false) else { return }
        // https://stackoverflow.com/questions/28519274/ios-unsupported-color-space-error
        imageQueue.async {
            self.viewController.depthPredict.predict(with: scaledPixelBuffer)
        }
        featureQueue.async {
            self.featureExtractor.extractDepth(with: frame, and: DepthDataFromML.depthMap)
        }
        // Recorder 采集方法
        if isRecording {
            let colorImage: CVPixelBuffer = frame.capturedImage
            let timestamp: CMTime = CMTime(seconds: frame.timestamp, preferredTimescale: 1_000_000_000)
            let currentCameraInfo = CameraInfo(timestamp: frame.timestamp,
                                               intrinsics: frame.camera.intrinsics,
                                               transform: frame.camera.transform,
                                               eulerAngles: frame.camera.eulerAngles,
                                               exposureDuration: frame.camera.exposureDuration)
            collectorQueue.async { [self] in
                rgbRecorder.update(colorImage, timestamp: timestamp)
                cameraInfoRecorder.update(currentCameraInfo, timestamp: timestamp)
            }
            if !PixelBufferQueue.isEmpty {
                let depthMap = PixelBufferQueue.queue.removeFirst()
                collectorQueue.async { [self] in
                    depthRecorder.update(depthMap, timestamp: timestamp)
                }
            }
            numFrames += 1
        }
    }
}

extension ARManager: RecordingManager {
    func getSession() -> NSObject {
        return session
    }
    // start record
    func startRecording() {
        sessionQueue.sync { [self] in
            self.username = ScanConfig.userName
            self.sceneDescription = ScanConfig.sceneDescription
            self.sceneType = ScanConfig.sceneType
            numFrames = 0
            if let currentFrame = session.currentFrame {
                cameraIntrinsic = currentFrame.camera.intrinsics
                if ScanConfig.developerMode {
                    if let depthPic = DepthDataFromML.depthPic {
                        let height = CVPixelBufferGetHeight(depthPic)
                        let width = CVPixelBufferGetWidth(depthPic)
                        depthFrameResolution = [height, width]
                    } else {
                        fatalError("can not collect depth data")
                    }
                } else {
                    depthFrameResolution = [1440, 1920]
                }
            }
            guard let url = ScanConfig.url,
                  let recordingId = ScanConfig.recordingID else { fatalError("cannot find url & recordingID!") }
            dirRecordingID = recordingId
            dirUrl = url
            depthRecorder.prepareForRecording(dirPath: dirUrl.path, filename: dirRecordingID)
            rgbRecorder.prepareForRecording(dirPath: dirUrl.path, filename: dirRecordingID)
            cameraInfoRecorder.prepareForRecording(dirPath: dirUrl.path, filename: dirRecordingID)
            featureExtractor.startRecording()
            isRecording = true
            Logger.shared.debugPrint("ARKit manager started recording data.")
        }
    }
    // stop record
    func endRecording() {
        sessionQueue.async { [self] in
            isRecording = false
            depthRecorder.finishRecording()
            rgbRecorder.finishRecording()
            cameraInfoRecorder.finishRecording()
            featureExtractor.endRecording()
            writeMetadataToFIle()
            username = nil
            sceneDescription = nil
            sceneType = nil
            viewController.notifyProgressPC(value: 1.0)
            viewController.notifyProgressRaw(value: 1.0)
            Logger.shared.debugPrint("ARKit manager ended recording data.")
        }
    }
}

extension ARManager {
    func configureSession(_ videoFormat: ARConfiguration.VideoFormat, _ imageResolution: CGSize) {
        frequency = videoFormat.framesPerSecond
        colorFrameResolution = [Int(imageResolution.height), Int(imageResolution.width)]
        let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                           AVVideoHeightKey: NSNumber(value: colorFrameResolution[0]),
                                            AVVideoWidthKey: NSNumber(value: colorFrameResolution[1])]
        rgbRecorder = RGBRecorder(videoSettings: videoSettings)
    }
    private func writeMetadataToFIle() {
        let cameraIntrinsicArray = cameraIntrinsic?.arrayRepresentation
        let rgbStreamInfo = CameraStreamInfo(id: "color_back_1",
                                             type: "color_camera",
                                             encoding: "h264",
                                             frequency: frequency ?? 0,
                                             numberOfFrames: numFrames,
                                             fileExtension: "mp4",
                                             resolution: colorFrameResolution,
                                             intrinsics: cameraIntrinsicArray,
                                             extrinsics: nil)
        let depthStreamInfo = CameraStreamInfo(id: "depth_back_1",
                                               type: "lidar_sensor",
                                               encoding: "float16_zlib",
                                               frequency: frequency ?? 0,
                                               numberOfFrames: numFrames,
                                               fileExtension: "depth.zlib",
                                               resolution: depthFrameResolution,
                                               intrinsics: nil,
                                               extrinsics: nil)
        let cameraInfoStreamInfo = StreamInfo(id: "camera_info_color_back_1",
                                              type: "camera_info",
                                              encoding: "jsonl",
                                              frequency: frequency ?? 0,
                                              numberOfFrames: numFrames,
                                              fileExtension: "jsonl")
        let metadata = Metadata(username: username ?? "",
                                userInputDescription: sceneDescription ?? "",
                                sceneType: sceneType ?? "",
                                gpsLocation: [],
                                streams: [rgbStreamInfo, depthStreamInfo, cameraInfoStreamInfo],
                                numberOfFiles: 5)
        let metadataPath = (dirUrl.path as NSString)
                                .appendingPathComponent((dirRecordingID as NSString)
                                .appendingPathExtension("json")!)
        metadata.display()
        metadata.writeToFile(filepath: metadataPath)
    }
}
