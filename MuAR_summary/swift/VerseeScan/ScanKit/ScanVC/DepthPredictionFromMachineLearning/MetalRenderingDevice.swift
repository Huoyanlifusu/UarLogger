//
//  MetalRenderingDevice.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/2.
//
// 深度材质渲染
import CoreGraphics
import Metal
import CoreVideo
import CoreImage

public let sharedMetalRenderingDevice = MetalRenderingDevice()

public class MetalRenderingDevice {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Could not create Metal Device") }
        self.device = device

        guard let queue = self.device.makeCommandQueue() else { fatalError("Could not create command queue") }
        self.commandQueue = queue
    }
    //over
    func generateRenderPipelineDescriptor(_ vertexFuncName: String, _ fragmentFuncName: String, _ colorPixelFormat: MTLPixelFormat = .bgra8Unorm) throws -> MTLRenderPipelineDescriptor {
        let library = self.device.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: vertexFuncName)
        let fragment_func = library.makeFunction(name: fragmentFuncName)
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = colorPixelFormat

        return rpd
    }
    //over
    func makeRenderVertexBuffer(_ origin: CGPoint = .zero, size: CGSize) -> MTLBuffer? {
        let w = size.width, h = size.height
        let vertices = [
            Vertex(position: CGPoint(x: origin.x , y: origin.y), textCoord: CGPoint(x: 0, y: 0)),
            Vertex(position: CGPoint(x: origin.x + w , y: origin.y), textCoord: CGPoint(x: 1, y: 0)),
            Vertex(position: CGPoint(x: origin.x + 0 , y: origin.y + h), textCoord: CGPoint(x: 0, y: 1)),
            Vertex(position: CGPoint(x: origin.x + w , y: origin.y + h), textCoord: CGPoint(x: 1, y: 1)),
        ]
        return makeRenderVertexBuffer(vertices)
    }
    //over
    func makeRenderVertexBuffer(_ vertices: [Vertex]) -> MTLBuffer? {
        return self.device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: .cpuCacheModeWriteCombined)
    }
    //over
    func makeRenderUniformBuffer(_ size: CGSize) -> MTLBuffer? {
        let metrix = Matrix.identity
        metrix.scaling(xScale: 2 / Float(size.width), yScale: -2 / Float(size.height), zScale: 1)
        metrix.translation(xPos: -1, yPos: 1, zPos: 0)
        return self.device.makeBuffer(bytes: metrix.mat, length: MemoryLayout<Float>.size * 16, options: [])
    }
}

extension MetalRenderingDevice {
    func toCVPixelBuffer(_ image: CIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                       kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(image.extent.width),
                                         Int(image.extent.height),
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         &pixelBuffer)

        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        let CIContext = CIContext(mtlDevice: device)
        CIContext.render(image, to: pixelBuffer!)
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }
        return pixelBuffer
    }
}
