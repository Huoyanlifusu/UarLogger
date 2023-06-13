//
//  Data.swift
//  integration
//
//  Created by 张裕阳 on 2023/6/13.
//

import Foundation
import ARKit

class EnvDataCollector {
    var light = LightSensor(lightEstimate: 0.0, lightColorTemp: 0.0)
    var feature = FeatureSensor(featurePointNum: 0)
    
    var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "env_data.csv"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func featureExtractor(_ frame: ARFrame, _ timeStamp: TimeInterval) {
        if frame.rawFeaturePoints?.points.count ?? 0 > 20 {
            Logger.shared.debugPrint("纹理丰富场景")
        }
        else {
            Logger.shared.debugPrint("纹理稀缺场景")
        }
    }
    
    func lightEstimation(_ frame: ARFrame, _ timeStamp: TimeInterval) {
        let lighting = frame.lightEstimate?.ambientIntensity ?? 0.0
        let colorTemp = frame.lightEstimate?.ambientColorTemperature ?? 0.0
        light.lightEstimate = lighting
        light.lightColorTemp = colorTemp
        saveToFile(light, timeStamp)
    }
    
    func saveToFile(_ light: LightSensor, _ time: TimeInterval) {
        let luminance = "\(light.lightEstimate)"
        let chrominance = "\(light.lightColorTemp)"
        let timestamp = "\(time)"
        createCSV(luminance, chrominance, timestamp)
    }
    
    func createCSV(_ l: String,
                   _ c: String,
                   _ t: String) {
        guard let logFile = logFile else {
            Logger.shared.debugPrint("未找到本地文件")
            return
        }

        guard let data = "\(l),\(c),\(t)\n".data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
                Logger.shared.debugPrint("写入\(t)时刻环境数据")
            }
        } else {
            var csvText = "peerPosAR,peerPosNI,MyPos,Distance,Frame,Time\n"
            let newLine = "\(l),\(c),\(t)\n"
            csvText.append(newLine)
            do {
                try csvText.write(to: logFile, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                Logger.shared.debugPrint("创建环境文件失败")
                print("\(error)")
            }
        }
    }
}
