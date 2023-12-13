//
//  MetalVideoView.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/1.
//

import Foundation
import Metal
import MetalKit
// 复写MTKView，作为深度预测结果的显示图像
public class MetalVideoView: MTKView {
    public var currentTexture: ATexture? {
        willSet (newValue) {
            guard let texture = newValue else { return }
            drawableSize = CGSize(width: texture.texture.width, height: texture.texture.height)
        }
    }
    private var pipelineState: MTLRenderPipelineState!
    private var render_target_vertex: MTLBuffer!
    private var render_target_uniform: MTLBuffer!
    
    public override init(frame frameRect: CGRect, device: MTLDevice? = MTLCreateSystemDefaultDevice()!) {
        super.init(frame: frameRect, device: device)
        setup()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)

        setup()
    }

    private func setup() {
        self.device = sharedMetalRenderingDevice.device

        isOpaque = false
        setupTargetUniforms()

        do {
            try setupPiplineState()
        } catch {
            fatalError("Metal initialize failed: \(error.localizedDescription)")
        }
    }

    func setupTargetUniforms() {
        let size = drawableSize
        render_target_vertex = sharedMetalRenderingDevice.makeRenderVertexBuffer(size: size)
        render_target_uniform = sharedMetalRenderingDevice.makeRenderUniformBuffer(size)
    }

    private func setupPiplineState() throws {
        let rpd = try sharedMetalRenderingDevice.generateRenderPipelineDescriptor("vertex_render_target",
                                                                                  "fragment_render_target",
                                                                                  colorPixelFormat)
        pipelineState = try sharedMetalRenderingDevice.device.makeRenderPipelineState(descriptor: rpd)
    }

    public override func draw(_ rect:CGRect) {
        if let currentDrawable = self.currentDrawable, let imageTexture = currentTexture {
            let renderPassDescriptor = MTLRenderPassDescriptor()
            let attachment = renderPassDescriptor.colorAttachments[0]
            attachment?.clearColor = clearColor
            attachment?.texture = currentDrawable.texture
            attachment?.loadAction = .clear
            attachment?.storeAction = .store

            let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

            commandEncoder?.setRenderPipelineState(pipelineState)

            commandEncoder?.setVertexBuffer(render_target_vertex, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(render_target_uniform, offset: 0, index: 1)
            commandEncoder?.setFragmentTexture(imageTexture.texture, index: 0)
            commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            commandEncoder?.endEncoding()
            commandBuffer?.present(currentDrawable)
            commandBuffer?.commit()
        }
    }
}
