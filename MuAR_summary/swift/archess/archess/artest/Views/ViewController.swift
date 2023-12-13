//
//  ViewController.swift
//  artest
//
//  Created by 张裕阳 on 2022/9/22.
//

// 发送码及意义
//  1——收到该信号表示开始游戏，已经建立棋盘
//  2——收到该信号表示对方先手，己方后手
//  3——收到该信号表示己方先手，对方后手
//  4——收到该信号表示己方执白，对方执黑
//  5——收到该信号表示己方执黑，对方执白
//  6--收到该信号表示对方回合已经结束，己方回合开始
//  7--收到该信号表示对方获胜，您输了
//  8--收到该信号表示游戏即将重启


import Foundation
import UIKit
import ARKit
import NearbyInteraction
import MultipeerConnectivity
import RealityKit
import SceneKit
import SceneKit.ModelIO


@available(iOS 16.0, *)
class ViewController: UIViewController, NISessionDelegate, ARSessionDelegate, ARSCNViewDelegate {
    
    //Main scene
    @IBOutlet weak var sceneView: ARSCNView!
    
    //some labels
    @IBOutlet weak var deviceLable: UILabel!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    //detail view
    @IBOutlet weak var DetailView: UIView!
//    @IBOutlet weak var DetailUpArrow: UIImageView!
//    @IBOutlet weak var DetailDownArrow: UIImageView!
    
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
    var firstClick = false
    
    //chessGameLogicVariable
    var canPlaceBoard = true
    
    //some mathematical data
    var camera: ARCamera?
    var objPos: simd_float4?
    
    var peerTrans: simd_float4x4?
    var peerTransFromARKit: simd_float4x4?
    
    var anchorFromPeer: ARAnchor?
    var chessBoardAnchorFromPeer: ARAnchor?
    var blackChessAnchorFromPeer: ARAnchor?
    var whiteChessAnchorFromPeer: ARAnchor?
    
    var eulerangleForSending: simd_float3?
    var peerEulerangle: simd_float3?
    var peerPos: simd_float4?
    
    //var couldCreateObj: Bool = true
    var peerAnchor: ARAnchor?
    var peerDirection: simd_float3?
    var peerDistance: Float?
    
