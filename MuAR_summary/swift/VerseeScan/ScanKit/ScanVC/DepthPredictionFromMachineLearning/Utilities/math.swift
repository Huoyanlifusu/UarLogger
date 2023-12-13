//
//  math.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/2/27.
//

import Foundation

struct Vertex {
    var position: vector_float4
    var textCoord: vector_float2

    init(position: CGPoint, textCoord: CGPoint) {
        self.position = position.toFloat4()
        self.textCoord = textCoord.toFloat2()
    }
}

class Matrix {

    private(set) var mat: [Float]

    static var identity = Matrix()

    private init() {
        mat = [1, 0, 0, 0,
             0, 1, 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1
        ]
    }

    @discardableResult
    func translation(xPos: Float, yPos: Float, zPos: Float) -> Matrix {
        mat[12] = xPos
        mat[13] = yPos
        mat[14] = zPos
        return self
    }

    @discardableResult
    func scaling(xScale: Float, yScale: Float, zScale: Float)  -> Matrix  {
        mat[0] = xScale
        mat[5] = yScale
        mat[10] = zScale
        return self
    }
}


extension CGPoint {
    func toFloat4(zComponent: CGFloat = 0, wComponent: CGFloat = 1) -> vector_float4 {
        return [Float(x), Float(y), Float(zComponent) ,Float(wComponent)]
    }
    
    func toFloat2() -> vector_float2 {
        return [Float(x), Float(y)]
    }
}
