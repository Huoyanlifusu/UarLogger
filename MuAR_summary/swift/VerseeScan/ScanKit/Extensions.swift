//
//  Extensions.swift
//  ScanKit
//
//  Created by Kenneth Schröder on 11.08.21.
//

import Foundation
import MetalKit
import ARKit
import VideoToolbox

typealias Float2 = SIMD2<Float>
typealias Float3 = SIMD3<Float>

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func / (lhs: CGPoint, rhs: Float) -> CGPoint {
    return CGPoint(x: lhs.x / CGFloat(rhs), y: lhs.y / CGFloat(rhs))
}

extension CGPoint {
    func convertCoordinateSystemReverseXY(from: CGSize, to: CGSize) -> CGPoint {
        let widthFactor = to.width / from.height
        let heightFactor = to.height / from.width
        return CGPoint(x: y * heightFactor, y: x * widthFactor )
    }
}

extension Float {
    static let degreesToRadian = Float.pi / 180
}

extension matrix_float3x3 {
    mutating func copy(from affine: CGAffineTransform) {
        columns.0 = Float3(Float(affine.a), Float(affine.c), Float(affine.tx))
        columns.1 = Float3(Float(affine.b), Float(affine.d), Float(affine.ty))
        columns.2 = Float3(0, 0, 1)
    }
}

extension MTKView : RenderDestinationProvider {
}

extension ARCamera {
    func getPosition() -> Float3 {
        return Float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}

protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}

protocol CollectionWriter: AnyObject {
    var delegate: CollectionWriterDelegate? { get set }
    func getCurrentOutputPath() -> URL
    func getLastWrittenFrame() -> Int
    func getLastWrittenTitle() -> String
}

protocol CollectionWriterDelegate: AnyObject {
    func fileWritten()
}

protocol ProgressTracker: AnyObject {
    func notifyProgressRaw(value: Float)
    func notifyProgressPC(value: Float)
}

// https://stackoverflow.com/questions/28332946/how-do-i-get-the-current-date-in-short-format-in-swift
extension Date {
    func string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}

// https://stackoverflow.com/questions/62750759/how-to-run-tflite-model-with-arkit-session-captured-image
extension CIImage {
    func resize(size : CGSize) -> CIImage {
        let scale = min(size.width, size.height) / min(self.extent.size.width, self.extent.size.height)
        let resizedImage = self.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let width = resizedImage.extent.size.width
        let height = resizedImage.extent.size.height
        let xOffset = (CGFloat(width) - size.width) / 2.0
        let yOffset = (CGFloat(height) - size.height) / 2.0
        let rect = CGRect(x: xOffset, y: yOffset, width: size.width, height: size.height)
        return resizedImage
            .clamped(to: rect)
            .cropped(to: CGRect(x: 0, y: 0, width: size.width, height: size.height))

    }
    
    func toPixelBuffer(context : CIContext, size inSize:CGSize? = nil, gray : Bool = true) -> CVPixelBuffer? {
        let attributes = [

            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,

            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue ] as CFDictionary

        var nullablePixelBuffer : CVPixelBuffer? = nil

        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.extent.size.width), Int(self.extent.size.height), kCVPixelFormatType_32BGRA, attributes, &nullablePixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer = nullablePixelBuffer else {

            return nil

        }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        context.render(self, to: pixelBuffer, bounds: CGRect(x: 0, y: 0, width: self.extent.size.width, height: self.extent.size.height), colorSpace: gray ? CGColorSpaceCreateDeviceGray() : self.colorSpace)

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer

    }

}

extension CVPixelBuffer {
    
