
import Foundation
import SwiftUI
import UIKit

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

func browseSandboxDirectory() -> Int {
    let fileManager = FileManager.default
    // 获取应用程序沙盒的根目录路径
    if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        do {
            // 获取文件夹内容
            let directoryContents = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            
            // 输出文件夹内容
            print("Files in the sandbox directory：")
            for item in directoryContents {
                print(item)
            }
        } catch {
            print("Failed to catch files：\(error)")
        }
    } else {
        print("Failed to reach sandbox directory path")
    }
    return 0
}

struct ProjectView: View {
    @State var isBottomMenuPopup: Bool = false
    
    var projectNames = getProjectName()
    let i = browseSandboxDirectory()
    
    let img = UIImage()
    private let dirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    var body: some View {
        ScrollView {
            VStack {
                List(projectNames, id: \.hash) { project in
                    Text(project)
                    Button("Open in Files App") { // https://stackoverflow.com/questions/64591298/how-can-i-open-default-files-app-with-myapp-folder-programmatically
                        let dirPath = dirPath.appendingPathExtension(project)
                        let path = dirPath.absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
                        let url = URL(string: path)!
                        UIApplication.shared.open(url)
                    }
                }
                Spacer()
                
            }
            .navigationTitle("Projects")
        }.navigationViewStyle(StackNavigationViewStyle()).accentColor(Color.black) // https://stackoverflow.com/questions/65316497/swiftui-navigationview-navigationbartitle-layoutconstraints-issue/65316745
    }
}
