//
//  MainSUIV.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/23.
//
import AVFoundation
import Foundation
import SwiftUI
import RealityKit
import Combine

struct ScanVC_representable: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<ScanVC_representable>) -> ScanVC {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // storyboard file name
        let next_vc = storyboard.instantiateViewController(withIdentifier: "recording_vc") as! ScanVC
        return next_vc
    }
    func updateUIViewController(_ uiViewController: ScanVC, context: UIViewControllerRepresentableContext<ScanVC_representable>) { }
}

func getProjectName() -> [String] { // https://stackoverflow.com/questions/42894421/listing-only-the-subfolders-within-a-folder-swift-3-0-ios-10
    let filemgr = FileManager.default
    let dirPaths = filemgr.urls(for: .documentDirectory, in: .userDomainMask)
    let myDocumentsDirectory = dirPaths[0]
    var projectNames:[String] = []
    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: myDocumentsDirectory, includingPropertiesForKeys: nil, options: [])
        let subdirPaths = directoryContents.filter{ $0.hasDirectoryPath }
        let subdirNamesStr = subdirPaths.map{ $0.lastPathComponent }
        projectNames = subdirNamesStr.filter { $0 != ".Trash" }
    } catch let error as NSError {
        print(error.localizedDescription)
    }
    return projectNames.sorted()
}

struct MainSUIV: View {
    @State var isPresentingScan: Bool = false
    @State var isPresentingObjectCapture: Bool = false
    @State var isUnsupportedObjCap: Bool = false
    @State var isBottomMenuPopup: Bool = false
    @State var isPreviewingFile: Bool = false
    @State var developerMode: Bool = ScanConfig.developerMode
    @State private var isPresentingSetting: Bool = false
    @State var filenames = getProjectName()
    
    var mainViewModel = MainSUIVViewmodel()
    
    let screenWidth = UIConfig.screenWidth
    let spaceing = UIConfig.mainViewSpacing
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        mainView
    }
    
    var mainView: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer().frame(width: spaceing/2)
                        Text("VerseeScan")
                            .font(.headline)
                            .padding()
                        Spacer()
                        Button(action: {
                            isPresentingSetting.toggle()
                        }) {
                            Image("setting").resizable().frame(width: 15, height: 15)
                        }
                        .padding(8)
                        .overlay(content: { RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 1) })
                        .sheet(isPresented: $isPresentingSetting) { SettingSUIV() }
                        Spacer().frame(width: spaceing)
                    }
                    .background(Color(red: 0.9, green: 0.9, blue: 0.9))
                    ScrollView {
                        Section(header: HStack {
                            Text("")
                                .font(.system(size: 30))
                                .foregroundColor(.black)
                                .bold()
                            Spacer()
                        }.padding(.leading, 16)
                        ) {
                            if #available(iOS 17.0, *) {
                                if developerMode {
                                    objCapButton
                                        .cornerRadius(30)
                                        .padding()
                                }
                            }
                            if filenames.count == 0 {
                                VStack {
                                    Spacer().frame(width: spaceing)
                                    Button(action: {
                                        isPresentingScan.toggle()
                                        newCapture()
                                    }) {
                                        HStack {
                                            VStack {
                                                Text("New Capture")
                                                    .bold()
                                                    .font(.system(size: 16))
                                                    .foregroundColor(Color(uiColor: UIColor.init(white: 1.0, alpha: 0.85)))
                                            }
                                            .cornerRadius(30)
                                            .frame(width: screenWidth-2*spaceing, height: screenWidth/2 - spaceing/2)
                                            .background(Color.black)
                                        }
                                    }
                                    .cornerRadius(20)
                                    .frame(maxHeight: (screenWidth-spaceing)/CGFloat(2))
                                    .fullScreenCover(isPresented: $isPresentingScan) {
                                        ScanVC_representable().ignoresSafeArea(.all)
                                    }
                                    Spacer().frame(width: spaceing)
                                }
                            } else {
                                LazyVGrid(columns: columns) {
                                    fileButton
                                }
                            }
                        }
//                        Section(header: HStack {
//                            Text("Featured").font(.system(size: 30))
//                                .foregroundColor(.black)
//                                .bold()
//                            Spacer()
//                        }.padding(.leading, 16)
//                        ) {
//                            
//                        }
                    }
                    HStack {
                        scanButton
//                        pairingButton
                    }
                }.background(Color(red: 0.95, green: 0.95, blue: 0.95))
            }
        }
        .refreshable {
            do {
                developerMode = ScanConfig.developerMode
                updateFileNames()
            } catch {
                Logger.shared.debugPrint("Warning 105: No recording files in the directory.")
            }
        }
    }
}

extension MainSUIV {
    func updateFileNames() {
        self.filenames = getProjectName()
    }
}

struct MainSUIV_Previews: PreviewProvider {
    static var previews: some View {
        MainSUIV()
    }
}
