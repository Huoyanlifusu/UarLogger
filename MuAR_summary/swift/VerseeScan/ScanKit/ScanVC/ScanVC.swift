//
//  RawDataVC.swift
//  ScanKit
//
//  Created by Kenneth Schröder on 11.08.21.
//
// VC represents view controller
import UIKit
import Metal
import MetalKit
import ARKit
import Progress
import GDPerformanceView_Swift
import SwiftUI

class ScanVC: UIViewController, MTKViewDelegate, ProgressTracker {
    @IBOutlet weak var underlayControl: UISegmentedControl!
    @IBOutlet weak var viewControl: UISegmentedControl!
    @IBOutlet weak var viewshedButton: RoundedButton!
    @IBOutlet weak var torchButton: RoundedButton!
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var memoryBar: UIProgressView!
    @IBOutlet weak var backButton: UIButton!
    var memoryBarTimer = Timer()
    var arSession: ARSession!
    var renderer: ScanRenderer!
    var arManager: ARManager!
    var cmManager: CMManager!
    var clManager: CLManager!
    var depthPredict = DepthPredict()
    let depthmapTexutreGenerater = DepthmapTextureGenerater()
    var currentProgressRaw: Float = 0
    var currentProgressPC: Float = 0
    var scanStart: TimeInterval!
    var scanEnd: TimeInterval!
    let jsonEncoder = JSONEncoder()
    let performanceView = PerformanceMonitor(options: [.performance, .memory], style: .light)
    let MLQueue = DispatchQueue.global(qos: .background)
    let setupQueue = DispatchQueue(label: "com.setup")
    let coreQueue = DispatchQueue(label: "com.core.setup")
    let loadingVC = UIHostingController(rootView: InitializationSUIV())
    private var depthPicView: MetalVideoView = {
        let view = MetalVideoView(frame: CGRect(x: 0,
                                                y: 0,
                                                width: 960,
                                                height: 720),
                                  device: MTLCreateSystemDefaultDevice()!)
        view.alpha = 0
        return view
    }()
    private var errorRateLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0,
                                          y: 0, width: 40, height: 20))
        label.text = ""
        label.layer.cornerRadius = 10
        label.backgroundColor = .lightGray
        label.font = UIFont(name: "Helvetica", size: 11)
        return label
    }()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if isPad {
            return .landscapeLeft
        } else {
            return .portrait
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ScanConfig.isPad = isPad
        // 配置ML模型
        if ScanConfig.developerMode {
            MLQueue.async { [self] in
                depthPredict.setupModel()
                Logger.shared.debugPrint("Machine Learning Model setup.")
            }
        }
        // setup path
        configDirectory()
        // Set the view's delegate
        arSession = ARSession()
        arManager = ARManager(viewController: self,
                              arsession: arSession)
        arSession.delegate = arManager
        cmManager = CMManager(bootTime: Date().timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime,
                              viewController: self)
        clManager = CLManager(viewController: self)
        Logger.shared.debugPrint("Session & Manager setup.")
        // Set the view to use the default device
        if let view = self.view as? MTKView {
            view.device = MTLCreateSystemDefaultDevice()
            view.backgroundColor = UIColor.clear
            view.delegate = self
            guard view.device != nil else {
                print("Metal is not supported on this device")
                return
            }
            // Configure the renderer to draw to the view
            renderer = ScanRenderer(session: arSession, metalDevice: view.device!, renderDestination: view)
            ScanConfig.viewportSize = view.bounds.size
            renderer.drawRectResized(size: ScanConfig.viewportSize!)
        }
        if Thread.current.isMainThread {
            // update UI according to ScanConfig
            underlayControl.selectedSegmentIndex = ScanConfig.underlayIndex
            viewControl.selectedSegmentIndex = ScanConfig.viewIndex
            if !ScanConfig.developerMode {
                viewControl.isEnabled = false
                underlayControl.setEnabled(false, forSegmentAt: 2)
                underlayControl.setEnabled(false, forSegmentAt: 3)
            }
            if ScanConfig.viewshedActive {
                viewshedButton.backgroundColor = UIColor(named: "Occa")
            } else {
                viewshedButton.backgroundColor = .darkGray
            }
            let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                                action: #selector(ScanVC.handleLongPress(gestureRecognizer:)))
            // UITapGestureRecognizer(target: self,
            //                        action: #selector(ScanVC.handleTap(gestureRecognizer:)))
            view.addGestureRecognizer(longPressGesture)
        } else {
            DispatchQueue.main.async { [self] in
                // update UI according to ScanConfig
                underlayControl.selectedSegmentIndex = ScanConfig.underlayIndex
                viewControl.selectedSegmentIndex = ScanConfig.viewIndex
                if !ScanConfig.developerMode {
                    viewControl.isEnabled = false
                    underlayControl.setEnabled(false, forSegmentAt: 2)
                    underlayControl.setEnabled(false, forSegmentAt: 3)
                }
                if ScanConfig.viewshedActive {
                    viewshedButton.backgroundColor = UIColor(named: "Occa")
                } else {
                    viewshedButton.backgroundColor = .darkGray
                }
                let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                                    action: #selector(ScanVC.handleLongPress(gestureRecognizer:)))
                // UITapGestureRecognizer(target: self,
                //                        action: #selector(ScanVC.handleTap(gestureRecognizer:)))
                view.addGestureRecognizer(longPressGesture)
            }
            // 测试数据
            if ScanConfig.developerMode {
                if Thread.current.isMainThread {
                    performanceView.start()
                    performanceView.show()
                } else {
                    DispatchQueue.main.async { [self] in
                        performanceView.start()
                        performanceView.show()
                    }
                }
            }
        }
        self.memoryBarTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            _ = self.updateMemoryBarAskContinue()
        })
        Logger.shared.debugPrint("UI setup.")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics = .sceneDepth // additional options like .personSegmentation for green-screen scenarios e.g.
            // smoothedSceneDepth minimizes differences across frames https://developer.apple.com/documentation/arkit/arconfiguration/3089121-framesemantics
        }
        configuration.isAutoFocusEnabled = true
        //if(ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification)){
        //configuration.sceneReconstruction = .meshWithClassification // enables mesh generation
        //}
        // configuration.isAutoFocusEnabled // camera using fixed focus or auto focus
        configuration.planeDetection = [.horizontal, .vertical] // enabling plane detection smoothes the mesh at points that are near detected planes
        // configuration.userFaceTrackingEnabled // provides ARFaceAnchor for rendering avatars in multi-user experiences e.g.
        // worldAlignment defines the orientation of the world coordinate system according to gravity vector and compass direction
        configuration.worldAlignment = .gravity // leads to major drift in world tracking when heading enabled
        configuration.environmentTexturing = .none // .automatic
        
        // Run the view's session
        arSession.run(configuration)
        let videoFormat = configuration.videoFormat
        let imageResolution = videoFormat.imageResolution
        arManager.configureSession(videoFormat, imageResolution)
        Logger.shared.debugPrint("ARKit configed.")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Thread.current.isMainThread {
            view.addSubview(depthPicView)
            view.sendSubviewToBack(depthPicView)
            if ScanConfig.developerMode && SettingConfig.downloadedCoreML {
                view.addSubview(errorRateLabel)
            }
        } else {
            DispatchQueue.main.async { [self] in
                view.addSubview(depthPicView)
                view.sendSubviewToBack(depthPicView)
                if ScanConfig.developerMode && SettingConfig.downloadedCoreML {
                    view.addSubview(errorRateLabel)
                }
            }
        }
        Logger.shared.debugPrint("Subview added.")
    }
    
    // viewWillDisapper
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if ScanConfig.developerMode {
            self.performanceView.pause()
            self.performanceView.hide()
        }

        if ScanConfig.isRecording {
            recordingInteruptted()
            Logger.shared.debugPrint("Scan interupted.")
        } else {
            if scanStart == nil, let url = ScanConfig.url { // clean up folder if nothing recorded
                try? FileManager.default.removeItem(at: url)
            }
        }
        // Pause the view's session
        arSession.pause()
    }
    
    // viewDidLayOutSubview
    override func viewDidLayoutSubviews() {
        DispatchQueue.main.async {
            super.viewDidLayoutSubviews()
            let xOrigin = ScanConfig.viewportSize!.width/2.0 - UIConfig.depthPicWidth/2
            let yOrigin = ScanConfig.viewportSize!.height/2.0 - UIConfig.depthPicHeight/2
            self.depthPicView.frame = CGRect(origin: CGPoint(x: xOrigin, y: yOrigin),
                                             size: CGSize(width: UIConfig.depthPicWidth,
                                                          height: UIConfig.depthPicHeight))
            self.errorRateLabel.frame = CGRect(origin: CGPoint(x: 0, y: 40),
                                               size: CGSize(width: 80, height: 20))
        }
        Logger.shared.debugPrint("ScanVC Ssbview configured.")
    }
    // Auto-hide the home indicator to maximize immersion in AR experiences.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // Hide the status bar to maximize immersion in AR experiences.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    // reset tracking
    public func resetTracking() {
        if let configuration = arSession.configuration {
            arSession.run(configuration, options: .resetSceneReconstruction)
        }
    }
    // MARK: - interaction handling
    @objc
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        // Create anchor using the camera's current position
        if let currentFrame = arSession.currentFrame, gestureRecognizer.state == .began {
            let tapLocation = gestureRecognizer.location(in: gestureRecognizer.view)
            let capturedCoordinateSys = view.frame.size
            let norm_point = CGPoint(x: tapLocation.x / capturedCoordinateSys.width,
                                     y: tapLocation.y / capturedCoordinateSys.height)
            if let result = arSession.raycast(currentFrame.raycastQuery(from: norm_point,
                                                                         allowing: .estimatedPlane,
                                                                         alignment: .any)).first {
                print(result)
            }
        }
    }
    // MARK: - MTKViewDelegate
    // Called whenever view changes orientation or layout is changed
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        DispatchQueue.main.async {
            self.renderer.drawRectResized(size: size)
        }
    }
    // Called whenever the view needs to render
    func draw(in view: MTKView) {
        DispatchQueue.main.async {
            self.renderer.update()
        }
        if ScanConfig.developerMode {
            guard let depthMap = DepthDataFromML.depthMap else { return }
            DispatchQueue.main.async {
                self.depthPicView.currentTexture = self.depthmapTexutreGenerater.texture(depthMap, 128, 160)
            }
            guard let error = UIConfig.error else { return }
            DispatchQueue.main.async {
                self.errorRateLabel.text = "\(error)"
            }
        }
    }
}

