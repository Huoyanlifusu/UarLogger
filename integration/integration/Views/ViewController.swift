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
    
    // some labels
    @IBOutlet weak var deviceLable: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    //send map button
//    @IBOutlet weak var sendMapButton: UIButton!

    let coachingOverlayView = ARCoachingOverlayView()
    
    //NISession variable
    var niSession: NISession?
    var peerDiscoveryToken: NIDiscoveryToken?
    var sharedTokenWithPeers = false
    var currentState: DistanceDirectionState = .unknown
    enum DistanceDirectionState {
        case unknown, closeUpInFOV, notCloseUpInFOV, outOfFOV
    }
    
    //MPCSession variable
    var mpc: MPCSession?
    var connectedPeer: MCPeerID?
    var peerDisplayName: String?
    var peerSessionIDs = [MCPeerID: String]()
    var sessionIDObservation: NSKeyValueObservation?
    
    //some conditional variable
    var alreadyAdd = false
    var couldDetect = true
    var couldCollectFeature: Bool = false
    private let featureQueue = DispatchQueue(label: "feature")
    
    //some mathematical data
    var camera: ARCamera?
    
    var peerTrans: simd_float4x4?
    var peerTransFromARKit: simd_float4x4?
    
    var anchorFromPeer: ARAnchor?
    
    var eularAngle: simd_float3?
    var peerEulerangle: simd_float3?
    
    //var couldCreateObj: Bool = true
    var peerDirection: simd_float3?
    var peerDistance: Float?
    
    private let collectorQUeue = DispatchQueue(label: "collector")
    private var frameNum: Int = 0
    private let dataCollector = DataCollector()
    private var isRecording = false
    
    private let recordingButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        button.layer.cornerRadius = 40
        button.backgroundColor = .white
        
        let circleLayer = CALayer()
        circleLayer.backgroundColor = UIColor.red.cgColor
        circleLayer.cornerRadius = 20
        circleLayer.frame = CGRect(x: 20, y: 20, width: 40, height: 40)
        
        button.layer.addSublayer(circleLayer)
        button.addTarget(self, action: #selector(ViewController.hitRecordingButton), for: .touchUpInside)
        return button
    }()
    
    private let projectButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0,
                              width: 120, height: 50)
        button.layer.cornerRadius = 10
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.setTitle("menu", for: .normal)
        button.addTarget(self, action: #selector(ViewController.pushProjectMenu), for: .touchUpInside)
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
    
    //viewdidload happen before viewdidappear
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
        
        //set ARSession
        //niSession?.setARSession(sceneView.session)
        
        //set delegate
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = false
        //start ar session
        
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        print("AR Session Started!")
        
        //show feature points in ar experience, usually not used
        //sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        setupCoachingOverlay()
        
        
        //disable idletimer cause user may not touch screen for a long time
        UIApplication.shared.isIdleTimerDisabled = true
        
        sessionIDObservation = observe(\.sceneView.session.identifier, options: [.new]) { object, change in
            print("SessionID changed to: \(change.newValue!)")
            // Tell all other peers about your ARSession's changed ID, so
            // that they can keep track of which ARAnchors are yours.
            guard let multipeerSession = self.mpc else { return }
            self.sendARSessionIDTo(peers: multipeerSession.connectedPeers)
        }
        
        let serialQueue = DispatchQueue(label: "serialQueue")
        self.view.addSubview(recordingButton)
//        self.view.addSubview(projectButton)
        self.view.addSubview(deleteAllDataButton)
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
//        projectButton.frame = CGRect(x: UIScreen.main.bounds.size.width*3/4 - 50,
//                                     y: UIScreen.main.bounds.size.height*3/4 + 50,
//                                     width: 100, height: 50)
        deleteAllDataButton.frame = CGRect(x: 30,
                                           y: 40,
                                           width: 150,
                                           height: 40)
        deleteAllDataButton.addSinkAnimation()
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
            startupMPC()
            currentState = .unknown
        }
        
        if mpc != nil && connectedPeer != nil {
            startupNI()
        }
    }
    
    func startupMPC() {
        if mpc == nil {
            #if targetEnvironment(simulator)
            mpc = MPCSession(service: "zyy-artest",
                             identity: "zyy-artest.simulator",
                             maxPeers: 1)
            #else
            mpc = MPCSession(service: "zyy-artest",
                             identity: "zyy-artest.realdevice",
                             maxPeers: 1)
            #endif
            mpc?.peerConnectedHandler = connectedToPeer
            mpc?.peerDisConnectedHandler = disconnectedToPeer
            mpc?.peerDataHandler = dataReceiveHandler
        }
        mpc?.invalidate()
        mpc?.start()
    }
    
    func startupNI() {
        //create a session
        if let mytoken = niSession?.discoveryToken {
            //share your token
            if !sharedTokenWithPeers {
                shareTokenWithPeers(token: mytoken)
                print("share token!")
            }
            
            //make sure have peerToken
            guard let peerToken = peerDiscoveryToken else {
                return
            }
            
            // set config
            let configuration = NINearbyPeerConfiguration(peerToken: peerToken)
            configuration.isCameraAssistanceEnabled = false
        
            //run session
            niSession?.run(configuration)
            print("welldone")
            
            
        } else {
            fatalError("Could not catch your token.")
        }
    }
    
    //handler of connection
    func connectedToPeer(peer: MCPeerID) {
        guard let myToken = niSession?.discoveryToken else {
            fatalError("Can not find your token while connecting")
        }
        if connectedPeer != nil {
            fatalError("already connected")
        }
        if !sharedTokenWithPeers {
            shareTokenWithPeers(token: myToken)
        }
        connectedPeer = peer
        peerDisplayName = peer.displayName
        DispatchQueue.main.async {
            self.deviceLable.text = "链接对象:" + peer.displayName
        }
    }
    
    //handle to disconnect
    func disconnectedToPeer(peer: MCPeerID) {
        if connectedPeer == peer {
            connectedPeer = nil
            sharedTokenWithPeers = false
        }
    }
    
    //share token
    func shareTokenWithPeers(token: NIDiscoveryToken) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
            fatalError("cannot encode your token")
        }
        self.mpc?.sendDataToAllPeers(data: data)
        sharedTokenWithPeers = true
    }
    
    //put new anchor into node
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let name = anchor.name, name.hasPrefix(Constants.ObjectName) {
            node.addChildNode(loadModel())
            return
        }
        if let participantAnchor = anchor as? ARParticipantAnchor {
            DispatchQueue.main.async {
                print("did add participant")
            }
            node.addChildNode(loadModel())
            return
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multipeerSession = mpc else { return }
        if !multipeerSession.connectedPeers.isEmpty {
            
            // encodeData of collaborativeData
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else { fatalError("Unexpectedly failed to encode collaboration data.") }

            
            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendDataToAllPeers(data: encodedData)
        } else {
            // 未匹配时
//            print("Deferred sending collaboration to later because there are no peers.")
        }
    }
    
    //NISessionDelegate Monitoring NearbyObjects
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        DispatchQueue(label: "serialQueue").async {
            if self.couldDetect == true {
                
                guard let peerToken = self.peerDiscoveryToken else {
                    fatalError("don't have peer token")
                }
                let nearbyOject = nearbyObjects.first { (obj) -> Bool in
                    return obj.discoveryToken == peerToken
                }
                guard let nearbyObjectUpdate = nearbyOject else {
                    return
                }
                self.peerTrans = session.worldTransform(for: nearbyObjectUpdate)
                self.visualisationUpdate(with: nearbyObjectUpdate)
            }
        }
        //当处理数据时停止实时测量
    }
    
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }
        // Find the right peer.
        let peerObj = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }
        if peerObj == nil {
            return
        }
        currentState = .unknown
        switch reason {
        case .peerEnded:
            // The peer token is no longer valid.
            peerDiscoveryToken = nil
            // The peer stopped communicating, so invalidate the session because
            // it's finished.
            session.invalidate()
            // Restart the sequence to see if the peer comes back.
            startup()
            // Update the app's display.
            infoLabel.text = "Peer Ended"
        case .timeout:
            // The peer timed out, but the session is valid.
            // If the configuration is valid, run the session again.
            if let config = session.configuration {
                session.run(config)
            }
            infoLabel.text = "Peer Timeout"
        default:
            fatalError("Unknown and unhandled NINearbyObject.RemovalReason")
        }
    }
    var count: Int = 0
    //monitoring 30fps update
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        camera = frame.camera
        StoredData.camTrans = camera?.transform
        if isRecording {
            guard let arkitData = StoredData.peerPosInARKit,
                  let niData = StoredData.peerPosInNI else { return }
            collectorQUeue.async { [self] in
                print("采集第\(frameNum)数据")
                self.dataCollector.collectData(arkitData, niData, frame, frameNum)
                frameNum += 1
            }
        }
    }
    
    // ARSessionDelegate Monitoring NearbyObjects
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let participantAnchor = anchor as? ARParticipantAnchor {
                //messageLabel.displayMessage("Established joint experience with a peer.")
                peerTransFromARKit = participantAnchor.transform
                StoredData.peerPosInARKit = participantAnchor.transform.columns.3
                DispatchQueue.main.async {
                    print("ar data is ready")
                }
            }
        }
    }
    
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let participantAnchor = anchor as? ARParticipantAnchor {
                //messageLabel.displayMessage("Established joint experience with a peer.")
                peerTransFromARKit = participantAnchor.transform
                StoredData.peerPosInARKit = participantAnchor.transform.columns.3
                DispatchQueue.main.async {
                    print("ar data is updated")
                }
            }
        }
    }
    
    // handler to connect
    var mapProvider: MCPeerID?
    // handler to data receive
    func dataReceiveHandler(data: Data, peer: MCPeerID) {
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            sceneView.session.update(with: collaborationData)
        }
        if let discoverytoken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
            peerDidShareDiscoveryToken(peer: peer, token: discoverytoken)
        }
        if let pos = try? JSONDecoder().decode(simd_float4.self, from: data) {
            guard let camTrans = StoredData.camTrans else { print("no cam")
                return }
            if abs(pos.w - 100) < 1 {
                // nothing
            }
            else {
                guard let direction = peerDirection else { couldDetect = true; return }
                guard let distance = peerDistance else { couldDetect = true; return }
                let peerPos = alignDistanceWithNI(distance: distance, direction: direction)
                //算法1 使用两次位姿旋转矩阵
                //let Pos = coordinateAlignment(direction: direction, distance: distance, myCam: cam, peerEuler: peerEulerangle!, pos: pos)
                //使用NI库自带的peer位姿矩阵 和 peercam坐标系坐标 求解世界坐标系坐标
                guard let peerT = peerTransFromARKit else { couldDetect = true; return }
                let peerTrans: simd_float4x4 = simd_float4x4(peerT.columns.0,
                                                         peerT.columns.1,
                                                         peerT.columns.2,
                                                         Constants.weight * peerT.columns.3 + (1 - Constants.weight) * peerPos)
                guard let anchor = anchorFromPeer else { couldDetect = true; return}
                let objPos = camTrans * peerTrans * pos
                let objTrans = simd_float4x4(anchor.transform.columns.0,
                                             anchor.transform.columns.1,
                                             anchor.transform.columns.2,
                                             objPos)
                let newAnchor = ARAnchor(name: Constants.ObjectName, transform: objTrans)
                //算法结束 添加ar实体
                addAnchor(anchor: newAnchor)
                couldDetect = true
                if let e = optimizeAnchorPos(with: anchor), e != nil {
                    let originOffset = e
                    let x_column = simd_float4(1, 0, 0, 0)
                    let y_column = simd_float4(0, 1, 0, 0)
                    let z_column = simd_float4(0, 0, 1, 0)
                    //构造列主序矩阵
                    sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4(columns: (x_column,y_column,z_column,originOffset)))
                }
            }
        }
        if let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
            anchorFromPeer = anchor
        }
        if let eulerangle = try? JSONDecoder().decode(simd_float3.self, from: data) {
            peerEulerangle = eulerangle
            //resetWorldOrigin(with: eularangle, and: peerEulerangle)
        }
    }
    
    func resetWorldOrigin(with myEuler: simd_float3, and peerEuler: simd_float3) {
        let newWorldTransform = correctPose(with: peerEuler, using: myEuler)
        sceneView.session.setWorldOrigin(relativeTransform: newWorldTransform)
    }
    
    func addAnchor(anchor: ARAnchor) {
        sceneView.session.add(anchor: anchor)
    }
    
    //receive peer token
    func peerDidShareDiscoveryToken(peer: MCPeerID, token: NIDiscoveryToken) {
        if connectedPeer != peer {
            fatalError("receive token from unexpected token")
        }
        peerDiscoveryToken = token
        //create a config
        startupNI()
    }
    
    //handling interruption and suspension
    func sessionWasSuspended(_ session: NISession) {
        infoLabel.text = "Session was suspended"
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        if let config = self.niSession?.configuration {
            session.run(config)
        } else {
            // Create a valid configuration.
            startup()
        }
    }
    
    //Hit test function
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: sceneView)
            guard let arRayCastQuery = sceneView
                .raycastQuery(from: location,
                              allowing: .estimatedPlane,
                              alignment: .horizontal)
            else {
                return
            }
            guard let result = sceneView.session.raycast(arRayCastQuery).first
            else {
                return
            }
            
            let anchor = ARAnchor(name: Constants.ObjectName, transform: result.worldTransform)
            sceneView.session.add(anchor: anchor)
            guard let anchorData = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
            else { fatalError("can't encode anchor") }
            //send anchor data
            self.mpc?.sendDataToAllPeers(data: anchorData)
            
            guard let cam = camera else { return }
            guard let eulerData = try? JSONEncoder().encode(cam.eulerAngles) else { fatalError("dont have your cam") }
            self.mpc?.sendDataToAllPeers(data: eulerData)
            // 世界坐标 - 相机坐标
            let pos = cam.transform.inverse * result.worldTransform.columns.3
            guard let posData = try? JSONEncoder().encode(pos) else { fatalError("cannot encode simd_float3x3") }
            self.mpc?.sendDataToAllPeers(data: posData)
        }
    }
    
    
    @IBAction func shareSession(_ sender: Any) {
        sceneView.session.getCurrentWorldMap(completionHandler: {
            worldmap, error in
            guard let map = worldmap else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true) else {
                fatalError("Cannot archive world map!")
            }
            self.mpc?.sendDataToAllPeers(data: data)
        })
    }
    
    //get distance&direction state
    func getDistanceDirectionState(from nearbyObject: NINearbyObject) -> DistanceDirectionState {
        if nearbyObject.distance == nil && nearbyObject.direction == nil {
            return .unknown
        }

        let isNearby = nearbyObject.distance.map(isNearby(_:)) ?? false
        let directionAvailable = nearbyObject.direction != nil

        if isNearby && directionAvailable {
            return .closeUpInFOV
        }

        if !isNearby && directionAvailable {
            return .notCloseUpInFOV
        }

        return .outOfFOV
    }
    
    func isNearby(_ distance: Float) -> Bool {
        return distance < Constants.distanceThereshold
    }
    
    //load object model
    func loadModel() -> SCNNode {
        let sphere = SCNSphere(radius: 0.1)
        sphere.firstMaterial?.diffuse.contents = "worldmap.jpg"
        let node = SCNNode(geometry: sphere)
        return node
    }
    
    //update visualization information
    func visualisationUpdate(with peer: NINearbyObject) {
        // Animate into the next visuals.
        guard let direction = peer.direction else { return }
        peerDirection = direction
        guard let distance = peer.distance else { return }
        peerDistance = distance
        let camVec = alignDistanceWithNI(distance: distance, direction: direction)
        StoredData.peerPosInNI = (StoredData.camTrans! * camVec).normalize()
    }
    
    @IBAction func setWorldOrigin(_ sender: Any) {
        guard let cam = camera else { return }
        let euler = simd_make_float4(cam.eulerAngles, 100)
        guard let data = try? JSONEncoder().encode(euler) else {
            print("cannot encode your eulerangle!")
            return
        }
        self.mpc?.sendDataToAllPeers(data: data)
    }
    
    func addCoordinateAnchor(using anchorName: String, with transform: simd_float4x4) {
        let coordinate = ARAnchor(name: anchorName, transform: transform)
        sceneView.session.add(anchor: coordinate)
    }
    
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
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
    
    @IBAction func collectFeature(_ sender: Any) {
        couldCollectFeature = true
    }
    
    //use button to reset tracking
    @IBAction func resetTracking(_ sender: UIButton?) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    //use coachingoverlayview to reset tracking
    @IBAction func resetTracking() {
        guard let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration else { print("A configuration is required"); return }
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func removeAllAnchorsYouCreated(_ sender: UIButton?) {
        guard let frame = sceneView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == sceneView.session.identifier.uuidString {
                sceneView.session.remove(anchor: anchor)
            }
        }
    }
    
    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
        guard let frame = sceneView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier {
                sceneView.session.remove(anchor: anchor)
            }
        }
    }
    
    private func sendARSessionIDTo(peers: [MCPeerID]) {
        guard let multipeerSession = mpc else { return }
        let idString = sceneView.session.identifier.uuidString
        let command = "SessionID:" + idString
        // 将字符串类型转为data
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendDataToAllPeers(data: commandData)
        }
    }
}

extension ViewController {
    @objc func hitRecordingButton() {
        isRecording.toggle()
        if isRecording {
            if RecordConfig.fileURL == nil {
                initFilePath()
            }
            print("开始采集")
        } else {
            print("结束采集")
        }
    }
    
    @objc func pushProjectMenu() {
        let swiftUIView = ProjectMenu() // 替换成您的 SwiftUI 视图名称
        let hostingController = UIHostingController(rootView: swiftUIView)
        DispatchQueue.main.async {
            self.present(hostingController, animated: true, completion: nil)
        }
    }
    
    @objc func clearTempFolder() {
        let queue = DispatchQueue(label: "delete")
        queue.async {
            let fileManager = FileManager.default
            let tempFolderPath = NSTemporaryDirectory()
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
                for filePath in filePaths {
                    try fileManager.removeItem(atPath: tempFolderPath + filePath)
                }
            } catch {
                print("Could not clear temp folder: \(error)")
            }
        }
    }
    
    func initFilePath() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "collect.csv"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        RecordConfig.fileURL = fileURL
    }
}

struct Constants {
    static let ObjectName = "Object"
    static let distanceThereshold: Float = 0.4
    static let frameNum: Int = 2
    static let weight: Float = 0.9
}
