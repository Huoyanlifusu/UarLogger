//
//  ReconstructionProgressView.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/19.
//

import Foundation
import SwiftUI
import RealityKit

@available(iOS 17.0, *)
struct ReconstructionProgressView: View {
    @ObservedObject var viewModel: ObjCapView.ObjCapViewModel
    @ObservedObject var session: ObjectCaptureSession
    @State var isPresentingProcessdAsset: Bool = false
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack {
                ObjectCapturePointCloudView(session: session)
                if viewModel.isProcessingComplete {
                    Button {
                        isPresentingProcessdAsset = true
                    } label: {
                        VStack {
                            Text("Model processing is completed!")
                            Text("Click here to check out the asset.")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    ProgressView(value: viewModel.requestProcessPercentage)
                }
            }
        }.sheet(isPresented: $isPresentingProcessdAsset) {
            ARQuickLookView(name: "model", allowScaling: true, captureDir: viewModel.captureDir!)
        }
    }
}
