//
//  SettingSUIV.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/17.
//

import Foundation
import SwiftUI
import Firebase

struct SettingSUIV: View {
    @State private var selectedAlgorithm: Algorithm = .lidar
    @State private var voxelSize: VoxelSize = .twomm
    
    @State private var deleteDataAfterUploading: Bool = true
    @State private var developerMode: Bool = ScanConfig.developerMode
    
    @State private var isPresentingAbout = false
    @State private var isPresentingPrivacy = false
    
    @State private var requireDownloading = false
    
    @State private var HStackBackgroundColor = Color.white
    
    @State private var isLogin = LoginConfig.isLogin
    @State private var loggedOut = !LoginConfig.isLogin
    
    private var totalMemory = UIDevice.current.totalDiskSpaceInBytes
    private var freeMemory = UIDevice.current.freeDiskSpaceInBytes
    private var usedMemory = UIDevice.current.usedDiskSpaceInBytes
    
    let alertTitle: String = "Notification"
    private let fileDownloader = FileDownloader()
    enum Algorithm: String, CaseIterable, Identifiable {
        case ML, lidar
        var id: Self { self }
    }
    
    enum VoxelSize: CaseIterable, Identifiable {
        case twomm, fivemm, tenmm
        var id: Self { self }
    }
    
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Mesh")) {
                    VStack {
                        HStack {
                            Text("Voxel Size")
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        Rectangle()
                            .fill(Color(uiColor: UIColor.lightGray))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .cornerRadius(15)
                            .overlay(
                                HStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill((voxelSize == VoxelSize.twomm) ? Color.white : Color(uiColor: UIColor.lightGray))
                                        .frame(maxWidth: 88)
                                        .frame(height: 36)
                                        .overlay {
                                            Text("2mm")
                                                .onTapGesture {
                                                    voxelSize = VoxelSize.twomm
                                                }
                                                .padding(5)
                                        }
                                    Divider()
                                        .background(Color.white)
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill((voxelSize == VoxelSize.fivemm) ? Color.white : Color(uiColor: UIColor.lightGray))
                                        .frame(maxWidth: 88)
                                        .frame(height: 36)
                                        .overlay {
                                            Text("5mm")
                                                .onTapGesture {
                                                    voxelSize = VoxelSize.fivemm
                                                }
                                                .padding(5)
                                        }
                                    Divider()
                                        .background(Color.white)
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill((voxelSize == VoxelSize.tenmm) ? Color.white : Color(uiColor: UIColor.lightGray))
                                        .frame(maxWidth: 88)
                                        .frame(height: 36)
                                        .overlay {
                                            Text("10mm")
                                                .onTapGesture {
                                                    voxelSize = VoxelSize.tenmm
                                                }
                                                .padding(5)
                                        }
                                }
                            )
                            .mask(
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(width: 300, height: 40)
                            )
                    }
                    Picker("Algorithm", selection: $selectedAlgorithm) {
                        Text("Machine Learning").tag(Algorithm.ML).frame(maxWidth: .infinity)
                        Text("Lidar Sensor").tag(Algorithm.lidar).frame(maxWidth: .infinity)
                    }
                }
                
                Section(header: Text("Data Management")) {
                    Toggle(isOn: $deleteDataAfterUploading, label: {
                        Text("Clear Data After Uploading")
                    }).onChange(of: deleteDataAfterUploading) { newValue in
                        UploadConfig.deleteFilesAfterUploading = newValue
                    }
                    Button("Clear Data") {
                        clearData()
                    }.foregroundColor(Color.red)
                    // https://stackoverflow.com/questions/58018633/swiftui-how-to-remove-margin-between-views-in-vstack
                    VStack(spacing: 0) {
                        HStack {
                            // https://stackoverflow.com/questions/56465083/custom-font-size-for-text-in-swiftui
                            Text("Used Memory:")
                            Spacer()
                            Text("\(UIDevice.current.usedDiskSpaceInGB)" + " / " + "\(UIDevice.current.totalDiskSpaceInGB)")
                                .font(.system(size: 14)).foregroundColor(Color(UIColor.lightGray))
                        }
                        Spacer().frame(height: 10)
                        GeometryReader { geometry in
                            // https://stackoverflow.com/questions/64031680/remove-padding-bewteen-items-in-hstack
                            HStack(spacing: 0) {
                                Rectangle()
                                    .foregroundColor(Color.orange)
                                    .frame(width: convertBytesToOccupationRate(usedMemory, totalMemory) * geometry.size.width,
                                           height: geometry.size.height)
                                Rectangle()
                                    .foregroundColor(Color.cyan)
                                    .frame(width: convertBytesToOccupationRate(freeMemory, totalMemory) * geometry.size.width,
                                           height: geometry.size.height)
                            }.mask(
                                RoundedRectangle(cornerRadius: 15)
                            )
                        }
                    }
                }
                
                Section(header: Text("Product")) {
                    // 暂时隐藏About和Privacy Policy界面
//                    NavigationLink(destination: AboutSUIV()) {
//                        Text("About").foregroundColor(Color.blue)
//                    }
//                    NavigationLink(destination: PrivacySUIV()) {
//                        Text("Privacy policy").foregroundColor(Color.blue)
//                    }
                    Button("Sending Feedback") {
                        openMailBox()
                    }.foregroundColor(Color.blue)
                }
                
                Section(header: Text("Developer")) {
                    Toggle(isOn: $developerMode, label: {
                        Text("Developer Mode")
                    }).onChange(of: developerMode) { newValue in
                        if newValue {
                            Logger.shared.debugPrint("Developer mode on.")
                        }
                        else {
                            Logger.shared.debugPrint("Developer mode off.")
                        }
                        ScanConfig.developerMode = newValue
                        requireDownloading = newValue && !SettingConfig.downloadingCoreML && !SettingConfig.downloadedCoreML
                    }.alert(alertTitle,
                            isPresented: $requireDownloading) {
                        Button("OK") {
                            SettingConfig.downloadingCoreML = true
                            let url = URL(string: "https://ml-assets.apple.com/coreml/models/Image/DepthEstimation/FCRN/FCRN.mlmodel")
                            FileDownloader.loadFileAsync(url: url!) { (path, error) in
                                Logger.shared.debugPrint("MLModel download to: \(path)")
                                Logger.shared.debugPrint(error)
                                SettingConfig.downloadedCoreML = true
                                SettingConfig.downloadingCoreML = false
                            }
                        }
                        Button("Cancel") {}
                    } message: {
                        Text("Please hit OK to download relating files for developer mode.")
                    }
                    if SettingConfig.downloadingCoreML {
                        ProgressView("Downloading Progress", value: SettingConfig.downloadingProgress, total: 1.0)
                    }
                }
                
                Section(header: Text("Versee")) {
                    HStack {
                        Text("Follow on Bilibili")
                        Spacer()
                        Image("bilibili")
                            .resizable()
                            .frame(maxWidth: 25, maxHeight: 25)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        jumpToBilibili()
                    }
                    HStack {
                        Text("Follow on Twitter")
                        Spacer()
                        Image("Twitter")
                            .resizable()
                            .frame(maxWidth: 20, maxHeight: 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 25)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        jumpToTwitter()
                    }
                }
                
                Section(header: LoginConfig.isLogin ? Text("User - \(LoginConfig.userName)") : Text("User - None")) {
                    if isLogin {
                        VStack {
                            HStack {
                                Button(action: {
                                    userSignOut()
                                }, label: {
                                    Text("Log Out")
                                        .withSettingStyles()
                                })
                                .alert(isPresented: $loggedOut) {
                                    Alert(title: Text("Message"),
                                          message: Text("Successfully logged out, do you want to back to login page?"),
                                          primaryButton: Alert.Button.cancel(Text("No").foregroundColor(Color.red)),
                                          secondaryButton: Alert.Button.default(Text("Yes"),
                                                                                action: {backToLoginPage()}))
                                }
                                Spacer()
                            }
                        }
                    }
                    else {
                        VStack{
                            NavigationLink(destination: LoginSUIV(), isActive: $loggedOut, label: {
                                Text("Login Page")
                            })
                        }
                    }
                }
            }.navigationTitle("Setting")
                .refreshable {
                    updateUserState()
                }
        }
    }
}

