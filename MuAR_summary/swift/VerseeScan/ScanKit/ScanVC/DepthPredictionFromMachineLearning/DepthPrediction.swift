//
//  DepthPrediction.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/2/27.
//
// 基于CoreML的深度预测
import Vision
import CoreML

public var depthPixelBuffer: CVImageBuffer?

class DepthPredict {
    var visionModel: VNCoreMLModel?
    var request: VNCoreMLRequest?
    var estModel: MLModel?
    let postQueue = DispatchQueue(label: "postProcessor")
    func setupModel() {
        if ScanConfig.developerMode {
            do {
                if let url = ScanConfig.downloadURL {
                    let compiledModelURL = try MLModel.compileModel(at: url)
                    estModel = try MLModel(contentsOf: compiledModelURL, configuration: MLModelConfiguration())
                }
                else {
                    Logger.shared.debugPrint("Warning 001: Core ML setup before MLModel URL setup.")
                    return
                }
                if let model = estModel {
                    if let visionModel = try? VNCoreMLModel(for: model) {
                        self.visionModel = visionModel
                        request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
                        request?.imageCropAndScaleOption = .scaleFill
                    } else {
                        Logger.shared.debugPrint("Error 005: No MLModel file.")
                        fatalError()
                    }
                }
                else {
                    Logger.shared.debugPrint("Warning 003: MLModel setup failed.")
                }
            }
            catch {
                Logger.shared.debugPrint("Error 002: Core ML setup failed.")
                fatalError()
            }
        }
    }
    
    func predict(with pixelBuffer: CVPixelBuffer) {
        guard let request = request else {
            return
        }
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
           let heatMap = observations.first?.featureValue.multiArrayValue {
            DepthDataFromML.depthMap = heatMap
        }
    }
}


struct DepthDataFromML {
    static var depthMap: MLMultiArray?
    static var depthPic: CVPixelBuffer?
}