    func texture(withFormat pixelFormat: MTLPixelFormat, planeIndex: Int, addToCache cache: CVMetalTextureCache) -> MTLTexture? {
        
        let width = CVPixelBufferGetWidthOfPlane(self, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(self, planeIndex)
        
        var cvtexture: CVMetalTexture?
        _ = CVMetalTextureCacheCreateTextureFromImage(nil, cache, self, nil, pixelFormat, width, height, planeIndex, &cvtexture)
        let texture = CVMetalTextureGetTexture(cvtexture!)
        
        return texture
        
    }
    
}

extension MTLClearColor {
    static var red: Self {
        return MTLClearColorMake(1, 0, 0, 1) // r, g, b, a
    }
}

extension MLMultiArray {
    func flatten() -> [Double] {
        let length = self.count
        let doublePtr = self.dataPointer.bindMemory(to: Double.self, capacity: length)
        let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
        let outputArray = Array(doubleBuffer)
        return outputArray
    }
    // https://stackoverflow.com/questions/61709079/convert-mlmultiarray-to-float
    // 无法直接转换为float array
    func flattenToFloat() -> [Float]? {
        if let pointer = try? UnsafeBufferPointer<Float>(self) {
            let array = Array(pointer)
            return array
        }
        return nil
    }
}

extension vector_float3 {
    func toSIMD() -> simd_float4 {
        return simd_make_float4(self, 1)
    }
}

extension CGRect {
    func toCGSize() -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

extension simd_float3 {
    func toColumn() -> simd_float4 {
        return simd_float4(self, 0)
    }
}

extension simd_float4 {
    func normalize() -> simd_float3 {
        return simd_float3(x: self.x/self.w, y: self.y/self.w, z: self.z/self.w)
    }
}
// https://stackoverflow.com/questions/45703436/swift-3-convert-arraydouble-to-arrayfloat-extension
extension Array where Element == Double {
    public var asArrayOfFloat: [Float] {
        return self.map { return Float($0) }
    }
}

// MARK: - Dir Size Calculation https://gist.github.com/NikolaiRuhe/408cefb953c4bea15506a3f80a3e5b96

public extension FileManager {

    /// Calculate the allocated size of a directory and all its contents on the volume.
    ///
    /// As there's no simple way to get this information from the file system the method
    /// has to crawl the entire hierarchy, accumulating the overall sum on the way.
    /// The resulting value is roughly equivalent with the amount of bytes
    /// that would become available on the volume if the directory would be deleted.
    ///
    /// - note: There are a couple of oddities that are not taken into account (like symbolic links, meta data of
    /// directories, hard links, ...).
    func allocatedSizeOfDirectory(at directoryURL: URL) throws -> UInt64 {

        // The error handler simply stores the error and stops traversal
        var enumeratorError: Error? = nil
        func errorHandler(_: URL, error: Error) -> Bool {
            enumeratorError = error
            return false
        }

        // We have to enumerate all directory contents, including subdirectories.
        let enumerator = self.enumerator(at: directoryURL,
                                         includingPropertiesForKeys: Array(allocatedSizeResourceKeys),
                                         options: [],
                                         errorHandler: errorHandler)!

        // We'll sum up content size here:
        var accumulatedSize: UInt64 = 0

        // Perform the traversal.
        for item in enumerator {

            // Bail out on errors from the errorHandler.
            if enumeratorError != nil { break }

            // Add up individual file sizes.
            let contentItemURL = item as! URL
            accumulatedSize += try contentItemURL.regularFileAllocatedSize()
        }

        // Rethrow errors from errorHandler.
        if let error = enumeratorError { throw error }

        return accumulatedSize
    }
}


fileprivate let allocatedSizeResourceKeys: Set<URLResourceKey> = [
    .isRegularFileKey,
    .fileAllocatedSizeKey,
    .totalFileAllocatedSizeKey,
]


fileprivate extension URL {

    func regularFileAllocatedSize() throws -> UInt64 {
        let resourceValues = try self.resourceValues(forKeys: allocatedSizeResourceKeys)

        // We only look at regular files.
        guard resourceValues.isRegularFile ?? false else {
            return 0
        }

        // To get the file's size we first try the most comprehensive value in terms of what
        // the file may use on disk. This includes metadata, compression (on file system
        // level) and block size.
        // In case totalFileAllocatedSize is unavailable we use the fallback value (excluding
        // meta data and compression) This value should always be available.
        return UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
    }
}

extension UIDevice {
    
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    //MARK: Get String Value
    var totalDiskSpaceInGB:String {
       return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var freeDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var usedDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInMB:String {
        return MBFormatter(totalDiskSpaceInBytes)
    }
    
    var freeDiskSpaceInMB:String {
        return MBFormatter(freeDiskSpaceInBytes)
    }
    
    var usedDiskSpaceInMB:String {
        return MBFormatter(usedDiskSpaceInBytes)
    }
    
    //MARK: Get raw value
    var totalDiskSpaceInBytes:Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }
    
