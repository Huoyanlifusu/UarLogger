import Foundation
import simd
import SceneKit
import ARKit
import Accelerate

//azumith radian in XOY plane
func azumith(from direction: simd_float3) -> Float {
    return asin(direction.z)
}

//elevation angle
func elevation(from direction: simd_float3) -> Float {
    return atan2(direction.x, direction.y)
}

func correctPose(with peerEuler: simd_float3, using myEuler: simd_float3) -> simd_float4x4 {
    let theta_x = myEuler.x - peerEuler.x
    let theta_y = myEuler.y - peerEuler.y
    let theta_z = myEuler.z - peerEuler.z
    
    let e11 = cos(theta_y)*cos(theta_z) + sin(theta_x)*sin(theta_y)*sin(theta_z)
    let e12 = sin(theta_y)*sin(theta_x)*cos(theta_z) - cos(theta_y)*sin(theta_z)
    let e13 = sin(theta_y)*cos(theta_x)
    
    let e21 = cos(theta_x) * sin(theta_z)
    let e22 = cos(theta_x) * cos(theta_z)
    let e23 = -1 * sin(theta_x)

    let e31 = cos(theta_y)*sin(theta_x)*sin(theta_z) - sin(theta_y)*cos(theta_z)
    let e32 = sin(theta_y)*sin(theta_z) + cos(theta_y)*sin(theta_x)*cos(theta_z)
    let e33 = cos(theta_y)*cos(theta_x)

    //矩阵向量顺序 列一 列二 列三
    let TransMatrix = simd_float4x4(simd_float4(e11, e21, e31, 0),
                                    simd_float4(e12, e22, e32, 0),
                                    simd_float4(e13, e23, e33, 0),
                                    simd_float4(0, 0, 0, 1))
    
    //位姿校准
    //    var newPose = simd_float4x4(simd_float4(1,0,0,0),
    //                                simd_float4(0,1,0,0),
    //                                simd_float4(0,0,1,0),
    //                                simd_float4(0,0,0,1))
    
//    if abs(y_diff) > 0.1 {
//        newPose = newPose * simd_float4x4(SCNMatrix4MakeRotation(y_diff, 0, 1, 0))
//    }
//    if abs(x_diff) > 0.1 {
//        newPose = newPose * simd_float4x4(SCNMatrix4MakeRotation(x_diff, 1, 0, 0))
//    }
//    if abs(z_diff) > 0.1 {
//        newPose = newPose * simd_float4x4(SCNMatrix4MakeRotation(z_diff, 0, 0, 1))
//    }
//    print("\(newPose)")
    return TransMatrix
}

func coordinateAlignment(direction: simd_float3, distance: Float, myCam: ARCamera, peerEuler: simd_float3, pos: simd_float4) -> simd_float4 {
    //NI摄像头坐标系旋转至AR摄像头坐标系
    
    let dx: Float = -1 * direction.y * distance //单位 米
    let dy: Float = direction.x * distance
    let dz: Float = direction.z * distance
    let t = simd_float4(dx, dy, dz, 1)
    
    let theta_x = myCam.eulerAngles.x - peerEuler.x
    let theta_y = myCam.eulerAngles.y - peerEuler.y
    let theta_z = myCam.eulerAngles.z - peerEuler.z
    
    var T = simd_float4x4(diagonal: simd_float4(repeating: 1))
            * simd_float4x4(SCNMatrix4MakeRotation(theta_y, 0, 1, 0))
            * simd_float4x4(SCNMatrix4MakeRotation(theta_x, 1, 0, 0))
            * simd_float4x4(SCNMatrix4MakeRotation(theta_z, 0, 0, 1))
    
//    let e11 = cos(theta_y)*cos(theta_z) + sin(theta_x)*sin(theta_y)*sin(theta_z)
//    let e12 = sin(theta_y)*sin(theta_x)*cos(theta_z) - cos(theta_y)*sin(theta_z)
//    let e13 = sin(theta_y)*cos(theta_x)
//
//    let e21 = cos(theta_x) * sin(theta_z)
//    let e22 = cos(theta_x) * cos(theta_z)
//    let e23 = -1 * sin(theta_x)
//
//    let e31 = cos(theta_y)*sin(theta_x)*sin(theta_z) - sin(theta_y)*cos(theta_z)
//    let e32 = sin(theta_y)*sin(theta_z) + cos(theta_y)*sin(theta_x)*cos(theta_z)
//    let e33 = cos(theta_y)*cos(theta_x)
//
//    //矩阵向量顺序 列一 列二 列三
//    let TransMatrix = simd_float4x4(simd_float4(e11, e21, e31, 0),
//                                    simd_float4(e12, e22, e32, 0),
//                                    simd_float4(e13, e23, e33, 0),
//                                    t)
    
    
    let Tcw = myCam.transform
    
    
    
    let nPos = Tcw * T * pos
    
//    let theta_x: Float = eularAngle.x //单位 弧度数
//    let theta_y: Float = eularAngle.y
//    let theta_z: Float = eularAngle.z
    
    //方法一 利用EUS世界坐标系
    //失败 原因 数据交换不及时,不同型号间默认世界坐标系不同

    
    return nPos
}

//方法二 基于随机世界坐标系和初始位姿校准
//三角向量计算 O1代表主机的坐标原点 C1代表主机的摄像头位置 A代表ar物体被给予的虚拟锚点

func inverse(matrix: simd_float3x3) -> simd_float3x3 {
    return matrix.inverse
}

extension SCNVector3 {
    func convertToSIMD3() -> simd_float3 {
        return simd_float3(x, y, z)
    }
}

func position(from vector: simd_float4) -> simd_float3 {
    return simd_float3(vector.x, vector.y, vector.z)
}

func translation(from matrix: simd_float4x4, with position_diff: simd_float3) -> simd_float4x4 {
    var newmatrix = matrix
    newmatrix.columns.3.x += position_diff.x
    newmatrix.columns.3.y += position_diff.y
    newmatrix.columns.3.z += position_diff.z
    return newmatrix
}

func alignDistanceWithNI(distance: Float, direction: simd_float3) -> simd_float4 {
    let dx: Float = -1 * direction.y * distance //单位 米
    let dy: Float = direction.x * distance
    let dz: Float = direction.z * distance
    let t = simd_float4(dx, dy, dz, 1)
    return t
}

func optimizeAnchorPos(with anchor: ARAnchor) -> simd_float4? {
    if optimization.count <= 5 {
        optimization.count += 1
        optimization.optimumAnchorPos = (optimization.optimumAnchorPos + anchor.transform.columns.3)/(optimization.count + 1)
        return nil
    }
    else {
        let e = anchor.transform.columns.3 - optimization.optimumAnchorPos
        return e
    }
}

struct optimization {
    static var optimumAnchorPos: simd_float4 = simd_float4(0, 0, 0, 1)
    static var count:Float = 0
}

extension simd_float4 {
    static func - (v1: simd_float4, v2: simd_float4) -> simd_float4 {
        return simd_make_float4(v1.x-v2.x, v1.y-v2.y, v1.z-v2.z, v1.w-v2.w)
    }
}
