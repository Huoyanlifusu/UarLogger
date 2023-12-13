//
//  Logger.swift
//  integration
//
//  Created by 张裕阳 on 2023/6/13.
//

import Foundation

class Logger {
    static let shared = Logger()
    
    private init(){}
    
    func debugPrint(
        _ message: Any,
        extra1: String = #file,
        extra2: String = #function,
        extra3: Int = #line,
        remoteLog: Bool = false,
        plain: Bool = false
    ) {
        if plain {
            print(message)
        }
        else {
            let filename = (extra1 as NSString).lastPathComponent
            print(message, "[\(filename) \(extra3) line]")
        }
        
        if remoteLog {
            // means recording the log to system backend
        }
    }
    
    func prettyPrint(message: Any) {
        dump(message)
    }
    
    func printDocumentsDirectory() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        print("Document Path: \(documentsPath)")
    }
    // This function requires firebase support
    func logEvent(_ name: String? = nil, event: String? = nil, param: [String: Any]? = nil) {
        // Analytics.logEvent(name, parameters: param)
    }
}
