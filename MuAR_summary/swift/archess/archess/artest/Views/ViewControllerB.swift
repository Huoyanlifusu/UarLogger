//
//  ViewControllerB.swift
//  archess
//
//  Created by 张裕阳 on 2023/2/14.
//
import Foundation
import UIKit
import RealityKit
import ARKit
import SceneKit
import simd



@available(iOS 16.0, *)
class ViewControllerB: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    @IBOutlet weak var ARview: ARSCNView!
    
    var originNode: SCNNode?
    
    var camera: ARCamera?
    
    
    //chessGameLogicVariable
    var canPlaceBoard = true
    var firstClick = false
    
    private let infoLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: 0,
                                          width: anotherConstants.labelLength,
                                          height: anotherConstants.labelHeight))
        label.font = UIFont(name: "hongleisim-Regular", size: 20)
        label.text = ""
        return label
    }()
    
    private let deviceLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: 0,
                                          width: anotherConstants.labelLength,
                                          height: anotherConstants.labelHeight))
        label.font = UIFont(name: "hongleisim-Regular", size: 20)
        label.text = "initalDeviceLabel"
        return label
    }()
    
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
    
    private let myTurnLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: 0,
                                          width: 180,
                                          height: 30))
        label.font = UIFont(name: "hongleisim-Regular", size: 30)
        label.text = "您的回合"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("do not support ar world tracking")
        }
        
        //disable some buttons
        
        //set ARSession
        //niSession?.setARSession(sceneView.session)
        
        //set delegate
        ARview.session.delegate = self
        ARview.automaticallyUpdatesLighting = false
        
        //add light to show color
        ARview.autoenablesDefaultLighting = true
        ARview.automaticallyUpdatesLighting = true
        
        //start ar session
        
        //make configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        ARview.session.run(configuration)
        print("AR Session Started!")
        
        view.addSubview(exitButton)
        view.addSubview(restartButton)
        
        //show feature points in ar experience, usually not used
        //sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        //暂时不用辅助界面