    /*
     Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible.
     */
    var freeDiskSpaceInBytes:Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }
    
    var usedDiskSpaceInBytes:Int64 {
       return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }
}

extension CVPixelBuffer {
    func pixelBufferToUIImage() -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: self)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let uiImage = UIImage(cgImage: cgImage!)
        return uiImage
    }
}

func pixelBufferFromCGImage(image: CGImage) -> CVPixelBuffer {
    var pxbuffer: CVPixelBuffer? = nil
    let options: NSDictionary = [:]

    let width =  image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow

    let dataFromImageDataProvider = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, image.dataProvider!.data)
    let x = CFDataGetMutableBytePtr(dataFromImageDataProvider)!


    CVPixelBufferCreateWithBytes(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32ARGB,
        x,
        bytesPerRow,
        nil,
        nil,
        options,
        &pxbuffer
    )
    return pxbuffer!;
}

extension UIImage {

    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard let image = cgImage else { return nil }
        self.init(cgImage: image)
    }

    public func crop(rect: CGRect) -> UIImage? {
        var rect = rect
        rect.origin.x *= scale
        rect.origin.y *= scale
        rect.size.width *= scale
        rect.size.height *= scale

        if let imageRef = cgImage?.cropping(to: rect) {
            return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        }
        return nil
    }

    public func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size

        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, true, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))

        self.draw(in: CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width, height: size.height
        ))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    public func getOrCreateCGImage() -> CGImage? {
        return cgImage ?? ciImage.flatMap {
                let context = CIContext()
                return context.createCGImage($0, from: $0.extent)
        }
    }

    /**
     Scales the image to the given height while preserving its aspect ratio.
     */
    public func resize(toHeight newHeight: CGFloat) -> UIImage? {
        guard self.size.height != newHeight else { return self }
        let ratio = newHeight / size.height
        let newSize = CGSize(width: size.width * ratio, height: newHeight)
        return resize(to: newSize)
    }

    /**
     Scales the image to the given width while preserving its aspect ratio.
     */
    public func resize(toWidth newWidth: CGFloat) -> UIImage? {
        guard self.size.width != newWidth else { return self }
        let ratio = newWidth / size.width
        let newSize = CGSize(width: newWidth, height: size.height * ratio)
        return resize(to: newSize)
    }

    private func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }

}

import CoreLocation

extension CLLocation {

    func exifMetadata(heading:CLHeading? = nil) -> NSMutableDictionary {

        let GPSMetadata = NSMutableDictionary()
        let altitudeRef = Int(self.altitude < 0.0 ? 1 : 0)
        let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
        let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"

        // GPS metadata
        GPSMetadata[(kCGImagePropertyGPSLatitude as String)] = abs(self.coordinate.latitude)
        GPSMetadata[(kCGImagePropertyGPSLongitude as String)] = abs(self.coordinate.longitude)
        GPSMetadata[(kCGImagePropertyGPSLatitudeRef as String)] = latitudeRef
        GPSMetadata[(kCGImagePropertyGPSLongitudeRef as String)] = longitudeRef
        GPSMetadata[(kCGImagePropertyGPSAltitude as String)] = Int(abs(self.altitude))
        GPSMetadata[(kCGImagePropertyGPSAltitudeRef as String)] = altitudeRef
        GPSMetadata[(kCGImagePropertyGPSTimeStamp as String)] = self.timestamp.isoTime()
        GPSMetadata[(kCGImagePropertyGPSDateStamp as String)] = self.timestamp.isoDate()
        GPSMetadata[(kCGImagePropertyGPSVersion as String)] = "2.2.0.0"

        if let heading = heading {
            GPSMetadata[(kCGImagePropertyGPSImgDirection as String)] = heading.trueHeading
            GPSMetadata[(kCGImagePropertyGPSImgDirectionRef as String)] = "T"
        }

        return GPSMetadata
    }
}

extension Date {

    func isoDate() -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: "UTC")
        f.dateFormat = "yyyy:MM:dd"
        return f.string(from: self)
    }

    func isoTime() -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: "UTC")
        f.dateFormat = "HH:mm:ss.SSSSSS"
        return f.string(from: self)
    }
}
