//
//  MainViewSubviews.swift
//  VerseeScan
//
//  Created by 张裕阳 on 2023/6/22.
//

import Foundation
import SwiftUI
import RealityKit

extension MainSUIV {
    var scanButton: some View {
        Button(action: {
            isPresentingScan.toggle()
            newCapture()
        }) { Image(systemName: "plus").font(.system(size: 24)).foregroundColor(.white) }
            .frame(width: 36, height: 36)
            .background(Color.black)
            .clipShape(Circle())
            .padding(7)
            .overlay( Circle().stroke(Color.black, lineWidth: 2).shadow(radius: 3) )
            .overlay( GeometryReader { geo in
                Color.clear.preference(key: ButtonOffsetKey.self, value: geo.frame(in: .global).minY)
            }
            ).fullScreenCover(isPresented: $isPresentingScan) {
                ScanVC_representable().ignoresSafeArea(.all)
            }
    }
    
//    var pairingButton: some View {
//        Button(action: {
//            newPairing()
//        }) { Image(systemName: "dot.radiowaves.left.and.right").font(.system(size: 24)).foregroundColor(.white) }
//            .frame(width: 36, height: 36)
//            .background(Color.black)
//            .clipShape(Circle())
//            .padding(7)
//            .overlay( Circle().stroke(Color.black, lineWidth: 2).shadow(radius: 3) )
//            .overlay( GeometryReader { geo in
//                Color.clear.preference(key: ButtonOffsetKey.self, value: geo.frame(in: .global).minY)
//            }
//            ).fullScreenCover(isPresented: $isPresentingScan) {
//                ScanVC_representable().ignoresSafeArea(.all)
//            }
//    }
    
    var objCapButton: some View {
        Button(action: {
            if #available(iOS 17.0, *) {
                Task {
                    if await ObjectCaptureSession.isSupported {
                        isPresentingObjectCapture = true
                    } else {
                        isUnsupportedObjCap = true
                        Logger.shared.debugPrint("Warning 401: This device do not support object capture session.")
                    }
                }
            } else {
                Logger.shared.debugPrint("Warning 301: iOS Version lower than 17.0")
            }
        }) {
            HStack {
                VStack {
                    Text("Object Capture (Testing)")
                        .bold()
                        .font(.system(size: 16))
                        .foregroundColor(Color(uiColor: UIColor.init(white: 1.0, alpha: 0.85)))
                }
                .cornerRadius(30)
                .frame(width: screenWidth-2*spaceing, height: screenWidth/2 - spaceing/2)
                .background(Color.black)
                .sheet(isPresented: $isPresentingObjectCapture) { if #available(iOS 17.0, *) {
                    //                    ObjCapView()
                    }
                }
            }
        }
        .alert(isPresented: $isUnsupportedObjCap) {
            Alert(title: Text("Notification"),
                  message: Text("This device do not support Object Capture Session"),
                  dismissButton: .default(Text("Got it.")))
        }
    }
    
    var fileButton: some View {
        ForEach(filenames, id: \.hash) { proj in
            HStack {
                Button(action: {
                    isBottomMenuPopup.toggle()
                    mainViewModel.currentFilename = proj
                }) {
                    VStack {
                        if let img = getFirstFrameOfVideo(proj) {
                            Image(uiImage: img)
                                .resizable()
                                .frame(maxWidth: screenWidth/2-2*spaceing, maxHeight: screenWidth/2-2*spaceing)
                                .rotationEffect(.degrees(90))
                                .cornerRadius(15)
                        } else {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(maxWidth: screenWidth/2-2*spaceing, maxHeight: screenWidth/2-2*spaceing)
                                .foregroundColor(.black)
                                .cornerRadius(15)
                        }
                        Text(proj.prefix(19))
                            .font(.system(size: 12))
                            .foregroundColor(Color.black)
                    }
                }
                .shadow(radius: 5)
                .sheet(isPresented: $isBottomMenuPopup, content: {
                    bottomView
                        .presentationDetents([.fraction(0.20), .fraction(0.40)])
                        .presentationDragIndicator(.visible)
                })
            }
        }
    }
    
    var bottomView: some View {
        VStack(spacing: 5) {
            if (UploadConfig.isUploadingInBackgroundThread || mainViewModel.isUploading) && !mainViewModel.isShowingFailure {
                VStack {
                    if mainViewModel.currentFileNumber >= mainViewModel.allFileNumber
                        && mainViewModel.httpProgress >= 1 {
                        HStack {
                            Text("Verifying...")
                            Spacer()
                        }
                    } else {
                        ProgressView("Now uploading file \(Int(mainViewModel.currentFileNumber+1)) of \(Int(mainViewModel.allFileNumber))",
                                     value: mainViewModel.currentFileNumber,
                                     total: mainViewModel.allFileNumber)
                        ProgressView("Upload progress: \(String(format: "%.2f", mainViewModel.httpProgress*100)) %",
                                     value: mainViewModel.httpProgress,
                                     total: 1.0)
                        .scaleEffect(x: 1, y: 1, anchor: .center)
                        .progressViewStyle(.linear)
                    }
                }
            } else {
                Button(action: {
                    mainViewModel.uploadFile(mainViewModel.currentFilename)
                }, label: {
                    Text("Upload")
                        .withButtonStyles()
                })
                .withLoginStyles()
            }
            if #available(iOS 17.0, *) {
                if ScanConfig.developerMode && PhotogrammetrySession.isSupported {
                    Button(action: {
                        let vd = VideoDecomposer(path: mainViewModel.currentFilename)
                        var pg = Photogrammetry(path: mainViewModel.currentFilename)
                        let sQueue = DispatchQueue(label: "sQueue")
                        sQueue.async {
                            vd.getAllImages()
                            pg.initialization()
                        }
                    }, label: {
                        Text("Refinement")
                            .withButtonStyles()
                    })
                    .withLoginStyles()
                    
                    Button(action: {
                        let documentsDir = FileManager
                            .default
                            .urls(for: .documentDirectory,
                                  in: .userDomainMask)[0].appendingPathComponent(mainViewModel.currentFilename,
                                                                                 isDirectory: true)
                        let groupDir = FileManager
                            .default
                            .containerURL(forSecurityApplicationGroupIdentifier: "group.VerseescanGroup")
                        let srcPath = documentsDir.appendingPathComponent("Images",
                                                                          isDirectory: true)
                        let dstPath = groupDir?.appendingPathComponent("Images", isDirectory: true)
                        do {
                            try! FileManager.default.copyItem(atPath: srcPath.path, toPath: dstPath!.path)
                        } catch {
                            Logger.shared.debugPrint(error.localizedDescription)
                        }
                    }, label: {
                        Text("Copy Images to Shared Folder (Only for developer)")
                            .withButtonStyles()
                    })
                    .withLoginStyles()
                }
            }
            Button(action: {
                isPreviewingFile.toggle()
            }, label: {
                Text("Preview")
                    .withButtonStyles()
            })
            .withLoginStyles()
            .sheet(isPresented: $isPreviewingFile, content: {
                ProjectDetailsSUIV(projectName: mainViewModel.currentFilename)
            })
        }
    }
}

struct ButtonOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