//        setupCoachingOverlay()
        
        
        //disable idletimer cause user may not touch screen for a long time
        UIApplication.shared.isIdleTimerDisabled = true
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //suspend session
        ARview.session.pause()
        
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
        //label
        myTurnLabel.frame = CGRect(x: 50,
                                   y: 30,
                                   width: 180,
                                   height: 30)
        infoLabel.frame = CGRect(x: view.frame.size.width/2 - 45,
                                 y: view.frame.size.height - 100,
                                 width: anotherConstants.labelLength,
                                 height: anotherConstants.labelHeight)
        deviceLabel.frame = CGRect(x: view.frame.size.width/2 - 45,
                                   y: view.frame.size.height - 50,
                                   width: anotherConstants.labelLength,
                                   height: anotherConstants.labelHeight)
    }
    
    @objc private func didExit() {
        let alert = UIAlertController(title: "提醒",
                                      message: "是否返回主界面，当前所有内容都会丢失",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确认",
                                      style: .destructive){ (action) in
            resetMyChessInfo()
            resetAIChessInfo()
            self.originNode = nil
            //perform segue
            self.performSegue(withIdentifier: "viewBExitToMain", sender: self)
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
        resetMyChessInfo()
        resetAIChessInfo()
        firstClick = false
        canPlaceBoard = true
        originNode = nil
        
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.isCollaborationEnabled = true
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
        ARview.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    //渲染器
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //渲染棋盘
        if let name = anchor.name, name.hasPrefix(Constants.chessBoardName) {
            DispatchQueue.main.async {
                self.renderChessBoard(for: node)
                print("\(node.simdPosition)")
            }
            return
        }
        if let name = anchor.name, name.hasPrefix(Constants.blackChessName) {
            let (x,y,z) = couldRenderChess(with: anchor)
            if x == true {
                renderChess(xIndex: y!, yIndex: z!, color: 1)
            }
        }
        if let name = anchor.name, name.hasPrefix(Constants.whiteChessName) {
            let (x,y,z) = couldRenderChess(with: anchor)
            if x == true {
                renderChess(xIndex: y!, yIndex: z!, color: 2)
            }
        }
        
    }
    
    //第一种渲染方法
    func renderChessBoard(for node: SCNNode) {
        guard let url = Bundle.main.url(forResource: "chessBoard", withExtension: "usdz") else { fatalError("can not find resource url") }
        
        guard let boardNode = SCNReferenceNode(url: url) else { fatalError("cannot create chessboard node") }
        originNode = boardNode
        boardNode.load()
        
        //调整棋盘参数
        boardNode.scale = SCNVector3(0.3,0.3,0.3)
        //添加棋盘节点
        node.addChildNode(originNode!)
        MyChessInfo.couldInit = true
        initChessGame()
    }
    
    func initChessGame() {
        DispatchQueue.main.async {
            self.view.addSubview(self.myTurnLabel)
            self.view.addSubview(self.infoLabel)
            self.view.addSubview(self.deviceLabel)
        }
        if MyChessInfo.couldInit {
            
            MyChessInfo.couldInit = false
                
            //randomly pick color & order
            MyChessInfo.myChessColor = randomlyPickChessColor()
            if MyChessInfo.myChessColor == 1 {
                AIChessInfo.AIChessColor = 2
            } else if MyChessInfo.myChessColor == 2 {
                AIChessInfo.AIChessColor = 1
            } else {
                fatalError("you dont have a correct color")
            }
            
            MyChessInfo.myChessOrder = randomlyPickChessOrder()
            if MyChessInfo.myChessOrder == 1 {
                MyChessInfo.canIPlaceChess = true
                DispatchQueue.main.async {
                    self.myTurnLabel.alpha = anotherConstants.myTurnAlpha
                    self.setInfoLabel(with: "请您落子")
                }
            } else if MyChessInfo.myChessOrder == 2 {
                DispatchQueue.main.async {
                    self.setInfoLabel(with: "请您等待")
                    self.myTurnLabel.alpha = anotherConstants.AITurnAlpha
                }
                AITurn(isFirstStep: true)
            } else {
                fatalError("you dont have a correcr order")
            }
        }
        AIInitial(with: SinglePlayerGameInfo.level)
    }
    
    func loadBlackChess(with pos: simd_float4) -> SCNNode {
        guard let url = Bundle.main.url(forResource: "blackChess", withExtension: "usdz") else { fatalError("can not find resource url") }
        guard let node = SCNReferenceNode(url: url) else { fatalError("cannot establish black chess node") }
        
        node.simdTransform.columns.3 = pos
        node.simdScale = simd_float3(0.5,0.2,0.5)
        
        node.load()
        
        return node
    }
    
    func loadWhiteChess(with pos: simd_float4) -> SCNNode {
        guard let url = Bundle.main.url(forResource: "whiteChess", withExtension: "usdz") else { fatalError("can not find resource url") }
        guard let node = SCNReferenceNode(url: url) else { fatalError("cannot establish black chess node") }
        
        node.simdTransform.columns.3 = pos
        node.simdScale = simd_float3(0.5,0.2,0.5)
        
        node.load()
        return node
    }
    
    
    var count: Int = 0
    //monitoring 30fps update
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        camera = frame.camera
    }
    
    //ARSessionDelegate Monitoring NearbyObjects
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    }
    
    func couldRenderChess(with anchor: ARAnchor) -> (couldRender: Bool, indexOfX: Int?, indexOfY: Int?) {
        guard let originAnchor = ARview.anchor(for: originNode!) else {fatalError("no origin anchor")}
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
            return (false, nil, nil)
        }
        //判断是否已经落子
        if thereIsAChess(indexOfX: indexOfX, indexOfY: indexOfY) == true {
            DispatchQueue.main.async {
                self.setInfoLabel(with: "该处已经有棋子")
            }
            MyChessInfo.canIPlaceChess = true
            return (false, nil, nil)
        }
        return (true, indexOfX, indexOfY)
    }
    
    func renderChess(xIndex: Int, yIndex: Int, color: Int) {
        let localTrans = simd_float4(Float(xIndex)/10.0, 0.055, Float(yIndex)/10.0, 1)
        updatedAIIndexArray(indexOfX: xIndex, indexOfY: yIndex, with: color)
        if color == 1 {
            AIChessInfo.AIChessColor = 2
            originNode!.addChildNode(loadBlackChess(with: localTrans))
        } else if color == 2 {
            AIChessInfo.AIChessColor = 1
            originNode!.addChildNode(loadWhiteChess(with: localTrans))
        } else {
            fatalError("allocate color wrong")
        }
        updateChessInfo()
    }
    
    func updateChessInfo() {
        if MyChessInfo.myChessNum >= 5 {
            if isMeWin(AIChessInfo.IndexArray) {
                DispatchQueue.main.async {
                    self.setInfoLabel(with: "您胜利了！")
                    self.setDeviceLabel(with: "游戏结束")
                }
                MyChessInfo.canIPlaceChess = false
                return
            } else {
                DispatchQueue.main.async {
                    self.setInfoLabel(with: "等待AI落子")
                    self.myTurnLabel.alpha = anotherConstants.AITurnAlpha
                }
                MyChessInfo.canIPlaceChess = false
                AITurn(isFirstStep: false)
                return
            }
        } else {
            MyChessInfo.canIPlaceChess = false
            DispatchQueue.main.async {
                self.setInfoLabel(with: "等待AI落子")
                self.myTurnLabel.alpha = anotherConstants.AITurnAlpha

            }
            AITurn(isFirstStep: false)
            return
        }
    }
    
    //Hit test function
    @IBAction func handleViewBTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: ARview)
            guard let arRayCastQuery = ARview
                .raycastQuery(from: location,
                              allowing: .estimatedPlane,
                              alignment: .horizontal)
            else {
                return
            }
            guard let result = ARview.session.raycast(arRayCastQuery).first
            else {
                return
            }
            
            if firstClick == false && canPlaceBoard {
                //create and add chessboard anchor
                let anchor = ARAnchor(name: Constants.chessBoardName, transform: result.worldTransform)
                ARview.session.add(anchor: anchor)
                
                //有时arkit会多次检测tap，防止程序崩溃，同时保证此时不会产生新的board
                canPlaceBoard = false
                let _ = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { timer in
                    self.firstClick = true
                })
                
            }
            if firstClick == true && MyChessInfo.canIPlaceChess {
                MyChessInfo.canIPlaceChess = false
                //create and add chess anchor
                if MyChessInfo.myChessColor == 1 {
                    let anchor = ARAnchor(name: Constants.blackChessName, transform: result.worldTransform)
                    ARview.session.add(anchor: anchor)
                } else if MyChessInfo.myChessColor == 2 {
                    let anchor = ARAnchor(name: Constants.whiteChessName, transform: result.worldTransform)
                    ARview.session.add(anchor: anchor)
                } else {
                    fatalError("cannot load chess when you dont have color!!")
                }
            }
            
           
        }
    }
    
    func renderAIChess(with index: [Int]) {
        let indexOfX = index[0] - 4
        let indexOfY = index[1] - 4
        let coordinateOfX = Float(indexOfX) * 0.1
        let coordinateOfY = Float(indexOfY) * 0.1
        updatedAIIndexArray(indexOfX: indexOfX, indexOfY: indexOfY, with: AIChessInfo.AIChessColor)
        let localTrans = simd_float4(coordinateOfX, 0.055, coordinateOfY, 1)
        if AIChessInfo.AIChessColor == 1 {
            originNode!.addChildNode(loadBlackChess(with: localTrans))
        } else {
            originNode!.addChildNode(loadWhiteChess(with: localTrans))
        }
    }
    
    func AITurn(isFirstStep: Bool) {
        if isFirstStep {
            let nextStep = [4,4]
            renderAIChess(with: nextStep)
            updatedAIIndexArray(indexOfX: 4, indexOfY: 4, with: AIChessInfo.AIChessColor)
            
            MyChessInfo.canIPlaceChess = true
            DispatchQueue.main.async {
                self.setInfoLabel(with: "请您放置棋子")
                self.myTurnLabel.alpha = anotherConstants.myTurnAlpha
            }
            return
        }
        
        let nextAIStep = AIstep()
        if nextAIStep == nil {
            //游戏结束
            print("你输了，ai胜利")
        } else {
            guard let nextStep = nextAIStep else { fatalError("nextStep数据异常") }
            renderAIChess(with: nextStep)
            MyChessInfo.canIPlaceChess = true
            DispatchQueue.main.async {
                self.setInfoLabel(with: "请您放置棋子")
                self.myTurnLabel.alpha = anotherConstants.myTurnAlpha
            }
        }
    }
    
    func setInfoLabel(with string: String) {
        infoLabel.text = string
    }
    
    func setDeviceLabel(with string: String) {
        deviceLabel.text = string
    }

}

struct anotherConstants {
    static let labelLength: CGFloat = 200
    static let labelHeight: CGFloat = 30
    
    static let myTurnAlpha = 1.0
    static let AITurnAlpha = 0.1
}
