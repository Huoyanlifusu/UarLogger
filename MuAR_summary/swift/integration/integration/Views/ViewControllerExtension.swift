//
//  ViewControllerExtension.swift
//  integration
//
//  Created by 张裕阳 on 2023/7/10.
//

import Foundation
import ARKit

extension ViewController {
    fileprivate func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        guard let multipeer = mpc else { return }
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeer.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
        case .normal where multipeer.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeer.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
        case .notAvailable:
            message = "Tracking unavailable."
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
        case .limited(.initializing):
            message = "Initializing AR session."
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
        }
        
        infoLabel.text = message
    }
}
