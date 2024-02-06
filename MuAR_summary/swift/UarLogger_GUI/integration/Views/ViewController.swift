//
//  ViewController.swift
//  artest
//
//  Created by 张裕阳 on 2022/9/22.
//

import Foundation
import UIKit
import ARKit
import NearbyInteraction
import MultipeerConnectivity
import RealityKit
import SwiftUI

@available(iOS 16.0, *)
class ViewController: UIViewController, NISessionDelegate, ARSessionDelegate, ARSCNViewDelegate {
    // scene
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var panelView: UIView!
    
    // labels
    @IBOutlet weak var deviceLable: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var lightingIntensityLabel: UILabel!
    @IBOutlet weak var motionLabel: UILabel!
    @IBOutlet weak var featureLabel: UILabel!
    
    // button
    @IBOutlet weak var flashlightButton: UIButton!
    @IBOutlet weak var panelButton: UIButton!
    
    
    // Nearby Interaction
    var niSession: NISession?
    var peerDiscoveryToken: NIDiscoveryToken?
    var sharedTokenWithPeers = false
    var currentState: DistanceDirectionState = .unknown
    enum DistanceDirectionState {
        case unknown, closeUpInFOV, notCloseUpInFOV, outOfFOV
    }
    
    // Multipeer Connectivity
    var mpc: MPCSession?
    var connectedPeer: MCPeerID?
    var peerDisplayName: String?
    var peerSessionIDs = [MCPeerID: String]()
    var sessionIDObservation: NSKeyValueObservation?
    
    // Conditional variables
    var alreadyAdd = false
    var couldDetect = true
    private var isRecording = false
    private var isPanelShowing = false
    private var isFirstFrame = false
    private var isDectecingFp = true
    private var detectTimeInterval = 0
    private var fpNumSum = 0
    
    // ARKit & mathematical variables
    var camera: ARCamera?
    var currentFrame: ARFrame?
    var peerWorldTransFromARKit: simd_float4x4?
    var anchorFromPeer: ARAnchor?
    var eularAngle: simd_float3?
    var peerEulerangle: simd_float3?
    var peerDirection: simd_float3?
    var peerDistance: Float?
    
    // Data collection variables
    private let featureQueue = DispatchQueue(label: "feature")
    private let collectorQUeue = DispatchQueue(label: "collector")
    private let saveQueue = DispatchQueue(label: "save")

    private var frameNum: Int = 0
    
    // Custom UI components
    private let recordingButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        button.layer.cornerRadius = 40
        button.backgroundColor = .white
        
        let circleLayer = CALayer()
        circleLayer.backgroundColor = UIColor.green.cgColor
        circleLayer.cornerRadius = 20
        circleLayer.frame = CGRect(x: 20, y: 20, width: 40, height: 40)
        
