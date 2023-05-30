import Foundation
import CoreGraphics

class Images {
    static func cgImageSRGB(_ px: UnsafeRawPointer, w: Int, h: Int, pixelSize: Int) -> CGImage {
        let cgDataProvider = CGDataProvider(data: NSData(bytes: px, length: w * h * pixelSize))!
        let cgImage = CGImage(width: w,
                            height: h,
                            bitsPerComponent: 8,
                            bitsPerPixel: 32,
                            bytesPerRow: w*pixelSize,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
                            provider: cgDataProvider,
                            decode: nil,
                            shouldInterpolate: false,
                            intent: CGColorRenderingIntent.defaultIntent)!
        return cgImage
    }
}
