//
//  CLManager.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/4/12.
//

import Foundation
import CoreLocation
import UIKit

class CLManager: CLLocationManager, CLLocationManagerDelegate {
    private var viewController: ScanVC
    
    private var locationData: CLLocation?
    private var headingData: CLHeading?
    
    private var isRecording = false
    
    private lazy var logStringGps = initLogString()
    private lazy var logStringHeading = initLogString()
    
    init(viewController: ScanVC) {
        self.viewController = viewController
        super.init()
        self.delegate = self
        self.distanceFilter = kCLDistanceFilterNone
        self.desiredAccuracy = kCLLocationAccuracyBest
        self.headingOrientation = .landscapeLeft
        self.headingFilter = kCLHeadingFilterNone
        if self.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)) {
            self.requestWhenInUseAuthorization()
        }
    }
    
    func initLogString() -> NSMutableString {
        return NSMutableString(string: "")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationData = locations.last
        updateLocation(locationData)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingData = newHeading
        updateHeading(headingData)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [self] in
            let alert = UIAlertController(title: "Error", message: "Location update: (error)", preferredStyle: .alert)
            let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okButton)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateLocation(_ location: CLLocation?) {
        if location != nil && isRecording {
            let msDate = location!.timestamp.timeIntervalSince1970
            let currLatitude = location!.coordinate.latitude
            let currLongitude = location!.coordinate.longitude
            let currHorAccur = location!.horizontalAccuracy
            let currAltitude = location!.altitude
            let currVertAccur = location!.verticalAccuracy
            let currFloor = location!.floor?.level ?? nil
            let currCource = location!.course
            let currSpeed = location!.speed
            
            logStringGps.append(String(format: "%f,%f,%f,%f,%f,%f,%ld,%f,%f\r\n",
                                       msDate,
                                      currLatitude,
                                      currLongitude,
                                      currHorAccur,
                                      currAltitude,
                                      currVertAccur,
                                      currFloor ?? 0,
                                      currCource,
                                      currSpeed))
        }
    }
    
    func updateHeading(_ heading: CLHeading?) {
        if isRecording && heading != nil {
            let msDate = heading!.timestamp.timeIntervalSince1970
            let currTrueHeading = heading!.trueHeading
            let currMagneticHeading = heading!.magneticHeading
            let currHeadingAccuracy = heading!.headingAccuracy
            
            logStringHeading.append(String(format: "%f,%f,%f,%f\r\n",
                                           msDate,
                                           currTrueHeading,
                                           currMagneticHeading,
                                           currHeadingAccuracy))
        }
    }
    
    func writeStringToFile(_ string: NSMutableString, _ filename: String) {
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
        isRecording = true
        self.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            self.startUpdatingHeading()
        }
    }
    
    func endRecording() {
        isRecording = false
        self.stopUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            self.stopUpdatingHeading()
        }
        writeStringToFile(logStringGps, "GPS")
        writeStringToFile(logStringHeading, "heading")
        logStringGps = ""
        logStringHeading = ""
    }
}
