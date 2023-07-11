//
//  PoseFunc.swift
//  integration
//
//  Created by 张裕阳 on 2023/6/14.
//

import Foundation
import simd

func poseCalculateInARKit(_ trans: simd_float4x4) -> simd_float3 {
    // ARKit 旋转方向 z-y-x roll-yaw-pitch
    // z-axis roll
    let rollAngle = atan2(trans.columns.0.y, trans.columns.0.x)
    // y-axis yaw
    let yawAngle = asin(-trans.columns.0.z)
    // x-axis pitch
    let pitchAngle = atan2(trans.columns.1.z, trans.columns.2.z)
    return simd_float3(rollAngle, yawAngle, pitchAngle)
}