        button.layer.addSublayer(circleLayer)
        button.addTarget(self, action: #selector(ViewController.hitRecordingButton), for: .touchUpInside)
        return button
    }()
    private let deleteAllDataButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 150, height: 30)
        button.layer.cornerRadius = 10
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Delete Data", for: .normal)
        button.addTarget(self, action: #selector(ViewController.clearTempFolder), for: .touchUpInside)
        return button
    }()
    private let clearARObjButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        button.layer.cornerRadius = 10
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Clear", for: .normal)
        button.addTarget(self, action: #selector(ViewController.removeAllAnchorsYouCreated), for: .touchUpInside)
        return button
    }()
    private let featurePointLabel: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 0,
                             y: 0,
                             width: 250,
                             height: 40)
        label.textColor = .black
        label.backgroundColor = .white
        label.layer.cornerRadius = 10
        return label
    }()
    private let featurePointNumDetectButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.backgroundColor = .white
        button.setTitle("Fp", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(ViewController.detectFeaturePointNumber), for: .touchUpInside)
        return button
    }()
    private var circleLayer: CALayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //make sure support arworldtracking
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("do not support ar world tracking")
        }
        
        //set delegate
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = false
        //start ar session
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        
//        sceneView.session.run(configuration)
        
        //disable idletimer cause user may not touch screen for a long time
        UIApplication.shared.isIdleTimerDisabled = true
        
        self.view.addSubview(recordingButton)
        self.view.addSubview(deleteAllDataButton)
        self.view.addSubview(clearARObjButton)
        
        circleLayer = recordingButton.layer.sublayers?.first(where: { $0 is CALayer }) as? CALayer
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //suspend session
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // https://stackoverflow.com/questions/24084941/how-to-get-device-width-and-height
        recordingButton.frame = CGRect(x: UIScreen.main.bounds.size.width/2-40,
                                       y: UIScreen.main.bounds.size.height*3/4,
                                       width: 80, height: 80)
        recordingButton.addSinkAnimation()
        deleteAllDataButton.frame = CGRect(x: 30,
                                           y: 80,
                                           width: 150,
                                           height: 40)
        deleteAllDataButton.addSinkAnimation()
        clearARObjButton.frame = CGRect(x: 280,
                                        y: 80,
                                        width: 80,
                                        height: 40)
        clearARObjButton.addSinkAnimation()
        featurePointLabel.frame = CGRect(x: 40,
                                         y: 160,
                                         width: 250,
                                         height: 40)
        featurePointNumDetectButton.frame = CGRect(x: UIScreen.main.bounds.size.width/2-140,
                                                   y: UIScreen.main.bounds.size.height*3/4+40,
                                                   width: 40,
                                                   height: 40)
        panelButton.addSinkAnimation()
        panelView.layer.cornerRadius = 30
    }
    
    func startup() {
        //create Session
        if niSession == nil {
            niSession = NISession()
            print("create NIsession")
            
            //set a delegate
            niSession?.delegate = self
            sharedTokenWithPeers = false
        }
        
        if mpc == nil {
//            startupMPC()
            currentState = .unknown
        }
        
        if mpc != nil && connectedPeer != nil {
//            startupNI()
        }
    }
    
    //handler of connection
    func connectedToPeer(peer: MCPeerID) {
    }
    
    //handle to disconnect
    func disconnectedToPeer(peer: MCPeerID) {
    }
    
    //share token
    func shareTokenWithPeers(token: NIDiscoveryToken) {
    }
    
    //put new anchor into node
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
    }
    
    //NISessionDelegate Monitoring NearbyObjects
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
    }
    
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
    }
    //monitoring 30fps update
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    
    // ARSessionDelegate Monitoring NearbyObjects
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    }
    
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    }
    
    // handler to connect
    var mapProvider: MCPeerID?
    // handler to data receive
    func dataReceiveHandler(data: Data, peer: MCPeerID) {
    }
    
    func resetWorldOrigin(with myEuler: simd_float3, and peerEuler: simd_float3) {
    }
    
    func addAnchor(anchor: ARAnchor) {
    }
    
    //receive peer token
    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
    }
    
    //handling interruption and suspension
    func sessionWasSuspended(_ session: NISession) {
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
    }
    
    //Hit test function
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
    }
    
    
    @IBAction func flashlight(_ sender: Any) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
                        let alertController = UIAlertController(title: "Flashlight not supported", message: nil, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Understand", style: .default, handler: nil))
                        present(alertController, animated: true)
                        return
                    }
                    
                    do {
                        try device.lockForConfiguration()
                        let torchOn = !device.isTorchActive
                        try device.setTorchModeOn(level: 1.0)
                        device.torchMode = torchOn ? .on : .off
                        device.unlockForConfiguration()
                    } catch {
                        let alertController = UIAlertController(title: "Flashlight is not supported", message: nil, preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Understand", style: .default, handler: nil))
                        present(alertController, animated: true)
                    }
    }
    
    
    @IBAction func popupPanel(_ sender: Any) {
        if isPanelShowing {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                self.panelView.frame = CGRect(x: -250, y: 250, width: 250, height: 200)
            })
            panelButton.setTitle("Panel->", for: .normal)
            isPanelShowing = false
        } else {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                self.panelView.frame = CGRect(x: 0, y: 250, width: 250, height: 200)
            })
            panelButton.setTitle("<-Panel", for: .normal)
            isPanelShowing = true
        }
    }
    
    
    @IBAction func shareSession(_ sender: Any) {
    }
    
    //update visualization information
    func visualisationUpdate(with peer: NINearbyObject) {
    }
    
    //use button to reset tracking
    @IBAction func resetTracking(_ sender: UIButton?) {
    }
    
    //use coachingoverlayview to reset tracking
    @IBAction func resetTracking() {
    }
    
    @IBAction func removeAllAnchorsYouCreated(_ sender: UIButton?) {
    }
    
    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
    }
    
    private func sendARSessionIDTo(peers: [MCPeerID]) {
    }
}

extension ViewController {
    @objc func hitRecordingButton() {
        isRecording.toggle()
        if isRecording {
            circleLayer?.backgroundColor = UIColor.red.cgColor
        } else {
            circleLayer?.backgroundColor = UIColor.green.cgColor
        }
    }
    
    @objc func clearTempFolder() {
    }
    
    @objc func detectFeaturePointNumber() {
    }
}

struct Constants {
    static let ObjectName = "Object"
    static let distanceThereshold: Float = 0.4
    static let frameNum: Int = 2
    static let weight: Float = 0.9
}

extension UIButton {
    
    func addSinkAnimation() {
        self.layer.shadowColor = CGColor.init(red: 0,
                                              green: 0,
                                              blue: 0,
                                              alpha: 1)
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.layer.shadowOpacity = 0.8
        
        self.addTarget(self, action: #selector(self.sinkAction(_:)), for: .touchDown)
        self.addTarget(self, action: #selector(self.sinkReset(_:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(self.sinkReset(_:)), for: .touchUpOutside)
    }
    
    @objc func sinkAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.95)
            sender.layer.shadowOpacity = 0
        }, completion: nil)
    }
    
    @objc func sinkReset(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            sender.transform = CGAffineTransform.identity
            sender.layer.shadowOpacity = 0.8
        }, completion: nil)
    }
    
}
