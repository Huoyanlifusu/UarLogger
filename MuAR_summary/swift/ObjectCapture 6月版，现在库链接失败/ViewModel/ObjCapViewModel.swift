//
//  ObjCapViewModel.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/18.
//

import Foundation
import RealityKit
import SwiftUI

@available(iOS 17.0, *)
extension ObjCapView {
    final class ObjCapViewModel: ObservableObject {
        @Published var captureFolderState: CaptureFolderState?
        @Published var isProcessingComplete: Bool = false
        @Published var requestProcessPercentage: Double = 0.0
        
        var outputData = OutputData()
        
        var captureDir: URL? {
            captureFolderState?.captureDir
        }
        
        func setup() {
            do {
                captureFolderState = try ObjCapViewModel.createNewCaptureFolder()
            }
            catch {
                Logger.shared.debugPrint("Error 005: Unable to create object capture directory. Descriptions: \(error.localizedDescription)")
            }
        }
        
        private static func createNewCaptureFolder() throws -> CaptureFolderState {
            guard let newCapDir = CaptureFolderState.createObjCapDirectory() else {
                throw SetupError.failed(msg: "Unable to create capture directory!")
            }
            return CaptureFolderState(url: newCapDir)
        }
        
        private enum SetupError: Error {
            case failed(msg: String)
        }
        
        func handleProcessingComplete() {
            withAnimation(.easeIn) {
                isProcessingComplete = true
            }
        }
        
        func handleRequestProgress(_ fractionComplete: Double) {
            requestProcessPercentage = fractionComplete
        }
        
        func writePosesToFile(_ poses: PhotogrammetrySession.Poses) {
            let samples = poses.posesBySample
            for Sample in samples {
                let id = Sample.key
                let pose = Sample.value
                let rotation = pose.rotation
                let translation = pose.translation
                let scale = pose.transform.scale
                let transform = pose.transform.matrix.columns
                // save as quaternion, x denotes the real part, y z w denotes the imag part
                outputData.updateRotationString(rotation.real, rotation.imag.x, rotation.imag.y, rotation.imag.z, id)
                // save as x-y-z with scale factor u, v, w
                outputData.updateTranslationString(translation.x, translation.y, translation.z, scale.x, scale.y, scale.z, id)
                // transform matrix save order: row first, then column
                outputData.updateTransformString(transform.0.x, transform.1.x, transform.2.x, transform.3.x,
                                                 transform.0.y, transform.1.y, transform.2.y, transform.3.y,
                                                 transform.0.z, transform.1.z, transform.2.z, transform.3.z,
                                                 transform.0.w, transform.1.w, transform.2.w, transform.3.w, id)
            }
            outputData.saveRotationString()
            outputData.saveTranslationString()
            outputData.saveTransformString()
        }
        
        func writePointCloudToFile(_ pointcloud: PhotogrammetrySession.PointCloud) {
            let points = pointcloud.points
            for point in points {
                outputData.updateFeaturePointString(point.position.x, point.position.y, point.position.z)
            }
            outputData.savePointCloudPositionString()
        }
    }
    
    func createButton(label: String, action: @escaping () -> Void) -> some View {
        var buttonView: some View {
            Button(action: {
                action()
            }) {
                Text(label)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 2)
                    )
            }
            .frame(width: 200, height: 60)
        }
        return buttonView
    }
}
