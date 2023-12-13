//
//  Texture.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/3/2.
//
import Foundation
import AVFoundation

public class ATexture {
    let texture: MTLTexture
    let textureKey: String

    public init(texture: MTLTexture, textureKey: String = "") {
        self.texture = texture
        self.textureKey = textureKey
    }
    
    public init(_ width: Int, _ height: Int, pixelFormat: MTLPixelFormat = .bgra8Unorm, textureKey: String = "") {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]

        guard let newTexture = sharedMetalRenderingDevice.device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Could not create texture of size: (\(width), \(height))")
        }

        self.texture = newTexture
        self.textureKey = textureKey
    }
}
