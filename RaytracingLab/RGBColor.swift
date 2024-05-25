import Foundation

func clamp01(_ x: Double) -> Double {
    min(1, max(0, x))
}

struct RGBColor: ExpressibleByArrayLiteral {
    
    var r: Double = 0
    var g: Double = 0
    var b: Double = 0
    
    init(r: Double = 0, g: Double = 0, b: Double = 0) {
        self.r = clamp01(r)
        self.g = clamp01(g)
        self.b = clamp01(b)
    }
    
    init(arrayLiteral arr: Double...) {
        r = clamp01(arr[0])
        g = clamp01(arr[1])
        b = clamp01(arr[2])
    }
    
    mutating func mult(_ f: Double) {
        r = clamp01(r * f)
        g = clamp01(g * f)
        b = clamp01(b * f)
    }
    
    func multRGB(_ f: Double) -> RGBColor {
        RGBColor(r: r * f,
                 g: g * f,
                 b: b * f)
    }
    
    func pixel() -> Pixel {
        Pixel(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255))
    }
    
    static var white: RGBColor {
        [1, 1, 1, 1.0]
    }
    
    static var black: RGBColor {
        [0, 0, 0, 0]
    }
    
    static var blue: RGBColor {
        [0.4, 0.6, 0.8, 1.0]
    }
    
    static var red: RGBColor {
        [0.8, 0.4, 0.6, 1.0]
    }
    
    static var green: RGBColor {
        [0.6, 0.8, 0.4, 1.0]
    }
    
    static func + (c1: RGBColor, c2: RGBColor) -> RGBColor {
        [c1.r + c2.r,
         c1.g + c2.g,
         c1.b + c2.b]
    }
}

func add(c1: RGBColor, w1: Double, c2: RGBColor, w2: Double) -> RGBColor {
    [c1.r * w1  +  c2.r * w2,
     c1.g * w1  +  c2.g * w2,
     c1.b * w1  +  c2.b * w2]
}
