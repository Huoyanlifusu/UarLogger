import Foundation
import ARKit

@available(iOS 16.0, *)
extension ViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        
    }
    
    func coachingOverlayViewDidRequestSessionReset() {
        resetTracking()
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
