//
//  CMManager.swift
//  integration
//
//  Created by 张裕阳 on 2023/4/17.
//
import Foundation
import CoreMotion
import UIKit

class CMManager: CMMotionManager {
    let viewController: ViewController
    let imuFreq: Double = 100.0
    let accegyroQueue = OperationQueue()
    let motionQueue = OperationQueue()
    let magnetQueue = OperationQueue()
    
    var isRecoding = false
    
    var logFile: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory
    }
    
    private lazy var logStringGyro = initLogString()
    private lazy var logStringAcce = initLogString()
    private lazy var logStringMagn = initLogString()
    private lazy var logStringMotion = initLogString()
    private lazy var logStringMotARH = initLogString()
    private lazy var logStringMotMAG = initLogString()
    
    init(viewController: ViewController) {
        self.viewController = viewController
        super.init()
        self.gyroUpdateInterval = 1.0/imuFreq
        self.accelerometerUpdateInterval = 1.0/imuFreq
        self.deviceMotionUpdateInterval = 1.0/imuFreq
    }
    
    private func initLogString() -> NSMutableString {
        return NSMutableString(string: "")
    }
    
    func outputRotationData(_ data: CMGyroData?) {
        if (isRecoding && data != nil) {
            let msDate = data!.timestamp
            logStringGyro.append(String(format: "%f,%f,%f,%f\r\n",
                                        msDate,
                                        data!.rotationRate.x,
                                        data!.rotationRate.y,
                                        data!.rotationRate.z))
        }
    }
    
    func outputAccelerationData(_ data: CMAccelerometerData?) {
        if (isRecoding && data != nil) {
            let msDate = data!.timestamp
            logStringAcce.append(String(format: "%f,%f,%f,%f\r\n",
                                        msDate,
                                        data!.acceleration.x,
                                        data!.acceleration.y,
                                        data!.acceleration.z))
            StoredData.accX = data!.acceleration.x
            StoredData.accY = data!.acceleration.y
            StoredData.accZ = data!.acceleration.z
        }
    }
    
    func outputMagnetometerData(_ data: CMMagnetometerData?) {
        if (isRecoding && data != nil) {
            let msDate = data!.timestamp
            logStringMagn.append(String(format: "%f,%f,%f,%f\r\n",
                                        msDate,
                                        data!.magneticField.x,
                                        data!.magneticField.y,
                                        data!.magneticField.z))
        }
    }
    
    func outputDeviceMotionData(_ data: CMDeviceMotion?) {
        if (isRecoding && data != nil) {
            let msDate = data!.timestamp
            let quat = data!.attitude.quaternion
            logStringMotion.append(String(format: "%f,%f,%f,%f,%f\r\n",
                                        msDate,
                                        quat.w,
                                        quat.x,
                                        quat.y,
                                        quat.z))
            
            let rotr = data!.rotationRate
            let grav = data!.gravity
            let usracc = data!.userAcceleration
            logStringMotARH.append(String(format: "%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\r\n",
                                          msDate,
                                          rotr.x,
                                          rotr.y,
                                          rotr.z,
                                          grav.x,
                                          grav.y,
                                          grav.z,
                                          usracc.x,
                                          usracc.y,
                                          usracc.z,
                                          data!.heading))
            
            let calmagfield = data!.magneticField
            logStringMotMAG.append(String(format: "%f,%f,%f,%f,%d\r\n",
                                          msDate,
                                          calmagfield.field.x,
                                          calmagfield.field.y,
                                          calmagfield.field.z,
                                          calmagfield.accuracy.rawValue))
        }
    }
    
    func startGyroAcceUpdate() {
        self.startGyroUpdates(to: accegyroQueue, withHandler: {
            (data: CMGyroData?, error: Error?) in
            self.outputRotationData(data)
            if let error = error {
                let alert = UIAlertController(title: "Error", message: "Gyroscope update: \(error)", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okButton)
                self.viewController.present(alert, animated: true, completion: nil)
            }
        })
        
        self.startAccelerometerUpdates(to: accegyroQueue, withHandler: {
            (data: CMAccelerometerData?, error: Error?) in
            self.outputAccelerationData(data)
            if let error = error {
                let alert = UIAlertController(title: "Error", message: "Accelerometer update: \(error)", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okButton)
                self.viewController.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func stopGyroAcceUpdate() {
        self.stopGyroUpdates()
        self.stopAccelerometerUpdates()
    }
    
    func startMotionUpdate() {
        self.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: motionQueue, withHandler: {
            (data: CMDeviceMotion?, error: Error?) in
            self.outputDeviceMotionData(data)
            if let error = error {
                let alert = UIAlertController(title: "Error", message: "DeviceMotion update: \(error)", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okButton)
                self.viewController.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func stopMotionUpdate() {
        self.stopDeviceMotionUpdates()
    }
    
    func startMagnetUpdate() {
        self.startMagnetometerUpdates(to: magnetQueue, withHandler: {
            (data: CMMagnetometerData?, error: Error?) in
            self.outputMagnetometerData(data)
            if let error = error {
                let alert = UIAlertController(title: "Error", message: "Magnetometer update: \(error)", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okButton)
                self.viewController.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    func stopMagnetUpdate() {
        self.stopMagnetometerUpdates()
    }
    
    func writeStringToFile(_ string: NSMutableString, _ filename: String) {
        guard let url = logFile else {
            fatalError()
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
    
    func startRecording() {
        isRecoding = true
        startGyroAcceUpdate()
        startMotionUpdate()
        startMagnetUpdate()
    }
    
    func endRecording() {
        isRecoding = false
        stopGyroAcceUpdate()
        stopMotionUpdate()
        stopMagnetUpdate()
        writeStringToFile(logStringGyro, "Gyro")
        writeStringToFile(logStringAcce, "Accel")
        writeStringToFile(logStringMotion, "Motion")
        writeStringToFile(logStringMotARH, "MotARH")
        writeStringToFile(logStringMotMAG, "MotMagnFull")
        writeStringToFile(logStringMagn, "Magnet")
        self.logStringMagn = ""
        self.logStringAcce = ""
        self.logStringMotARH = ""
        self.logStringGyro = ""
        self.logStringMotion = ""
        self.logStringMotMAG = ""
    }
}
