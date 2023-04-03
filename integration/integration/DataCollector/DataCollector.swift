import Foundation
import ARKit

class DataCollector: NSObject {
    var pos = [PosData]()
    
    var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "ar_data.csv"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func collectData(_ posA: simd_float4, _ posB: simd_float3, _ frame: ARFrame, _ frameNum: Int) {
        let data = PosData(peerPosAR: posA.normalize(),
                           peerPosNI: posB,
                           myPos: frame.camera.transform.columns.3.normalize())
        pos.append(data)
        writeTrackedSymptomValues(data.peerPosAR, data.peerPosNI, data.myPos, frameNum)
    }
    
    func writeTrackedSymptomValues(_ peerPosAR: simd_float3, _ peerPosNI: simd_float3, _ myPos: simd_float3, _ timestamp: Int) {
        let peerPosARStr = "\(peerPosAR.x)+\(peerPosAR.y)+\(peerPosAR.z)"
        let peerPosNIStr = "\(peerPosNI.x)+\(peerPosNI.y)+\(peerPosNI.z)"
        let myPosStr = "\(myPos.x)+\(myPos.y)+\(myPos.z)"
        let timeStr = "\(timestamp)"
        createCSV(peerPosARStr, peerPosNIStr, myPosStr, timeStr)
    }
    
    func createCSV(_ x: String, _ y: String, _ z: String, _ t: String) {
        guard let logFile = logFile else {
            print("没找到本地文件")
            return
        }

        guard let data = "\(x),\(y),\(z),\(t)\n".data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
                print("001写入第\(t)帧数据")
            }
        } else {
            var csvText = "peerPosAR,peerPosNI,MyPos,Time\n"
            let newLine = "\(x),\(y),\(z),\(t)\n"
            csvText.append(newLine)
            do {
                try csvText.write(to: logFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("Failed to create file")
                print("\(error)")
            }
            print("002写入第\(t)帧数据")
         print(logFile ?? "not found")
        }
    }
}

struct PosData {
    var peerPosAR: simd_float3
    var peerPosNI: simd_float3
    var myPos: simd_float3
}

extension simd_float4 {
    func normalize() -> simd_float3 {
        return simd_float3(self.x/self.w, self.y/self.w, self.z/self.w)
    }
}
