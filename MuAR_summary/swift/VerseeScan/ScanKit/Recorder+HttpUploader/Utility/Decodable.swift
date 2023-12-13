//
//  Decodable.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/16.
//

import Foundation
import CoreLocation


// https://stackoverflow.com/questions/44603248/how-to-decode-a-property-with-type-of-json-dictionary-in-swift-45-decodable-pr
// JSON解析
struct MultiScanMetaData: Decodable {
    let device: [String: Any]
    let scene: [String: Any]
    let camera_orientation_euler_angles_format: String
    let depth_confidence_avaiable: Bool
    let depth_unit: String
    let depth_confidence_value_range: [Int]
    let camera_orientation_quaternion_format: String
    let number_of_files: Int
    let streams: [[String:Any]]
    let user: [String:Any]
    
    enum CodingKeys: String, CodingKey {
        case devcice = "device"
        case scene,
             camera_orientation_euler_angles_format,
             depth_confidence_avaiable, depth_unit, depth_confidence_value_range,
             camera_orientation_quaternion_format,
             number_of_files,
             streams, user
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        device = try container.decode([String:Any].self, forKey: .devcice)
        scene = try container.decode([String:Any].self, forKey: .scene)
        camera_orientation_euler_angles_format = try container.decode(String.self, forKey: .camera_orientation_euler_angles_format)
        depth_confidence_avaiable = try container.decode(Bool.self, forKey: .depth_confidence_avaiable)
        depth_unit = try container.decode(String.self, forKey: .depth_unit)
        depth_confidence_value_range = try container.decode([Int].self, forKey: .depth_confidence_value_range)
        camera_orientation_quaternion_format = try container.decode(String.self, forKey: .camera_orientation_quaternion_format)
        number_of_files = try container.decode(Int.self, forKey: .number_of_files)
        streams = try container.decode([[String:Any]].self, forKey: .streams)
        user = try container.decode([String:Any].self, forKey: .user)
    }
}
