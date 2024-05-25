import Foundation

struct HSLColor: ExpressibleByArrayLiteral {
    
    var h: Double = 0
    var s: Double = 0
    var l: Double = 0
    
    init(_ h: Double = 0, _ s: Double = 0, _ l: Double = 0) {
        self.h = clamp01(h)
        self.s = clamp01(s)
        self.l = clamp01(l)
    }
    
    init(arrayLiteral arr: Double...) {
        h = clamp01(arr[0])
        s = clamp01(arr[1])
        l = clamp01(arr[2])
    }
    
    func pixel() -> Pixel {
        let (r, g, b) = rgb()
        return Pixel(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255))
    }
    
    func rgb() -> (Double, Double, Double) { // https://stackoverflow.com/a/9493060/3729266
        
        func hueToRgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1.0/6.0 { return p + (q - p) * 6.0 * t }
            if t < 1.0/2.0 { return q }
            if t < 2.0/3.0 { return p + (q - p) * (2.0/3.0 - t) * 6 }
            return p
        }
        
        var r, g, b: Double
        
        if (s == 0) {
            r = l; g = l; b = l
        } else {
            let q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            let p = 2 * l - q;
            r = hueToRgb(p, q, h + 1.0/3.0);
            g = hueToRgb(p, q, h);
            b = hueToRgb(p, q, h - 1.0/3.0);
        }
        
        return (r,g,b);
    }
    
    static var white: HSLColor {
        [1, 1, 1]
    }
    
    static var black: HSLColor {
        [0, 0, 0]
    }
    
    static var blue: HSLColor {
        [0.65, 0.4, 0.5]
    }
    
    static var red: HSLColor {
        [0.0, 0.4, 0.5]
    }
    
    static var green: HSLColor {
        [0.4, 0.4, 0.5]
    }
    
    static var yellow: HSLColor {
        [0.3, 0.4, 0.5]
    }
}
