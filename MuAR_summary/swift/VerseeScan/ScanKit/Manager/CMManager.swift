//
//  CMManger.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/4/12.
//

import Foundation
import CoreMotion
import UIKit

class CMManager: CMMotionManager {
    private var viewController: ScanVC
    private let imuFreq: Double = 50.0
    private let accegyroQueue = OperationQueue()
    private let motionQueue = OperationQueue()
    private let magnetQueue = OperationQueue()
    
    private var isRecoding = false
    private var bootTime: TimeInterval
    
    init(bootTime: TimeInterval, viewController: ScanVC) {
        self.viewController = viewController
        self.bootTime = bootTime
        super.init()
        self.gyroUpdateInterval = 1.0/imuFreq
        self.accelerometerUpdateInterval = 1.0/imuFreq
        self.deviceMotionUpdateInterval = 1.0/imuFreq
    }
    
    func initLogString() -> NSMutableString {
        return NSMutableString(string: "")
    }
    
    func outputRotationData(_ data: CMGyroData?) {
        if (isRecoding && data != nil) {
            let msDate = bootTime + data!.timestamp
            let rotS = NSString(format: "%f,%f,%f,%f\r\n",
                                msDate,
                                data!.rotationRate.x,
                                data!.rotationRate.y,
                                data!.rotationRate.z)
            writeStringToFile(rotS, "Gyro")
        }
    }
    
    func outputAccelerationData(_ data: CMAccelerometerData?) {
        if (isRecoding && data != nil) {
            let msDate = bootTime + data!.timestamp
            let accS = NSString(format: "%f,%f,%f,%f\r\n",
                                msDate,
                                data!.acceleration.x,
                                data!.acceleration.y,
                                data!.acceleration.z)
            writeStringToFile(accS, "Accel")
        }
    }
    
    func outputMagnetometerData(_ data: CMMagnetometerData?) {
        if (isRecoding && data != nil) {
            let msDate = bootTime + data!.timestamp
            let magS = NSString(format: "%f,%f,%f,%f\r\n",
                            msDate,
                            data!.magneticField.x,
                            data!.magneticField.y,
                            data!.magneticField.z)
            writeStringToFile(magS, "Magn")
        }
    }
    
    func outputDeviceMotionData(_ data: CMDeviceMotion?) {
        if (isRecoding && data != nil) {
            let msDate = bootTime + data!.timestamp
            let quat = data!.attitude.quaternion
            let motS = NSString(format: "%f,%f,%f,%f,%f\r\n",
                                msDate,
                                quat.w,
                                quat.x,
                                quat.y,
                                quat.z)
            writeStringToFile(motS, "Motion")
            
            let rotr = data!.rotationRate
            let grav = data!.gravity
            let usracc = data!.userAcceleration
            let MotARHs = NSString(format: "%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\r\n",
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
                                   data!.heading)
            writeStringToFile(MotARHs, "MotARH")
            
            let calmagfield = data!.magneticField
            let MotMAGs = NSString(format: "%f,%f,%f,%f,%d\r\n",
                                   msDate,
                                   calmagfield.field.x,
                                   calmagfield.field.y,
                                   calmagfield.field.z,
                                   calmagfield.accuracy.rawValue)
            writeStringToFile(MotMAGs, "MotMAG")
        }
    }
    
    func startGyroAcceUpdate() {
        self.startGyroUpdates(to: accegyroQueue, withHandler: { [self]
            (data: CMGyroData?, error: Error?) in
            if let error = error {
                print(error)
            } else {
                outputRotationData(data)
            }
        })
        
        self.startAccelerometerUpdates(to: accegyroQueue, withHandler: { [self]
            (data: CMAccelerometerData?, error: Error?) in
            if let error = error {
                print(error)
            } else {
                outputAccelerationData(data)
            }
        })
    }
    
    func stopGyroAcceUpdate() {
        self.stopGyroUpdates()
        self.stopAccelerometerUpdates()
    }
    
    func startMotionUpdate() {
        self.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: motionQueue, withHandler: { [self]
            (data: CMDeviceMotion?, error: Error?) in
            if let error = error {
                print(error)
            } else {
                outputDeviceMotionData(data)
            }
        })
    }
    
    func stopMotionUpdate() {
        self.stopDeviceMotionUpdates()
    }
    
    func startMagnetUpdate() {
        self.startMagnetometerUpdates(to: magnetQueue, withHandler: { [self]
            (data: CMMagnetometerData?, error: Error?) in
            if let error = error {
                print(error)
            } else {
                outputMagnetometerData(data)
            }
        })
    }
    
    func stopMagnetUpdate() {
        self.stopMagnetometerUpdates()
    }
    
    func writeStringToFile(_ string: NSString, _ filename: String) {
        guard let url = ScanConfig.url else {
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
    }
}
