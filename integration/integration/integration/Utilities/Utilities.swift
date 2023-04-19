import Foundation
import ARKit
import UIKit
import VideoToolbox
import RealityKit


func isHigher(from elevation: Float) -> Bool {
    if elevation > 0 {
        return true
    } else {
        return false
    }
}

func collectData(with refFrame: ARFrame) {
    guard let featurePoints = refFrame.rawFeaturePoints?.points else { return }
    
    
    //利用列表存储信息
    var featurePointsIn2D: [CGPoint] = []
    
    for i in 0..<featurePoints.count {
        var featurePointIn2D = refFrame.camera.projectPoint(featurePoints[i], orientation: .portrait, viewportSize: CGSize(width: 360, height: 780))
        
        //强制转换类型，便于python处理
        if featurePointIn2D.x >= 0 && featurePointIn2D.y >= 0 {
            let x = Int(featurePointIn2D.x / 360 * 1440)
            let y = Int(featurePointIn2D.y / 780 * 1920)
            let newFeaturePoint = CGPoint(x: x, y: y)
            featurePointsIn2D.append(newFeaturePoint)
        }
        
    }
    
    print(featurePointsIn2D)
    
    
    for j in 0..<refFrame.anchors.count {
        let anchorPosition = refFrame.anchors[j].transform.columns.3
        print("\(anchorPosition)")
    }
    print("---------------------")
    
    
    // Save UIImage to Photos Album
    guard let uiImage = UIImage(pixelBuffer: refFrame.capturedImage, scale: 1.0, orientation: .right) else { return }
    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
    
    
    
    
}


extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer, scale: CGFloat, orientation: UIImage.Orientation) {
            var image: CGImage?
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)

            guard let cgImage = image else { return nil }

            self.init(cgImage: cgImage, scale: scale, orientation: orientation)
        }
    }

extension MeshResource {
    /**
     Generate three axes of a coordinate system with x axis = red, y axis = green and z axis = blue
     - parameters:
     - axisLength: Length of the axes in m
     - thickness: Thickness of the axes as a percentage of their length
     */
    static func generateCoordinateSystemAxes(length: Float = 0.1, thickness: Float = 2.0) -> Entity {
        let thicknessInM = (length / 100) * thickness
        let cornerRadius = thickness / 2.0
        let offset = length / 2.0
        
        let xAxisBox = MeshResource.generateBox(size: [length, thicknessInM, thicknessInM], cornerRadius: cornerRadius)
        let yAxisBox = MeshResource.generateBox(size: [thicknessInM, length, thicknessInM], cornerRadius: cornerRadius)
        let zAxisBox = MeshResource.generateBox(size: [thicknessInM, thicknessInM, length], cornerRadius: cornerRadius)
    
        let xAxis = ModelEntity(mesh: xAxisBox, materials: [UnlitMaterial(color: .red)])
        let yAxis = ModelEntity(mesh: yAxisBox, materials: [UnlitMaterial(color: .green)])
        let zAxis = ModelEntity(mesh: zAxisBox, materials: [UnlitMaterial(color: .blue)])
        
        xAxis.position = [offset, 0, 0]
        yAxis.position = [0, offset, 0]
        zAxis.position = [0, 0, offset]
        
        let axes = Entity()
        axes.addChild(xAxis)
        axes.addChild(yAxis)
        axes.addChild(zAxis)
        return axes
    }
}

extension UUID {
    /**
     - Tag: ToRandomColor
    Pseudo-randomly return one of several fixed standard colors, based on this UUID's first four bytes.
    */
    func toRandomColor() -> UIColor {
        var firstFourUUIDBytesAsUInt32: UInt32 = 0
        let data = withUnsafePointer(to: self) {
            return Data(bytes: $0, count: MemoryLayout.size(ofValue: self))
        }
        _ = withUnsafeMutableBytes(of: &firstFourUUIDBytesAsUInt32, { data.copyBytes(to: $0) })

        let colors: [UIColor] = [.red, .green, .blue, .yellow, .magenta, .cyan, .purple,
        .orange, .brown, .lightGray, .gray, .darkGray, .black, .white]
        
        let randomNumber = Int(firstFourUUIDBytesAsUInt32) % colors.count
        return colors[randomNumber]
    }
}


extension simd_float3x3: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        try self.init(diagonal: container.decode(SIMD3<Float>.self))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode([columns.0, columns.1, columns.2])
     }
 }

extension FloatingPoint {
    var degreeToRadians: Self { self * .pi / 180}
    var radiansToDegrees: Self { self * 180 / .pi }
}


extension UIButton {
    
    func addSinkAnimation() {
        self.layer.shadowColor = CGColor.init(red: 0,
                                              green: 0,
                                              blue: 0,
                                              alpha: 1)
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.layer.shadowOpacity = 0.8
        
        self.addTarget(self, action: #selector(self.sinkAction(_:)), for: .touchDown)
        self.addTarget(self, action: #selector(self.sinkReset(_:)), for: .touchUpInside)
        self.addTarget(self, action: #selector(self.sinkReset(_:)), for: .touchUpOutside)
    }
    
    @objc func sinkAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.95)
            sender.layer.shadowOpacity = 0
        }, completion: nil)
    }
    
    @objc func sinkReset(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            sender.transform = CGAffineTransform.identity
            sender.layer.shadowOpacity = 0.8
        }, completion: nil)
    }
}
