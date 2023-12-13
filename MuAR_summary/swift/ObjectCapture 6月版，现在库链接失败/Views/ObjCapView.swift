//
//  ObjCapView.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/17.
//

import Foundation
import RealityKit
import SwiftUI

@available(iOS 17.0, *)
struct ObjCapView: View {
    @StateObject var session = ObjectCaptureSession()
    @StateObject var objCapViewModel = ObjCapViewModel()
    @State var isAlertPresented: Bool = false
    
    var body: some View {
        if session.userCompletedScanPass {
            VStack {
                ObjectCapturePointCloudView(session: session)
                seesionCompletedScanPassView
            }
        } else {
            ZStack {
                ObjectCaptureView(session: session)
                if case .initializing = session.state {
                    sessionStateInitView
                } else if case .ready = session.state {
                    sessionStateReadyView
                } else if case .detecting = session.state {
                    sessionStateDetectingView
                } else if case .capturing = session.state {
                    sessionStateCapturingView
                } else if case .completed = session.state {
                    sessionStateCompletedView
                } else if case .failed( _) = session.state {
                    sessionStateFailedView
                }
            }
        }
    }
}
