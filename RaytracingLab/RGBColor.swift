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

func hsv_to_rgb(hsv: (Double, Double, Double)) -> (Double, Double, Double) { // https://stackoverflow.com/a/36209005/3729266
    let (h,s,v) = hsv
    
    var H = h*360, S = s, V = v
    var P, Q, T, fract: Double
    
    H = (H == 1.0) ? 0 : H/60
    fract = H - floor(H);
    P = V*(1 - S);
    Q = V*(1 - S * fract);
    T = V*(1 - S * (1 - fract));
    
    var (r,g,b): (Double, Double, Double)
    if      0 <= H && H < 1 {
        (r,g,b) = (V, T, P)
    } else if H < 2 {
        (r,g,b) = (Q, V, P)
    } else if H < 3 {
        (r,g,b) = (P, V, T)
    } else if H < 4 {
        (r,g,b) = (P, Q, V)
    } else if H < 5 {
        (r,g,b) = (T, P, V)
    } else if H < 6 {
        (r,g,b) = (V, P, Q)
    } else {
        (r,g,b) = (0,0,0)
    }
    
    return (r,g,b)
}

func hsl_to_rgb(hsl: (Double, Double, Double)) -> (Double, Double, Double) { // https://stackoverflow.com/a/9493060/3729266
    
    func hueToRgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
        var t = t
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        if t < 1.0/6.0 { return p + (q - p) * 6.0 * t }
        if t < 1.0/2.0 { return q }
        if t < 2.0/3.0 { return p + (q - p) * (2.0/3.0 - t) * 6 }
        return p
    }
    
    let (h,s,l) = hsl
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
