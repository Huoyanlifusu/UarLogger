//
//  ObjCapSubViews.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/19.
//

import Foundation
import RealityKit
import SwiftUI

@available(iOS 17.0, *)
extension ObjCapView {
    var sessionStateInitView: some View {
        VStack(alignment: .trailing) {
            Spacer()
            InitButton
        }
    }
    var sessionStateReadyView: some View {
        VStack(alignment: .trailing) {
            Spacer()
            ContinueButton
        }
    }
    var sessionStateDetectingView: some View {
        VStack(alignment: .trailing) {
            Spacer()
            CapureButton
        }
    }
    var sessionStateCapturingView: some View {
        VStack {
            Spacer()
            Text("\(session.numberOfShotsTaken) shots taken")
        }
    }
    var seesionCompletedScanPassView: some View {
        VStack {
            Spacer()
            HStack {
                FinishButton
                RestartButton
            }
            .buttonStyle(.borderedProminent)
        }
        .alert(isPresented: $isAlertPresented) {
            Alert(title: Text("Finished Flip"),
                  primaryButton: .default(Text("No Flip"), action: {
                session.beginNewScanPass()
            }), secondaryButton: .default(Text("Flip"), action: {
                session.beginNewScanPassAfterFlip()
            }))
        }
    }
    var sessionStateCompletedView: some View {
        ReconstructionProgressView(viewModel: objCapViewModel, session: session)
            .task {
                do {
                    var configuration = PhotogrammetrySession.Configuration()
                    configuration.sampleOrdering = .sequential
                    configuration.featureSensitivity = .high
                    configuration.checkpointDirectory = objCapViewModel.captureDir?.appendingPathComponent("Images/")
                    let session = try PhotogrammetrySession(input: objCapViewModel.captureDir!, configuration: configuration)
                    
                    try session.process(requests: [
                        .modelFile(url: objCapViewModel.captureDir!.appendingPathComponent("model.usdz")),
                        .poses,
                        .pointCloud
                    ])
                    
                    for try await output in session.outputs {
                        switch output {
                        case .processingComplete:
                            objCapViewModel.handleProcessingComplete()
                        case .inputComplete:
                            Logger.shared.debugPrint("Input Complete!")
                        case .requestError(let request, let error):
                            Logger.shared.debugPrint("Error 501: ObjCap Model Request Error. Descriptions: \(request) - \(error.localizedDescription)")
                        case .requestComplete(let request, let result):
                            Logger.shared.debugPrint("Request Complete: \(request) - \(result)")
                            switch result {
                            case .poses(let poses):
                                objCapViewModel.writePosesToFile(poses)
                            case .pointCloud(let pointCloud):
                                objCapViewModel.writePointCloudToFile(pointCloud)
                            case .modelFile(_):
                                continue
                            case .modelEntity(_):
                                continue
                            case .bounds(_):
                                continue
                            @unknown default:
                                Logger.shared.debugPrint("Error 402: Unknown case error.")
                            }
                        case .requestProgress(_, fractionComplete: let fractionComplete):
                            objCapViewModel.handleRequestProgress(fractionComplete)
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
                }
                catch {
                    Logger.shared.debugPrint(error.localizedDescription)
                }
            }
    }
    var sessionStateFailedView: some View {
        Text("Scanning Failed")
    }
    // Buttons
    var InitButton: some View {
        createButton(label: "Init", action: {
            objCapViewModel.setup()
            session.start(imagesDirectory: objCapViewModel.captureDir!)
        })
    }
    var ContinueButton: some View {
        createButton(label: "Continue", action: {
            let _ = session.startDetecting()
        })
    }
    var CapureButton: some View {
        createButton(label: "Start Capture", action: {
            session.startCapturing()
        })
    }
    var FinishButton: some View {
        createButton(label: "Finish", action: {
            session.finish()
        })
    }
    var RestartButton: some View {
        createButton(label: "New Captures", action: {
            isAlertPresented = true
            session.pause()
        })
    }
}
