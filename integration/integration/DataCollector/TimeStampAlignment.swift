//
//  TimeStampAlign.swift
//  integration
//
//  Created by 张裕阳 on 2023/7/10.
//

import Foundation

class TimeStampAlignment {
    var AR_First_Stamp: TimeInterval?
    var NI_First_Stamp: TimeInterval?
    var CM_First_Stamp: TimeInterval?
    
    func recordFirstStamps() {
        guard let afs = AR_First_Stamp else {
            return
        }
        guard let cfs = CM_First_Stamp else {
            return
        }
        let atime = Double(afs)
        let ctime = Double(cfs)
        var str = NSMutableString(string: "")
        str.append(String(format: "%f\r\n", atime))
        str.append(String(format: "%f\r\n", ctime))
        writeToFile(str, "alingment")
    }
    
    func writeToFile(_ string: NSMutableString, _ filename: String) {
        guard let url = ScanConfig.fileURL else {
            return
        }
        let filePath = (url.path as NSString)
                                .appendingPathComponent((filename as NSString)
                                .appendingPathExtension("txt")!)
        do {
            try string.write(toFile: filePath, atomically: true,
                             encoding: String.Encoding.utf8.rawValue)
        } catch {
            print("Error writing string to file: \(error)")
        }
    }
}
