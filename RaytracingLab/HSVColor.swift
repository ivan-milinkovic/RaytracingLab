import Foundation

struct HSVColor: ExpressibleByArrayLiteral {
    
    var h: Double = 0
    var s: Double = 0
    var v: Double = 0
    
    init(h: Double = 0, s: Double = 0, v: Double = 0) {
        self.h = clamp01(h)
        self.s = clamp01(s)
        self.v = clamp01(v)
    }
    
    init(arrayLiteral arr: Double...) {
        h = clamp01(arr[0])
        s = clamp01(arr[1])
        v = clamp01(arr[2])
    }
    
    func pixel() -> Pixel {
        let (r, g, b) = rgb()
        return Pixel(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255))
    }
    
    func rgb() -> (Double, Double, Double) { // https://stackoverflow.com/a/36209005/3729266
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
    
    static var white: HSVColor {
        [1, 1, 1]
    }
    
    static var blue: HSVColor {
        [0.65, 0.4, 0.5]
    }
    
    static var red: HSVColor {
        [0.0, 0.4, 0.5]
    }
    
    static var green: HSVColor {
        [0.4, 0.4, 0.5]
    }
    
    static var yellow: HSVColor {
        [0.3, 0.4, 0.5]
    }
}