extension SettingSUIV {
    func userSignOut() {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            Logger.shared.debugPrint("Error signing out: \(signOutError.localizedDescription)")
            return
        }
        LoginConfig.isLogin = false
        loggedOut = true
    }
    
    func backToLoginPage() {
        if let window = UIApplication.shared.windows.first {
            let setupView = LoginSUIV()
            let hostingController = UIHostingController(rootView: setupView)
            // 设置动画
            hostingController.view.alpha = 0.0
            // 执行动画
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseOut], animations: {
                hostingController.view.alpha = 1.0
                window.rootViewController?.view.alpha = 0.0
            }, completion: nil)
            
            // 将 UIHostingController 设置为根视图控制器
            window.rootViewController = hostingController
            
            window.makeKeyAndVisible()
        }
    }
    
    func updateUserState() {
        isLogin = LoginConfig.isLogin
    }
    
    func clearData() {
        let fileManager = FileManager.default
        let currentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let directoryContents = try fileManager.contentsOfDirectory(atPath: currentPath)
            for path in directoryContents {
                let combinedPath = currentPath + "/" + path
                try fileManager.removeItem(atPath: combinedPath)
            }
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func openMailBox() {
        if let url = URL(string: "message://") {
            UIApplication.shared.open(url)
        }
    }
    
    func jumpToBilibili() {
        if let url = URL(string: "https://space.bilibili.com/1946896308") {
            UIApplication.shared.open(url)
        }
    }
    
    func jumpToTwitter() {
        if let url = URL(string: "https://twitter.com/TechVersee") {
            UIApplication.shared.open(url)
        }
    }
    
    func convertBytesToOccupationRate(_ freeSpace: Int64, _ maxSpace: Int64) -> CGFloat {
        let freeMemory = Float(freeSpace)
        let maxMemory = Float(maxSpace)
        return CGFloat(freeMemory/maxMemory)
    }
}
