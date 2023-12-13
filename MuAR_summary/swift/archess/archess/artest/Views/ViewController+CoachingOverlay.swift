//
//  ViewController+CoachingOverlay.swift
//  artest
//
//  Created by 张裕阳 on 2022/10/12.
//

import Foundation
import ARKit

@available(iOS 16.0, *)
extension ViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        DetailView.isHidden = true
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        DetailView.isHidden = false
    }
    
    func coachingOverlayViewDidRequestSessionReset() {
        restart()
    }
    
    func setActivatesAutomatically() {
        coachingOverlayView.activatesAutomatically = true
    }
    
    func setPlaneDetectionGoal() {
        coachingOverlayView.goal = .horizontalPlane
    }
    
    func setupCoachingOverlay() {
        coachingOverlayView.session = sceneView.session
        coachingOverlayView.delegate = self
        coachingOverlayView.goal = .tracking
        
        coachingOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        sceneView.addSubview(coachingOverlayView)
        
        setActivatesAutomatically()
        
        NSLayoutConstraint.activate([
            coachingOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlayView.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlayView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
    }
    
    
}