// MARK: - UI Methods

extension ScanVC {
    // underlayControl 底部第二栏
    @IBAction func underlayControlChanged(_ sender: UISegmentedControl) {
        ScanConfig.underlayIndex = sender.selectedSegmentIndex
        if ScanConfig.underlayIndex == 2 {
            DispatchQueue.main.async {
                self.depthPicView.alpha = 0.85
            }
        } else {
            DispatchQueue.main.async {
                self.depthPicView.alpha = 0
            }
        }
    }
    // viewControl 底部第一栏
    @IBAction func viewControlChanged(_ sender: UISegmentedControl) {
        ScanConfig.viewIndex = sender.selectedSegmentIndex
        if ScanConfig.viewIndex > 0 {
            underlayControl.selectedSegmentIndex = 0
            ScanConfig.underlayIndex = 0
            underlayControl.isEnabled = false
            depthPicView.alpha = 0
        } else {
            underlayControl.isEnabled = true
        }
    }
    // viewshedButton
    @IBAction func viewshed_button_pressed(_ sender: RoundedButton) {
        ScanConfig.viewshedActive = !ScanConfig.viewshedActive
        if ScanConfig.viewshedActive {
            sender.backgroundColor = UIColor(named: "Occa")
        } else {
            sender.backgroundColor = .darkGray
        }
    }
    // https://stackoverflow.com/questions/27207278/how-to-turn-flashlight-on-and-off-in-swift
    @IBAction func torch_button_pressed(_ sender: RoundedButton) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
                sender.backgroundColor = .darkGray
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                    sender.backgroundColor = UIColor(named: "Occa")
                } catch {
                    print(error)
                }
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    // hit record button
    @IBAction func record_button_pressed(_ sender: RoundedButton) {
        Task { @MainActor in
            if ScanConfig.isRecording {
                recordingEnded()
                Logger.shared.debugPrint("Recording ended normally.")
            } else {
                self.present(loadingVC, animated: true, completion: nil)
                await beginRecording()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    // hit back button
    @IBAction func back_button_pressed(_ sender: RoundedButton) {
        self.dismiss(animated: true, completion: nil)
    }
    // MARK: - Progress indicator
    func showProgressRing() {
        let ringParam: RingProgressorParameter = (.proportional, UIColor.green.withAlphaComponent(0.4), 100, 50)
        var labelParam: LabelProgressorParameter = DefaultLabelProgressorParameter
        labelParam.font = UIFont.systemFont(ofSize: 30, weight: UIFont.Weight.bold)
        labelParam.color = UIColor.white.withAlphaComponent(0.3)
        DispatchQueue.main.async {
            Prog.start(in: self.view, .blur(.regular), .ring(ringParam), .label(labelParam))
        }
        perform(#selector(updateProgress), with: nil, afterDelay: 1.2)
    }
    func notifyProgressRaw(value: Float) {
        currentProgressRaw = value
        updateProgress()
    }
    func notifyProgressPC(value: Float) {
        currentProgressPC = value
        updateProgress()
    }
    // update progress ring
    @objc func updateProgress() {
        var value: Float = (currentProgressRaw + currentProgressPC) / 2.0
        DispatchQueue.main.async {
            Prog.update(value, in: self.view)
        }
        if value >= 1.0 || value.isNaN {
            usleep(600_000) // sleep mills to not break Prog
            DispatchQueue.main.async {
                Prog.end(in: self.view)
            }
        }
    }
    // MARK: - Memory Bar
    func updateMemoryBarAskContinue() -> Bool {
        memoryBar.progress = Float(query_memory())/5_000_000_000
        if memoryBar.progress < 0.5 {
            memoryBar.tintColor = .green
        } else if memoryBar.progress < 0.75 {
            memoryBar.tintColor = .orange
        } else {
            memoryBar.tintColor = .red
            return false
        }
        return true
    }
    func query_memory() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return taskInfo.resident_size
        } else {
            print("Error with task_info(): " +
                (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
            return 0
        }
    }
    // MARK: - Alert Information
    func showingAlert(_ error: Error) {
        if Thread.current.isMainThread {
            let alert = UIAlertController(title: "Error", message: "DeviceMotion update: \(error)", preferredStyle: .alert)
            let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okButton)
            present(alert, animated: true, completion: nil)
        } else {
            DispatchQueue.main.async { [self] in
                let alert = UIAlertController(title: "Error", message: "DeviceMotion update: \(error)", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okButton)
                present(alert, animated: true, completion: nil)
            }
        }
    }
}

