import Foundation
import ARKit

class DataCollector: NSObject {
    var pos = [ARNIData]()
    
    var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "ar_data.csv"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func collectData(_ posA: simd_float4,
                     _ posB: simd_float3,
                     _ poseA: simd_float3,
                     _ frame: ARFrame,
                     _ distance: Float,
                     _ timeStamp: TimeInterval) {
        let camPos = (frame.camera.transform.inverse * frame.camera.transform.columns.3).normalize()
        var lightIntensity: CGFloat = frame.lightEstimate?.ambientIntensity ?? 0.0
        var lightColor: CGFloat = frame.lightEstimate?.ambientColorTemperature ?? 0.0
        var featurePointNumber: Int = frame.rawFeaturePoints?.__count ?? 0
        let data = ARNIData(peerPosAR: posA.normalize(),
                        peerPosNI: posB,
                        peerPoseAR: poseA,
                        myPos: camPos,
                        distance: distance,
                        timeStamp: timeStamp,
                        lightIntensity: lightIntensity,
                        lightColor: lightColor,
                        featurePointNumber: featurePointNumber)
        pos.append(data)
        writeTrackedSymptomValues(data.peerPosAR,
                                  data.peerPosNI,
                                  data.peerPoseAR,
                                  data.myPos,
                                  data.distance,
                                  timeStamp,
                                  lightIntensity,
                                  lightColor,
                                  featurePointNumber)
    }
    
    func writeTrackedSymptomValues(_ peerPosAR: simd_float3,
                                   _ peerPosNI: simd_float3,
                                   _ peerPoseAR: simd_float3,
                                   _ myPos: simd_float3,
                                   _ distance: Float,
                                   _ timeStamp: TimeInterval,
                                   _ lightIntensity: CGFloat,
                                   _ lightColor: CGFloat,
                                   _ featurePointNum: Int) {
        let peerPosARStr = "\(peerPosAR.x),\(peerPosAR.y),\(peerPosAR.z)"
        let peerPosNIStr = "\(peerPosNI.x),\(peerPosNI.y),\(peerPosNI.z)"
        let peerPoseARStr = "\(peerPoseAR.x),\(peerPoseAR.y),\(peerPoseAR.z)"
        let myPosStr = "\(myPos.x),\(myPos.y),\(myPos.z)"
        let distanceStr = "\(distance)"
        let timeStr = "\(timeStamp)"
        let lightIntensityStr = lightIntensity == 0.0 ? "nil" : "\(lightIntensity)"
        let lightColorStr = lightColor == 0.0 ? "nil" : "\(lightColor)"
        let featurePointNumStr = featurePointNum == 0 ? "nil" : "\(featurePointNum)"
        createCSV(peerPosARStr,
                  peerPosNIStr,
                  myPosStr,
                  peerPoseARStr,
                  distanceStr,
                  timeStr,
                  lightIntensityStr,
                  lightColorStr,
                  featurePointNumStr)
    }
    
    func createCSV(_ peerPosARStr: String,
                   _ peerPosNIStr: String,
                   _ camPoseStr: String,
                   _ peerCamStr: String,
                   _ distanceStr: String,
                   _ timeStampStr: String,
                   _ lightIntensityStr: String,
                   _ lightColorStr: String,
                   _ featurePointNUmStr: String) {
        guard let url = ScanConfig.fileURL else {
            Logger.shared.debugPrint("File not found.")
            return
        }
        let csvURL = url.appendingPathComponent("AR_NI_DATA.csv")
        let t = timeStampStr
        let d = distanceStr
        let x = peerPosARStr
        let y = peerPosNIStr
        let c1 = camPoseStr
        let c2 = peerCamStr
        let l1 = lightIntensityStr
        let l2 = lightColorStr
        let fp = featurePointNUmStr
        guard let data = "\(t),\(d),\(x),\(y),\(c1),\(l1),\(l2),\(fp)\n".data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: csvURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: csvURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
//                Logger.shared.debugPrint("写入\(t)时刻位置姿态数据")
            }
        } else {
            var csvText = "TimeStamp,Distance,ARx,ARy,ARz,NIx,NIy,NIz,Camx,Camy,Camz,AmbientLightIntensity,LightColorEstimate,FeaturePointNumber\n"
            let newLine = "\(t),\(d),\(x),\(y),\(c1),\(l1),\(l2),\(fp)\n"
            csvText.append(newLine)
            do {
                try csvText.write(to: csvURL, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                Logger.shared.debugPrint("Failed to create pose file.")
                print("\(error)")
            }
        }
    }
}

struct ARNIData {
    var peerPosAR: simd_float3
    var peerPosNI: simd_float3
    var peerPoseAR: simd_float3
    var myPos: simd_float3
    var distance: Float
    var timeStamp: TimeInterval
    var lightIntensity: CGFloat
    var lightColor: CGFloat
    var featurePointNumber: Int
}

extension simd_float4 {
    func normalize() -> simd_float3 {
        return simd_float3(self.x/self.w, self.y/self.w, self.z/self.w)
    }
}
