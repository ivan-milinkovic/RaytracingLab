import Foundation

struct HSVColor: ExpressibleByArrayLiteral {
    
    var h: Double = 0
    var s: Double = 0
    var v: Double = 0
    
    init(arrayLiteral arr: Double...) {
        h = arr[0]
        s = arr[1]
        v = arr[2]
    }
    
    // FIX: Extremelly slow in debug
    func pixel() -> Pixel {
        // https://www.rapidtables.com/convert/color/hsv-to-rgb.html
        let H = h * 360
        let C = v * s
        let m = v - C
        let tmp = abs(Int(H/60) % 2 - 1)
        let X = C * (1 - Double(tmp))
        var (R0, G0, B0) : (Double, Double, Double)
        switch H {
        case 0..<60:    (R0, G0, B0) = (C, X, 0)
        case 60..<120:  (R0, G0, B0) = (X, C, 0)
        case 120..<180: (R0, G0, B0) = (0, C, X)
        case 180..<240: (R0, G0, B0) = (0, X, C)
        case 240..<300: (R0, G0, B0) = (X, 0, C)
        case 300..<360: (R0, G0, B0) = (C, 0, X)
        default: (R0, G0, B0) = (0, 0, 0) // invalid state
        }

        return Pixel(r: UInt8((R0 + m) * 255), g: UInt8((G0 + m) * 255), b: UInt8((B0 + m) * 255))
    }
    
    static var white: HSVColor {
        [1, 1, 1]
    }
    
    static var blue: HSVColor {
        [0.6, 0.2, 0.2]
    }
    
    static var red: HSVColor {
        [0.0, 0.4, 0.6, 0.4]
    }
    
    static var green: HSVColor {
        [0.3, 0.8, 0.4, 1.0]
    }
    
    static func + (c1: HSVColor, c2: HSVColor) -> HSVColor {
        [c1.h + c2.h,
         c1.s + c2.s,
         c1.v + c2.v]
    }
}

/*
func pixel() -> Pixel {
    // https://www.rapidtables.com/convert/color/hsv-to-rgb.html
    let H = h * 360
    let C = v * s
    let m = v - C
    let tmp = abs(Int(H/60) % 2 - 1)
    let X = C * (1 - Double(tmp))
    var (R0, G0, B0) : (Double, Double, Double)
    if 0 <= H && H < 60 {
        (R0, G0, B0) = (C, X, 0)
    }
    else if 60 <= H && H < 120 {
        (R0, G0, B0) = (X, C, 0)
    }
    else if 120 <= H && H < 180 {
        (R0, G0, B0) = (0, C, X)
    }
    else if 180 <= H && H < 240 {
        (R0, G0, B0) = (0, X, C)
    }
    else if 240 <= H && H < 300 {
        (R0, G0, B0) = (X, 0, C)
    }
    else if 300 <= H && H < 360 {
        (R0, G0, B0) = (C, 0, X)
    } else {
        // invalid state
        (R0, G0, B0) = (0, 0, 0)
    }
    return Pixel(r: UInt8((R0 + m) * 255), g: UInt8((G0 + m) * 255), b: UInt8((B0 + m) * 255))
}
*/
