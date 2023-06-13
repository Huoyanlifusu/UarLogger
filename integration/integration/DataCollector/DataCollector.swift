import Foundation
import ARKit

class DataCollector: NSObject {
    var pos = [PosData]()
    
    var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "ar_data2.csv"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func collectData(_ posA: simd_float4,
                     _ posB: simd_float3,
                     _ frame: ARFrame,
                     _ distance: Float,
                     _ frameNum: Int,
                     _ timeStamp: TimeInterval) {
        let camPos = (frame.camera.transform.inverse * frame.camera.transform.columns.3).normalize()
        let data = PosData(peerPosAR: posA.normalize(),
                           peerPosNI: posB,
                           myPos: camPos,
                           distance: distance,
                           timeStamp: timeStamp)
        pos.append(data)
        writeTrackedSymptomValues(data.peerPosAR,
                                  data.peerPosNI,
                                  data.myPos,
                                  data.distance,
                                  frameNum,
                                  timeStamp)
    }
    
    func writeTrackedSymptomValues(_ peerPosAR: simd_float3,
                                   _ peerPosNI: simd_float3,
                                   _ myPos: simd_float3,
                                   _ distance: Float,
                                   _ frameNum: Int,
                                   _ timeStamp: TimeInterval) {
        let peerPosARStr = "\(peerPosAR.x)+\(peerPosAR.y)+\(peerPosAR.z)"
        let peerPosNIStr = "\(peerPosNI.x)+\(peerPosNI.y)+\(peerPosNI.z)"
        let myPosStr = "\(myPos.x)+\(myPos.y)+\(myPos.z)"
        let distanceStr = "\(distance)"
        let frameStr = "\(frameNum)"
        let timeStr = "\(timeStamp)"
        createCSV(peerPosARStr, peerPosNIStr, myPosStr, distanceStr, frameStr, timeStr)
    }
    
    func createCSV(_ x: String,
                   _ y: String,
                   _ z: String,
                   _ d: String,
                   _ f: String,
                   _ t: String) {
        guard let logFile = logFile else {
            Logger.shared.debugPrint("未找到本地文件")
            return
        }

        guard let data = "\(x),\(y),\(z),\(d),\(f),\(t)\n".data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
                Logger.shared.debugPrint("写入\(t)时刻位置姿态数据")
            }
        } else {
            var csvText = "peerPosAR,peerPosNI,MyPos,Distance,Frame,Time\n"
            let newLine = "\(x),\(y),\(z),\(d),\(f),\(t)\n"
            csvText.append(newLine)
            do {
                try csvText.write(to: logFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                Logger.shared.debugPrint("创建位姿文件失败")
                print("\(error)")
            }
        }
    }
}

struct PosData {
    var peerPosAR: simd_float3
    var peerPosNI: simd_float3
    var myPos: simd_float3
    var distance: Float
    var timeStamp: TimeInterval
}

extension simd_float4 {
    func normalize() -> simd_float3 {
        return simd_float3(self.x/self.w, self.y/self.w, self.z/self.w)
    }
}
