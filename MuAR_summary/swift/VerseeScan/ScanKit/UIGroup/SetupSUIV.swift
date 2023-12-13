//
//  SetupSUIV.swift
//  ScanKit
//
//  Created by Kenneth Schröder on 08.10.21.
//

// UI 开始界面
//import SwiftUI
//
//// https://stackoverflow.com/questions/58787180/how-to-change-width-of-divider-in-swiftui
//struct ThickDivider: View {
//    var body: some View {
//        Rectangle()
//            .fill(Color("Occa"))
//            .frame(height: 3)
//    }
//}
//
//// https://www.hackingwithswift.com/quick-start/swiftui/customizing-button-with-buttonstyle
//struct GrowingButton: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(Color("Occa"))
//            .foregroundColor(.white)
//            .clipShape(Capsule())
//            .scaleEffect(configuration.isPressed ? 1.2 : 1)
//            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
//    }
//}
//
//// https://stackoverflow.com/questions/63651077/how-to-center-crop-an-image-in-swiftui
//extension Image {
//    func centerCropped() -> some View {
//        GeometryReader { geo in
//            self
//            .resizable()
//            .scaledToFill()
//            .frame(width: geo.size.width, height: geo.size.height)
//            .clipped()
//        }
//    }
//}
//
//struct SetupSUIV: View {
//    @State private var savePointCloud = ScanConfig.savePointCloud
//    @State private var saveRGBVideo = ScanConfig.saveRGBVideo
//    @State private var saveDepthVideo = ScanConfig.saveDepthVideo
//    @State private var saveConfidenceVideo = ScanConfig.saveConfidenceVideo
//    @State private var saveWorldMapInfo = ScanConfig.saveWorldMapInfo
//    @State private var detectQRCodes = ScanConfig.detectQRCodes
//    @State private var rgbQuality = ScanConfig.rgbQuality
////    @State private var title: String = ""
//    @State private var userName: String = ""
//    @State private var sceneDescription: String = ""
//    @State private var sceneType: String = ""
//    @State private var isPresentingProjects: Bool = false
//    @State private var isPresentSetting: Bool = false
//    @State private var isPresentingScan: Bool = false
//    @State private var dataRateText = "Estimated Data Rate: "
//    private var mainColor = Color("Occa")
//    // https://cocoacasts.com/swift-fundamentals-how-to-convert-a-date-to-a-string-in-swift
//    func getDefaultProjectName() -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
//        let now: String = dateFormatter.string(from: Date())
//        return now
//    }
//
//    func updateDataEstimate() {
//        var estimate: Float = 0
//        if ScanConfig.savePointCloud {
//            estimate += 1
//        }
//        if ScanConfig.saveRGBVideo {
//            estimate += (30 + 577 * pow(ScanConfig.rgbQuality, 4))/10
//        }
//        if ScanConfig.saveDepthVideo {
//            estimate += 118.0/10
//        }
//        if ScanConfig.saveConfidenceVideo {
//            estimate += 30.0/10
//        }
//        if ScanConfig.saveWorldMapInfo {
//            estimate += 15 // note: increasing over time
//        }
//        dataRateText = String(format: "Estimated Data Rate: %.2f MB/s", estimate)
//    }
//
//    init() {
//        UITableView.appearance().separatorStyle = .none
//        UITableViewCell.appearance().backgroundColor = .clear
//        UITableView.appearance().backgroundColor = .clear
//    }
//    //主界面UI
//    var body: some View {
//        ZStack {
//            Image("background").centerCropped().ignoresSafeArea(.all)
//            VStack {
//                Text("VerseeScan").font(Font.custom("Apple SD Gothic Neo Bold", size: 60)).padding(.top, 30)
//                //ThickDivider()
//                List {
//                    Section(header: Text("Scan Settings")) {
//                        // https://stackoverflow.com/questions/62820488/extra-arguments-at-positions-11-12-in-call-swiftui
//                        // ViewBuilder supports only no more than 10 static views in one container
//                        Group {
//                            TextField("User Name", text: $userName, onEditingChanged: { edit in
//                                var user_Name: String? = userName
//                                if userName == "" { user_Name = nil }
//                                ScanConfig.userName = user_Name
//                            }).font(.title3).listRowBackground(Color.clear)
//                            TextField("Scene Description", text: $sceneDescription, onEditingChanged: { edit in
//                                var scene_Description: String? = sceneDescription
//                                if sceneDescription == "" { scene_Description = nil }
//                                ScanConfig.sceneDescription = scene_Description
//                            }).font(.title3).listRowBackground(Color.clear)
//                            TextField("Scene Type", text: $sceneType, onEditingChanged: { edit in
//                                var scene_Type: String? = sceneType
//                                if sceneType == "" { scene_Type = nil }
//                                ScanConfig.sceneType = scene_Type
//                            }).font(.title3).listRowBackground(Color.clear)
//                        }
////                        HStack {
////                            VStack {
////                                HStack {
////                                    Text("Test Mode").font(.title3)
////                                    Spacer()
////                                }
////                                HStack {
////                                    Text("Showing data like frame rate, memory usage. Testing depth with arkit feature points.").font(.caption2)
////                                    Spacer()
////                                }
////                            }.layoutPriority(1.0)
////                            Toggle("", isOn: $testingMode).onChange(of: testingMode) { value in
////                                ScanConfig.testingMode = value
////                            }.toggleStyle(SwitchToggleStyle(tint: mainColor))
////                        }.listRowBackground(Color.clear)
//                        HStack {
//                            VStack {
//                                HStack {
//                                    Text("Point Cloud").font(.title3)
//                                    Spacer()
//                                }
//                                HStack {
//                                    Text("On-the-fly generation of a colored point cloud, saved to documents folder in the .las file format.").font(.caption2)
//                                    Spacer()
//                                }
//                            }.layoutPriority(1.0)
//                            Toggle("", isOn: $savePointCloud).onChange(of: savePointCloud) { value in
//                                ScanConfig.savePointCloud = value
//                                updateDataEstimate()
//                            }.toggleStyle(SwitchToggleStyle(tint: mainColor))
//                        }.listRowBackground(Color.clear)
//                        HStack {
//                            VStack {
//                                HStack {
//                                    Text("RGB Video").font(.title3)
//                                    Spacer()
//                                }
//                                HStack {
//                                    Text("Record all images captured during the ARSession as video and save it to the specified location.").font(.caption2)
//                                    Spacer()
//                                }
//                            }.layoutPriority(1.0)
//                            Toggle("", isOn: $saveRGBVideo).onChange(of: saveRGBVideo) { value in
//                                ScanConfig.saveRGBVideo = value
//                                updateDataEstimate()
//                            }.toggleStyle(SwitchToggleStyle(tint: mainColor))
//                        }.listRowBackground(Color.clear)
//                        HStack {
//                            VStack {
//                                HStack {
//                                    Text("RGB Quality").font(.title3)
//                                    Spacer()
//                                }
//                                HStack {
//                                    Text("Adjust the JPEG compression quality of the saved RGB video.").font(.caption2)
//                                    Spacer()
//                                }
//                            }.layoutPriority(1.0)
//                            Slider(
//                                value: $rgbQuality,
//                                in: 0...1,
//                                onEditingChanged: { editing in
//                                    ScanConfig.rgbQuality = rgbQuality
//                                    updateDataEstimate()
//                                }
//                            ).frame(width: 100).accentColor(mainColor)
//                        }.listRowBackground(Color.clear)
//                        HStack {
//                            VStack {
//                                HStack {
//                                    Text("Depth Data").font(.title3)
//                                    Spacer()
//                                }
//                                HStack {
//                                    Text("Record all depth data captured during the ARSession and save it to the specified location.").font(.caption2)
//                                    Spacer()
//                                }
//                            }.layoutPriority(1.0)
//                            Toggle("", isOn: $saveDepthVideo).onChange(of: saveDepthVideo) { value in
//                                ScanConfig.saveDepthVideo = value
//                                updateDataEstimate()
//                            }.toggleStyle(SwitchToggleStyle(tint: mainColor))
//                        }.listRowBackground(Color.clear)
//                        HStack {
//                            VStack {
//                                HStack {
//                                    Text("Confidence Data").font(.title3)
//                                    Spacer()
//                                }
//                                HStack {
//                                    Text("Record all confidence data captured during the ARSession and save it to the specified location.").font(.caption2)
//                                    Spacer()
//                                }
//                            }.layoutPriority(1.0)
//                            Toggle("", isOn: $saveConfidenceVideo).onChange(of: saveConfidenceVideo) { value in
//                                ScanConfig.saveConfidenceVideo = value
//                                updateDataEstimate()
//                            }.toggleStyle(SwitchToggleStyle(tint: mainColor))
//                        }.listRowBackground(Color.clear)
//                        HStack {
//                            VStack {
//                                HStack {
//                                    Text("ARWorldMap Data").font(.title3)
//                                    Spacer()
//                                }
//                                HStack {
//                                    Text("Periodically save all of the ARWorldMap data to a JSON file at the specified location.").font(.caption2)
//                                    Spacer()
//                                }
//                            }.layoutPriority(1.0)
//                            Spacer()
//                            Toggle("", isOn: $saveWorldMapInfo).onChange(of: saveWorldMapInfo) { value in
//                                ScanConfig.saveWorldMapInfo = value
//                                updateDataEstimate()
//                            }.toggleStyle(SwitchToggleStyle(tint: mainColor))
//                        }.listRowBackground(Color.clear)
//                        HStack {
//                            VStack {
//                                HStack {
//                                    Text("QR Code Data").font(.title3)
//                                    Spacer()
//                                }
//                                HStack {
//                                    Text("Recognize QR Codes and save their location and message in JSON format to the specified location.").font(.caption2)
//                                    Spacer()
//                                }
//                            }.layoutPriority(1.0)
//                            Toggle("", isOn: $detectQRCodes).onChange(of: detectQRCodes) { value in
//                                ScanConfig.detectQRCodes = value
//                                updateDataEstimate()
//                            }.toggleStyle(SwitchToggleStyle(tint: mainColor))
//                        }.listRowBackground(Color.clear)
//                    }
//                }.scrollContentBackground(.hidden)
//                ThickDivider()
//                VStack(spacing: 10) {
//                    Text(dataRateText).font(.title3).onAppear() {
//                        updateDataEstimate()
//                    }
//                    Button("Start Scanning") {
//                        isPresentingScan.toggle()
//                        if ScanConfig.url == nil {
//                            return
//                        }
//                        if !FileManager.default.fileExists(atPath: ScanConfig.url!.path) {
//                            do {
//                                try FileManager.default.createDirectory(atPath: ScanConfig.url!.path, withIntermediateDirectories: true, attributes: nil)
//                            } catch {
//                                print(error.localizedDescription)
//                                return
//                            }
//                        }
//                    }.buttonStyle(GrowingButton()).fullScreenCover(isPresented: $isPresentingScan) {
//                        ScanVC_representable().ignoresSafeArea(.all)
//                    }
//                    HStack {
//                        Button("Setting") {
//                            isPresentSetting.toggle()
//                        }.buttonStyle(GrowingButton()).sheet(isPresented: $isPresentSetting) {
//                            SettingSUIV()
//                        }
//                        Spacer()
//                        Button("Projects") {
//                            isPresentingProjects.toggle()
//                        }.buttonStyle(GrowingButton()).sheet(isPresented: $isPresentingProjects) {
////                            ProjectsSUIV()
//                        }
//                    }
//                }.padding(.top, 10).padding(.leading, 20).padding(.trailing, 20).padding(.bottom, 30) // Button Block end
//            }.frame(
//                minWidth: 0,
//                maxWidth: 500,
//                minHeight: 0,
//                maxHeight: 900,
//                alignment: .topLeading
//            ).padding(.top).padding(.leading).padding(.trailing).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16.0)).ignoresSafeArea(.all)
//        }.environment(\.colorScheme, .dark)
//    }
//}
//
//struct SetupSUIV_Previews: PreviewProvider {
//    static var previews: some View {
//        SetupSUIV()
//    }
//}