    //var of chessGame
    var originNode: SCNNode?
    
    
    //退出按钮
    private let exitButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 0,
                                            width: 60,
                                            height: 60))
        button.backgroundColor = .black
        button.layer.cornerRadius = 30
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.3
        //button.layer.masksToBounds = true
        let image = UIImage(systemName: "arrow.left.circle",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 32,
                                                                           weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    //重启按钮
    private let restartButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0,
                                            y: 0,
                                            width: 60,
                                            height: 60))
        button.backgroundColor = .black
        button.layer.cornerRadius = 30
        button.layer.shadowRadius = 10
        button.layer.shadowOpacity = 0.3
        
        let image = UIImage(systemName: "arrow.clockwise",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 32,
                                                                           weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    //文本信息
    private let myTurnLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: 0,
                                          width: 180,
                                          height: 30))
        label.font = UIFont(name: "hongleisim-Regular", size: 30)
        label.text = "您的回合"
        return label
    }()
    
    private let peerTurnLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: 0,
                                          width: 180,
                                          height: 30))
        label.text = "对方回合"
        label.font = UIFont(name: "hongleisim-Regular", size: 30)
        return label
    }()
    
    private let playImageView: UIImageView = {
        let image = UIImage(systemName: "play.fill",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28,
                                                                           weight: .medium))
        image?.withTintColor(.black)
        let view = UIImageView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: 25,
                                             height: 25))
        view.image = image
        return view
    }()
    
    
    func rotateAnimation(with angle: CGFloat) {
        let animator = UIViewPropertyAnimator(duration: 1,
                                              curve: .linear,
                                              animations: { [unowned self] in
            self.playImageView.transform = CGAffineTransform(rotationAngle: angle)
        })
        
        animator.startAnimation()
    }
    
    
    
    
    //继承重写
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
        //add light to show color
        sceneView.automaticallyUpdatesLighting = true
        
        //start ar session
        
        //make configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        print("AR Session Started!")
        
        view.addSubview(exitButton)
        view.addSubview(restartButton)
        
        
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
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //suspend session
        sceneView.session.pause()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //退出按钮
        exitButton.frame = CGRect(x: view.frame.size.width - 70,
                                  y: view.frame.size.height - 100,
                                  width: 60,
                                  height: 60)
        exitButton.addTarget(self, action: #selector(didExit), for: .touchUpInside)
        //重启按钮
        restartButton.frame = CGRect(x: 30,
                                     y: view.frame.size.height - 100,
                                     width: 60,
                                     height: 60)
        restartButton.addTarget(self, action: #selector(didRestart), for: .touchUpInside)
        //文本
        myTurnLabel.frame = CGRect(x: 50,
                                   y: 30,
                                   width: 180,
                                   height: 30)
        peerTurnLabel.frame = CGRect(x: 200,
                                     y: 30,
                                     width: 180,
                                     height: 30)
        playImageView.frame = CGRect(x: 170,
                                     y: 35,
                                     width: 25,
                                     height: 25)
        
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
            mpc = MPCSession(service: "zyy-artest", identity: "zyy-artest.simulator", maxPeers: 1)
            #else
            mpc = MPCSession(service: "zyy-artest", identity: "zyy-artest.realdevice", maxPeers: 1)
            #endif
            mpc?.peerConnectedHandler = connectedToPeer
            mpc?.peerDisConnectedHandler = disconnectedToPeer
            mpc?.peerDataHandler = dataReceiveHandler
        }
        mpc?.invalidate()
        mpc?.start()
        DispatchQueue.main.async {
            self.setInfoLabel(with: "正在寻找同伴")
            self.setDeviceLabel(with: "未连接")
        }
    }
    
    func startupNI() {
        //create a session
        
        if let mytoken = niSession?.discoveryToken {
            //share your token
            if !sharedTokenWithPeers {
                shareTokenWithPeers(token: mytoken)
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
            
            
        } else {
            fatalError("Could not catch your token.")
        }
    }
    
    @objc private func didExit() {
        let alert = UIAlertController(title: "提醒",
                                      message: "是否返回主界面，当前所有内容都会丢失",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确认",
                                      style: .destructive){ (action) in
            //暂停mpc
            if self.mpc != nil {
                self.mpc?.suspend()
                self.mpc = nil
            }
            resetMyChessInfo()
            self.originNode = nil
            
            self.performSegue(withIdentifier: "exitToMain", sender: self)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func didRestart() {
        let alert = UIAlertController(title: "警告",
                                      message: "您确定要重启本局游戏吗",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确认",
                                      style: .destructive) { (action) in
            self.restart()
        })
        alert.addAction(UIAlertAction(title: "取消",
                                      style: .cancel))
        present(alert, animated: true)
    }
    
    func restart() {
        sendCodeToPeer(with: 8)
        //参数重置
        resetMyChessInfo()
        
        firstClick = false
        canPlaceBoard = true
        
        originNode = nil
        
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func restartByCode() {
        resetMyChessInfo()
        
        firstClick = false
        canPlaceBoard = true
        //AR相关内存清空
        originNode = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
            self.setInfoLabel(with: "已连接，请您点击并开始游戏")
            self.setDeviceLabel(with: "链接对象" + peer.displayName)
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
    
    //渲染器
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        //渲染棋盘
        if let name = anchor.name, name.hasPrefix(Constants.chessBoardName) {
            node.addChildNode(renderChessBoard())
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            node.addChildNode(ambientNode)
            DispatchQueue.main.async {
                self.infoLabel.text = "渲染结束"
            }
            return
        }
        if let name = anchor.name, name.hasPrefix(Constants.peerChessBoardName) {
            node.addChildNode(renderChessBoard())
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            node.addChildNode(ambientNode)
            DispatchQueue.main.async {
                self.infoLabel.text = "渲染结束"
            }
            return
        }
        if let name = anchor.name, name.hasPrefix(Constants.blackChessName) {
            renderChess(with: anchor, and: 1)
        }
        if let name = anchor.name, name.hasPrefix(Constants.whiteChessName) {
            renderChess(with: anchor, and: 2)
        }
        //渲染同伴
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
    
    //第一种渲染方法
    func renderChessBoard() -> SCNNode {
        guard let url = Bundle.main.url(forResource: "chessBoard", withExtension: "usdz") else { fatalError("can not find resource url") }
        
        guard let boardNode = SCNReferenceNode(url: url) else { fatalError("cannot create chessboard node") }
        originNode = boardNode
        boardNode.load()
        //调整棋盘参数
        boardNode.scale = SCNVector3(0.3,0.3,0.3)
        //添加棋盘节点
        MyChessInfo.couldInit = true
        initChessGame()
        return boardNode
    }
    
    //渲染棋子
    func renderChess(with anchor: ARAnchor, and color: Int) {
        guard let originAnchor = sceneView.anchor(for: originNode!) else {print("no origin anchor"); return }
        var localTrans = originAnchor.transform.inverse * anchor.transform.columns.3
        localTrans.y = 0.055
        localTrans.x = Float(lroundf(localTrans.x * Constants.scaleFromWorldToLocal * 10)) / Float(10)
        localTrans.z = Float(lroundf(localTrans.z * Constants.scaleFromWorldToLocal * 10)) / Float(10)
        
        
        let indexOfX: Int = lroundf(localTrans.x * 10)
        let indexOfY: Int = lroundf(localTrans.z * 10)
        
        //判断是否出界
        if indexOfX > 4 || indexOfX < -4 || indexOfY > 4 || indexOfY < -4 {
            DispatchQueue.main.async {
                self.setInfoLabel(with: "放置位置超出范围")
            }
            MyChessInfo.canIPlaceChess = true
            return
        }
        //判断是否已经落子
        if thereIsAChess(indexOfX: indexOfX, indexOfY: indexOfY) == true {
            DispatchQueue.main.async {
                self.setInfoLabel(with: "该处已经有棋子")
            }
            MyChessInfo.canIPlaceChess = true
            return
        }
        
        if color == 1 {
            originNode!.addChildNode(loadBlackChess(with: localTrans))
        } else {
            originNode!.addChildNode(loadWhiteChess(with: localTrans))
        }
        updateIndexArray(indexOfX: indexOfX, indexOfY: indexOfY, with: color)
        
        if MyChessInfo.myChessNum >= 5 {
            if WhoIsWinner(MyChessInfo.IndexArray) == MyChessInfo.myChessColor {
                MyChessInfo.canIPlaceChess = false
                sendCodeToPeer(with: 7)
                DispatchQueue.main.async {
                    self.setInfoLabel(with: "您胜利了！")
                    self.setDeviceLabel(with: "游戏结束")
                }
                return
            } else {
                MyChessInfo.canIPlaceChess = false
                //不传输anchor，直接传输坐标
                let indexArray: [Int] = [indexOfX, indexOfY]
                guard let indexData = try? JSONEncoder().encode(indexArray) else { fatalError("can not encode indexData") }
                guard let multipeer = mpc else { fatalError("do not connect with peer") }
                multipeer.sendDataToAllPeers(data: indexData)
                //己方UI调整
                DispatchQueue.main.async {
                    self.rotateAnimation(with: 0)
                    self.myTurnLabel.alpha = Constants.peerTurnAlpha
                    self.peerTurnLabel.alpha = Constants.myTurnAlpha
                }
                //通知对方UI调整
                sendCodeToPeer(with: 6)
                return
            }
        } else {
            MyChessInfo.canIPlaceChess = false
            //不传输anchor，直接传输坐标
            let indexArray: [Int] = [indexOfX, indexOfY]
            guard let indexData = try? JSONEncoder().encode(indexArray) else { fatalError("can not encode indexData") }
            guard let multipeer = mpc else { fatalError("do not connect with peer") }
            multipeer.sendDataToAllPeers(data: indexData)
            //己方UI调整
            DispatchQueue.main.async {
                self.rotateAnimation(with: 0)
                self.myTurnLabel.alpha = Constants.peerTurnAlpha
                self.peerTurnLabel.alpha = Constants.myTurnAlpha
            }
            sendCodeToPeer(with: 6)
            return
        }
    }
    
    //渲染同伴的棋子
    func renderChessWithIndex(_ index: [Int]) {
        //坐标换算
        let xAxis = Float(index[0])/10.0
        let zAxis = Float(index[1])/10.0
        let localTrans = simd_float4(xAxis, 0.055, zAxis, 1)
        
        //渲染
        if MyChessInfo.myChessColor == 1 {
            originNode!.addChildNode(loadWhiteChess(with: localTrans))
            updateIndexArray(indexOfX: index[0], indexOfY: index[1], with: 2)
        }
        if MyChessInfo.myChessColor == 2 {
            originNode!.addChildNode(loadBlackChess(with: localTrans))
            updateIndexArray(indexOfX: index[0], indexOfY: index[1], with: 1)
        }
        //渲染后才可以放置自己的棋子
        MyChessInfo.canIPlaceChess = true
        DispatchQueue.main.async {
            self.rotateAnimation(with: .pi)
            
            self.myTurnLabel.alpha = Constants.myTurnAlpha
            self.peerTurnLabel.alpha = Constants.peerTurnAlpha
        }
        print("rendered!")
    }
    
    //load object model
    func loadModel() -> SCNNode {
        let sphere = SCNSphere(radius: 0.04)
        sphere.firstMaterial?.diffuse.contents = "worldmap.jpg"
        let node = SCNNode(geometry: sphere)
        return node
    }
    
    //指定位置放置棋子
    func loadBlackChess(with pos: simd_float4) -> SCNNode {
        guard let url = Bundle.main.url(forResource: "blackChess", withExtension: "usdz") else { fatalError("can not find resource url") }
        guard let node = SCNReferenceNode(url: url) else { fatalError("cannot establish black chess node") }
        
        node.simdTransform.columns.3 = pos
        node.simdScale = simd_float3(0.5,0.2,0.5)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        let lightNode = SCNNode()
        lightNode.light = directionalLight
        lightNode.position = SCNVector3(x: pos.x, y: pos.y, z: pos.z) + SCNVector3(x: 0, y: 1, z: 0)
        
        node.load()
        node.addChildNode(lightNode)
        
        return node
    }
    
    func loadWhiteChess(with pos: simd_float4) -> SCNNode {
        guard let url = Bundle.main.url(forResource: "whiteChess", withExtension: "usdz") else { fatalError("can not find resource url") }
        guard let node = SCNReferenceNode(url: url) else { fatalError("cannot establish black chess node") }
        
        node.simdTransform.columns.3 = pos
        node.simdScale = simd_float3(0.5,0.2,0.5)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        let lightNode = SCNNode()
        lightNode.light = directionalLight
        lightNode.position = SCNVector3(x: pos.x, y: pos.y, z: pos.z) + SCNVector3(x: 0, y: 1, z: 0)
        
        node.load()
        node.addChildNode(lightNode)
        
        return node
    }
    
    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        guard let multipeerSession = mpc else { return }
        if !multipeerSession.connectedPeers.isEmpty {
            guard let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: true)
            else { fatalError("Unexpectedly failed to encode collaboration data.") }
            // Use reliable mode if the data is critical, and unreliable mode if the data is optional.
            let dataIsCritical = data.priority == .critical
            multipeerSession.sendDataWithPriority(encodedData, priority: dataIsCritical)
        } else {
            print("Deferred sending collaboration to later because there are no peers.")
        }
    }
    
    //NISessionDelegate Monitoring NearbyObjects
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        //当处理数据时停止实时测量
        
        guard let peerToken = peerDiscoveryToken else {
            fatalError("don't have peer token")
        }
        let nearbyOject = nearbyObjects.first { (obj) -> Bool in
            return obj.discoveryToken == peerToken
        }
        guard let nearbyObjectUpdate = nearbyOject else {
            return
        }
        peerTrans = session.worldTransform(for: nearbyObjectUpdate)
        visualisationUpdate(with: nearbyObjectUpdate)
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
            //infoLabel.text = "Peer Ended"
        case .timeout:
            
            // The peer timed out, but the session is valid.
            // If the configuration is valid, run the session again.
            if let config = session.configuration {
                session.run(config)
            }
            //infoLabel.text = "Peer Timeout"
        default:
            fatalError("Unknown and unhandled NINearbyObject.RemovalReason")
        }
    }
    
    
    
    var count: Int = 0
