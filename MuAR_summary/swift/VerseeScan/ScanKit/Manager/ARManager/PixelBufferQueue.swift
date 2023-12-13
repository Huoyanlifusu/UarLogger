//
//  Temp.swift
//  ScanKit
//
//  Created by 张裕阳 on 2023/4/13.
//

import Foundation
import CoreVideo

struct PixelBufferQueue {
    static var queue = [CVPixelBuffer]()
    
    static var isEmpty: Bool {
        return queue.isEmpty
    }
}
