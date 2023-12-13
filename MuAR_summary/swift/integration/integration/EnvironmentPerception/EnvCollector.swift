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
    var vc: ViewController?
    
    init( vc: ViewController? = nil) {
        self.vc = vc
    }
    
    var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = "env_data.csv"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func lightEstimation(_ frame: ARFrame, _ timeStamp: TimeInterval) {
        let lighting = frame.lightEstimate?.ambientIntensity ?? 0.0
        let colorTemp = frame.lightEstimate?.ambientColorTemperature ?? 0.0
        light.lightEstimate = lighting
        light.lightColorTemp = colorTemp
        setLightingConditionLabel(lighting)
//        if ScanConfig.isRecording {
//        saveToFile(light, timeStamp)
//        }
    }
    
    func setLightingConditionLabel(_ lighting: CGFloat) {
        if lighting > 900 && lighting < 1100 {
            vc!.lightingIntensityLabel.text = "Neutral Lighing"
        } else if lighting > 1400 {
            vc!.lightingIntensityLabel.text = "Over Lighting"
        } else if lighting < 700 && lighting > 300 {
            vc!.lightingIntensityLabel.text = "Dim Lighting"
        } else if lighting < 100 {
            vc!.lightingIntensityLabel.text = "Darkness"
        }
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
//                Logger.shared.debugPrint("写入\(t)时刻环境数据")
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