//    var previousConfig: ARConfiguration?
//    var previousFrame: ARFrame?
//    var buffer: [ARFrame] = []
//    var needStore: Bool = false
    //monitoring 30fps update
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        previousConfig = session.configuration
        camera = frame.camera
//        if frame != nil {
//            previousFrame = frame
//            buffer.append(previousFrame!)
//        }
//
//
//        //假设此处需要保存
//        if needStore {
//            guard let previousFrameData = try? NSKeyedArchiver.archivedData(withRootObject: buffer, requiringSecureCoding: true) else {
//                fatalError("cannot restore frame buffer")
//            }
//            guard let previousConfigData = try? NSKeyedArchiver.archivedData(withRootObject: previousConfig, requiringSecureCoding: true) else {
//                fatalError("cannot restore config")
//            }
//        }
    
        
    }
    
    var mapData: Data?
    func storeWorldMap() {
        guard let frame = sceneView.session.currentFrame else { return }
        if frame.worldMappingStatus == .mapped {
            sceneView.session.getCurrentWorldMap(completionHandler: { (map, error) in
                guard let worldmap = map else { fatalError("can not find worldmap") }
                
                let mapdata = try? NSKeyedArchiver.archivedData(withRootObject: worldmap, requiringSecureCoding: true)
                self.mapData = mapdata
            })
        }
    }
    
    func loadMap() {
        guard let data = self.mapData else {return}
        
        do {
            let map = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
        } catch {
            fatalError("can not load map")
        }
    }
    
    
    
    //ARSessionDelegate Monitoring NearbyObjects
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let participantAnchor = anchor as? ARParticipantAnchor {
                peerTransFromARKit = participantAnchor.transform
            }
        }
    }
    
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    }
    
    //handler to connect
    
    var mapProvider: MCPeerID?
    //handler to data receive
    func dataReceiveHandler(data: Data, peer: MCPeerID) {
        //经测试 可以收到collaborationdata
        if let collaborationData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARSession.CollaborationData.self, from: data) {
            sceneView.session.update(with: collaborationData)
        }
        
        //NI通信token
        if let discoverytoken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) {
            peerDidShareDiscoveryToken(peer: peer, token: discoverytoken)
        }
        if let pos = try? JSONDecoder().decode(simd_float4.self, from: data) {
            if canPlaceBoard == true {
                guard let boardAnchor = chessBoardAnchorFromPeer else { print("未收到棋盘anchor信息"); return }
                addPeerAnchor(with: boardAnchor, and: pos)
                
                canPlaceBoard = false
            } else {
                if MyChessInfo.myChessColor == 1 {
                    guard let peerChessAnchor = whiteChessAnchorFromPeer else { fatalError("no peer white chess anchor") }
                    addPeerAnchor(with: peerChessAnchor, and: pos)
                } else if MyChessInfo.myChessColor == 2 {
                    guard let peerChessAnchor = blackChessAnchorFromPeer else { fatalError("no peer black chess anchor") }
                    addPeerAnchor(with: peerChessAnchor, and: pos)
                }
            }
        }
        if let index = try? JSONDecoder().decode([Int].self, from: data) {
            print("\(index)")
            renderChessWithIndex(index)
        }
        if let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
            if let anchor = anchor as? ARParticipantAnchor {
                anchorFromPeer = anchor
            }
            if anchor.name == Constants.chessBoardName {
                chessBoardAnchorFromPeer = ARAnchor(name: Constants.peerChessBoardName, transform: anchor.transform)
            }
            if anchor.name == Constants.blackChessName {
                blackChessAnchorFromPeer = ARAnchor(name: Constants.blackChessName, transform: anchor.transform)
            }
            if anchor.name == Constants.whiteChessName {
                whiteChessAnchorFromPeer = ARAnchor(name: Constants.whiteChessName, transform: anchor.transform)
            }
        }
        
        if let code = try? JSONDecoder().decode(Int.self, from: data) {
            switch code {
            case 1:
                firstClick = true
                MyChessInfo.couldInit = false
                return
            case 2:
                DispatchQueue.main.async {
                    self.myTurnLabel.alpha = Constants.peerTurnAlpha
                    self.peerTurnLabel.alpha = Constants.myTurnAlpha
                }
                MyChessInfo.myChessOrder = 2
                return
            case 3:
                MyChessInfo.canIPlaceChess = true
                //rotate play image
                DispatchQueue.main.async {
                    self.rotateAnimation(with: .pi)
                    self.myTurnLabel.alpha = Constants.myTurnAlpha
                    self.peerTurnLabel.alpha = Constants.peerTurnAlpha
                }
                MyChessInfo.myChessOrder = 1
                return
            case 4:
                MyChessInfo.myChessColor = 2
                return
            case 5:
                MyChessInfo.myChessColor = 1
                return
            case 6:
                MyChessInfo.canIPlaceChess = true
                DispatchQueue.main.async {
                    self.myTurnLabel.alpha = Constants.myTurnAlpha
                    self.peerTurnLabel.alpha = Constants.peerTurnAlpha
                    self.rotateAnimation(with: .pi)
                }
                return
            case 7:
                MyChessInfo.canIPlaceChess = false
                DispatchQueue.main.async {
                    self.setInfoLabel(with: "您输了！")
                    self.setDeviceLabel(with: "游戏结束！")
                }
                return
            case 8:
                restartByCode()
                return
            default:
                return
            }
            
        }
        
    }
    
    func addPeerAnchor(with anchor: ARAnchor, and pos: simd_float4) {
        //使用NI数据进行两次位姿转换 Pcam->MyCam->MyWorld
        //使用NI数据进行两次位姿转换 Pcam->MyCam->MyWorld
        guard let cam = camera else { return }
        guard let direction = peerDirection else { return }
        guard let distance = peerDistance else { return }
        
        let peerPos = alignDistanceWithNI(distance: distance, direction: direction)
        
        //使用NI库自带的peer位姿矩阵 和 peercam坐标系坐标 求解世界坐标系坐标
        guard let peerT = peerTransFromARKit else { print("not peerT!");return }
        
        let peerTrans: simd_float4x4 = simd_float4x4(peerT.columns.0,
                                                 peerT.columns.1,
                                                 peerT.columns.2,
                                                 Constants.weight * peerT.columns.3 + (1 - Constants.weight) * peerPos)
        
        let objPos = cam.transform * peerTrans * pos
        let objTrans = simd_float4x4(anchor.transform.columns.0,
                                     anchor.transform.columns.1,
                                     anchor.transform.columns.2,
                                     objPos)
        
        let newAnchor = ARAnchor(name: anchor.name!, transform: objTrans)
        
        //如果是同伴传来的棋盘 直接添加anchor进行渲染
        if anchor.name == Constants.peerChessBoardName {
            let peerChessBoardAnchor = ARAnchor(name: "peerBoard", transform: newAnchor.transform)
            sceneView.session.add(anchor: peerChessBoardAnchor)
            return
        }
        
        print("成功添加peer传来的" + "\(anchor.name!)" + "物体")
        sceneView.session.add(anchor: newAnchor)
        
        
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
        //infoLabel.text = "Session was suspended"
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        if let config = self.niSession?.configuration {
            session.run(config)
        } else {
            // Create a valid configuration.
            startup()
        }
    }
    
    
    
    func sendCodeToPeer(with number: Int) {
        guard let multipeer = mpc else { fatalError("No peer connected") }
        guard let codeData = try? JSONEncoder().encode(number) else { fatalError("cannot encode this data") }
        multipeer.sendDataToAllPeers(data: codeData)
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
            guard let rayCastResult = sceneView.session.raycast(arRayCastQuery).first
            else {
                return
            }
            
            //trying to use SceneKit hitTest
//            guard let hitTestResult = sceneView.hitTest(location) else { return }
            
            
            if firstClick == false && canPlaceBoard {
                //create and add chessboard anchor
                let anchor = ARAnchor(name: Constants.chessBoardName, transform: rayCastResult.worldTransform)
                sceneView.session.add(anchor: anchor)
                guard let anchorData = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                else { fatalError("can't encode anchor") }
                //send anchor data
                self.mpc?.sendDataToAllPeers(data: anchorData)
                
                //change the state that you hit the first click
                sendCodeToPeer(with: 1)
                
                guard let cam = self.camera else { return }
                
                //unused euler data
    //            guard let eulerData = try? JSONEncoder().encode(cam.eulerAngles) else { fatalError("dont have your cam") }
    //            self.mpc?.sendDataToAllPeers(data: eulerData)
                
                let pos = cam.transform.inverse * rayCastResult.worldTransform.columns.3
                guard let posData = try? JSONEncoder().encode(pos) else { fatalError("cannot encode simd_float3x3") }
                self.mpc?.sendDataToAllPeers(data: posData)
                
                
                //有时arkit会多次检测tap，防止程序崩溃，同时保证此时不会产生新的board
                canPlaceBoard = false
                let _ = Timer.scheduledTimer(withTimeInterval: 0.3,
                                             repeats: false,
                                             block: { timer in
                    self.firstClick = true
                })
                
            }
            if firstClick == true && MyChessInfo.canIPlaceChess {
                MyChessInfo.canIPlaceChess = false
                //create and add chess anchor
                let anchor: ARAnchor?
                if MyChessInfo.myChessColor == 1 {
                    anchor = ARAnchor(name: Constants.blackChessName,
                                      transform: rayCastResult.worldTransform)
                } else if MyChessInfo.myChessColor == 2 {
                    anchor = ARAnchor(name: Constants.whiteChessName,
                                      transform: rayCastResult.worldTransform)
                } else {
                    fatalError("can not touch before choosing a color")
                }
                //add anchor in scene
                sceneView.session.add(anchor: anchor!)
                guard let anchorData = try? NSKeyedArchiver.archivedData(withRootObject: anchor!,
                                                                         requiringSecureCoding: true)
                else { fatalError("can't encode anchor") }
                //send anchor data
                self.mpc?.sendDataToAllPeers(data: anchorData)
                
                guard let cam = self.camera else { return }
                //send pos data
                let pos = cam.transform.inverse * rayCastResult.worldTransform.columns.3
                guard let posData = try? JSONEncoder().encode(pos) else { fatalError("cannot encode simd_float3x3") }
                self.mpc?.sendDataToAllPeers(data: posData)
                
            }
            
            
            

           
        }
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
    
    //update visualization information
    func visualisationUpdate(with peer: NINearbyObject) {
        // Animate into the next visuals.
        guard let direction = peer.direction else { return }
        peerDirection = direction
        guard let distance = peer.distance else { return }
        peerDistance = distance
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
    
    internal func setInfoLabel(with string: String) {
        self.infoLabel.text = string
    }
    
    internal func setDeviceLabel(with string: String) {
        self.deviceLable.text = string
    }

    
    private func removeAllAnchorsOriginatingFromARSessionWithID(_ identifier: String) {
        guard let frame = sceneView.session.currentFrame else { return }
        for anchor in frame.anchors {
            guard let anchorSessionID = anchor.sessionIdentifier else { continue }
            if anchorSessionID.uuidString == identifier {
                sceneView.session.remove(anchor: anchor)
            }
        }
        //couldCreateObj = true
    }
    
    private func sendARSessionIDTo(peers: [MCPeerID]) {
        guard let multipeerSession = mpc else { return }
        let idString = sceneView.session.identifier.uuidString
        let command = "SessionID:" + idString
        //将字符串类型转为data
        if let commandData = command.data(using: .utf8) {
            multipeerSession.sendDataToAllPeers(data: commandData)
        }
    }
    
    
    func initChessGame() {
        var code1: Int?
        var code2: Int?
        if MyChessInfo.couldInit {
            //randomly pick order
            MyChessInfo.myChessOrder = randomlyPickChessOrder()
            DispatchQueue.main.async {
                self.view.addSubview(self.myTurnLabel)
                self.view.addSubview(self.peerTurnLabel)
                self.view.addSubview(self.playImageView)
            }
            if MyChessInfo.myChessOrder == 1 {
                code1 = 2
            }
            if MyChessInfo.myChessOrder == 2 {
                code1 = 3
            }
            
            //randomly pick color
            MyChessInfo.myChessColor = randomlyPickChessColor()
            if MyChessInfo.myChessColor == 1 {
                code2 = 4
            }
            if MyChessInfo.myChessColor == 2 {
                code2 = 5
            }
            
            MyChessInfo.couldInit = false
            
            initCodeReceiver(code1!, code2!)
            
            
            if MyChessInfo.myChessOrder == 1 {
                MyChessInfo.canIPlaceChess = true
                DispatchQueue.main.async {
                    self.peerTurnLabel.alpha = 0.2
                    self.myTurnLabel.alpha = 1
                    self.rotateAnimation(with: .pi)
                }
            }
            if MyChessInfo.myChessOrder == 2 {
                DispatchQueue.main.async {
                    self.myTurnLabel.alpha = 0.2
                    self.peerTurnLabel.alpha = 1
                    
                }
            }
        }
    }
    
    
    func initCodeReceiver(_ code1: Int, _ code2: Int) {
        sendCodeToPeer(with: code1)
        sendCodeToPeer(with: code2)
    }
    
    

}

struct Constants {
    //obj name
    static let ObjectName = "Object"
    
    //ChessBoard&Chess Name
    static let chessBoardName = "ChessBoard"
    static let peerChessBoardName = "peerBoard"
    
  
    
    static let blackChessName = "BlackChess"
    static let whiteChessName = "WhiteChess"
    
    //mathmatic constant
    static let distanceThereshold: Float = 0.4
    static let frameNum: Int = 2
    static let weight: Float = 0.8
    
    static let scaleFromWorldToLocal: Float = 3.3
    
    //UI界面参数
    static let myTurnAlpha = 1.0
    static let peerTurnAlpha = 0.2
}

extension SCNVector3 {
    static func + (v1: SCNVector3, v2: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: v1.x + v2.x, y: v1.y + v2.y, z: v1.z + v2.z)
    }
}
