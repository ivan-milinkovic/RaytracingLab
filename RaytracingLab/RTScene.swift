import Foundation
import QuartzCore

let rtscene = RTScene()

class RTScene {
    
    var pixels : [Pixel]
    let w = 400
    let h = 400
    let numBounces = 1
    var update: (() -> Void)? = nil
    
    var circles: [Circle] = [
//        Circle(c: [-3, 0, -5], r: 1, mat: Material(color: Color.red)),
//        Circle(c: [ 0, 1, -5], r: 1, mat: Material(color: Color.blue)),
//        Circle(c: [ 2, 0, -5], r: 1, mat: Material(color: Color.green))
        
        Circle(c: [-3, 0, -5], r: 1, mat: Material(colorHSV: HSVColor.red)),
        Circle(c: [ 0, 1, -5], r: 1, mat: Material(colorHSV: HSVColor.blue)),
        Circle(c: [ 2, 0, -5], r: 1, mat: Material(colorHSV: HSVColor.green))
        
//        Circle(c: [ 0, 0, 0], r: 1, mat: Material(colorHSV: HSVColor.white)),
//        Circle(c: [ 1, 0, 0], r: 1, mat: Material(colorHSV: HSVColor.red)),
//        Circle(c: [ 0, 1, 0], r: 1, mat: Material(colorHSV: HSVColor.green)),
//        Circle(c: [ 0, 0,-1], r: 1, mat: Material(colorHSV: HSVColor.blue))
    ]
    
    let light : Vector = [0, 5, 0]
    
    init() {
        pixels = [Pixel].init(repeating: Pixel(), count: w*h)
    }
    
    func mark(point: CGPoint) {
        let x = Int(point.x)
        let y = Int(point.y)
        guard (0..<w).contains(x), (0..<h).contains(y)
        else { return }
        var px = pixels[y*w + x]
        px.r = 255
        px.g = 255
        px.b = 255
        pixels[y*w + x] = px
        update?()
    }
    
//    func test() {
//        let c = Circle(c: [0, 0, -5], r: 1)
//        let i = intersection(rayOrigin: [0, 0, 0], rayDir: [0, 0, -1], circle: c)
//        print()
//    }
    
    func render() {
        let start = CACurrentMediaTime()
//        renderIterative()
        renderRecursive()
        let dt = CACurrentMediaTime() - start
        print("render time: \(Int(dt*1000))ms")
        update?()
    }
    
    func renderIterative() {
        // define viewing frustum
        // projection plane x=[-1, 1], y=[-1, 1], z = -1
        
        for y in 0..<h {
            for x in 0..<w {
                
                var rayOrigin : Vector
                var rayDir : Vector
                var bounceResults = [Hit]()
                
                (rayOrigin, rayDir) = createViewerRay(x: x, y: y)
                if rayOrigin.isNaN || rayDir.isNaN {
                    continue
                }
                
                for i in 0..<numBounces {
                    if i > 0 {
                        let prevIntersection = bounceResults[i-1].its
                        rayOrigin = prevIntersection.point
                        rayDir = rotate(rayDir, axis: prevIntersection.normal, rad: Double.pi)
                    }
                    guard let h = closestHit(rayOrigin: rayOrigin, rayDir: rayDir) else { break }
                    bounceResults.append(h)
                }
                
                var colors = [Color]()
                for i in stride(from: bounceResults.count-1, through: 0, by: -1) {
                    let hit = bounceResults[i]
                    let lightAmount = lightAmount(point: hit.its.point, normal: hit.its.normal, light: light)
                    let color = hit.c.mat.colorRGB.multRGB(lightAmount)
                    colors.append(color)
                }
                
                var color : Color = [0, 0, 0, 1]
                if colors.count > 0 {
                    color = colors[0]
                    var i = 1; while i < colors.count-1 { defer { i += 1 }
                        color = color.multRGB(0.8) + colors[i].multRGB(0.2)
                    }
                }
                
                pixels[y*w + x] = color.pixel()
            }
        }
    }
    
    func renderRecursive() {
        // define viewing frustum
        // projection plane x=[-1, 1], y=[-1, 1], z = -1
        
        for y in 0..<h {
            for x in 0..<w {
                let (rayOrigin, rayDir) = createViewerRay(x: x, y: y)
                if rayOrigin.isNaN || rayDir.isNaN {
                    continue // invalid state
                }
                let color = trace(rayOrigin: rayOrigin, rayDir: rayDir, iteration: 1)
                pixels[y*w + x] = color?.pixel() ?? Pixel()
//                if let color {
//                    pixels[y*w + x] = Pixel(white: color.v)
//                } else {
//                    pixels[y*w + x] = Pixel()
//                }
            }
        }
    }
    
    private func trace(rayOrigin: Vector, rayDir: Vector, iteration: Int) -> HSVColor? {
        if iteration > numBounces { return nil }
        guard let hit = closestHit(rayOrigin: rayOrigin, rayDir: rayDir) else { return nil }
//        return [0, 0, 1]
        
        let reflectedRayDir = rotate(rayDir, axis: hit.its.normal, rad: Double.pi)
        let lightAmount = lightAmount(point: hit.its.point, normal: hit.its.normal, light: light)
        var sumLight = lightAmount
        
        if let sceneColor = trace(rayOrigin: hit.its.point, rayDir: reflectedRayDir, iteration: iteration + 1) {
            sumLight += sceneColor.v
            if sumLight > 1.0 {
                sumLight = 1.0
            }
        }
        
        let result: HSVColor = [0, 0, sumLight]
        return result
    }
    
//    struct CameraRayIterator {
//        let w: Int
//        let h: Int
//        let viewerRayBuilder: (_ x: Int, _ y: Int) -> (rayOrigin: Vector, rayDir: Vector)
//        private var i = 0
//        mutating func next() -> (rayOrigin: Vector, rayDir: Vector, x:Int, y: Int)? {
//            defer { i += 1 }
//            if i == w * h { return nil }
//            let x = i % w
//            let y = i / h + (x != 0 ? 1 : 0)
//            let (rayOrigin, rayDir) = viewerRayBuilder(x, y)
//            return (rayOrigin: rayOrigin, rayDir: rayDir, x: x, y: y)
//        }
//    }
    
    
    func lightAmount(point: Vector, normal: Vector, light: Vector) -> Double {
        let toLight = norm(light - point)
        let cos = dot(normal, toLight)
        let amount = cos >= 0 ? cos : 0.0
        return amount
    }
    
    func createViewerRay(x: Int, y: Int) -> (rayOrigin: Vector, rayDir: Vector) {
        let eye : Vector = [0, 0, 0]
        // convert pixel coordinates to world coordinates (plane in the 3D space)
        let canvasX = (Double(x)/Double(w))*2 - 1
        let canvasY = ((Double(y)/Double(h))*2 - 1) * -1 // * -1 to flip for UI
//        let ratio = Double(h) / Double(w)
//        let dy = (((Double(y)/Double(h))*2 - 1) * -1) * ratio
        let nearPlaneZ = Double(-1)
        let pixelWorldPosition : Vector = [canvasX, canvasY, nearPlaneZ]
        
        let viewerRight : Vector = [1, 0, 0]
        let viewerAdjusted = eye + (viewerRight * (0.0 * canvasX)) // todo: prevent fish eye effect
        let rayDir = norm(pixelWorldPosition - viewerAdjusted)
        
        return (rayOrigin: pixelWorldPosition, rayDir: rayDir)
    }
    
    func closestHit(rayOrigin: Vector, rayDir: Vector) -> Hit? {
        var result : Hit? = nil
        for c in circles {
            guard let i = intersection(rayOrigin: rayOrigin, rayDir: rayDir, circle: c)
            else { continue }
            
            if result == nil {
                result = Hit(c: c, its: i)
                continue
            }
            if len(i.point - rayOrigin) < len(result!.its.point - rayOrigin) {
                result = Hit(c: c, its: i)
            }
        }
        return result
    }
    
    func intersection(rayOrigin: Vector, rayDir: Vector, circle: Circle) -> Intersection? {
        let d = circle.c - rayOrigin
        let dn = norm(d)
        let d_len = len(d)
        let cos = dot(rayDir, dn)
        if cos <= 0 { return nil }
        let offsetToMiddle = d_len * cos
        let offsetFromMiddleSquared = circle.r * circle.r - d_len * d_len * (1.0 - cos * cos)
        if offsetFromMiddleSquared < 0 { return nil }
        let offsetFromMiddle = sqrt(offsetFromMiddleSquared)
        let offset = offsetToMiddle - offsetFromMiddle // +/- possible 2 solutions
        let intersection = rayDir * offset
        let normal = norm(intersection - circle.c)
        return Intersection(point: intersection, normal: normal)
    }
}

//struct TraceResult {
//    let hit: Hit
//    let color: Pixel
//}

struct Hit {
    let c: Circle
    let its: Intersection
}

struct Intersection {
    let point: Vector
    let normal: Vector
}

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
    
//    func pixel() -> Pixel {
//        // https://www.rapidtables.com/convert/color/hsv-to-rgb.html
//        let H = h * 360
//        let C = v * s
//        let m = v - C
//        let tmp = abs(Int(H/60) % 2 - 1)
//        let X = C * (1 - Double(tmp))
//        var (R0, G0, B0) : (Double, Double, Double)
//        if 0 <= H && H < 60 {
//            (R0, G0, B0) = (C, X, 0)
//        }
//        else if 60 <= H && H < 120 {
//            (R0, G0, B0) = (X, C, 0)
//        }
//        else if 120 <= H && H < 180 {
//            (R0, G0, B0) = (0, C, X)
//        }
//        else if 180 <= H && H < 240 {
//            (R0, G0, B0) = (0, X, C)
//        }
//        else if 240 <= H && H < 300 {
//            (R0, G0, B0) = (X, 0, C)
//        }
//        else if 300 <= H && H < 360 {
//            (R0, G0, B0) = (C, 0, X)
//        } else {
//            // invalid state
//            (R0, G0, B0) = (0, 0, 0)
//        }
//        return Pixel(r: UInt8((R0 + m) * 255), g: UInt8((G0 + m) * 255), b: UInt8((B0 + m) * 255))
//    }
    
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

struct Color: ExpressibleByArrayLiteral {
    
    var r: Double = 0
    var g: Double = 0
    var b: Double = 0
    var a: Double = 255
    
    init(r: Double = 0, g: Double = 0, b: Double = 0, a: Double = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    init(arrayLiteral arr: Double...) {
        r = arr[0]
        g = arr[1]
        b = arr[2]
        if arr.count == 4 {
            a = arr[3]
        }
    }
    
    func multRGB(_ f: Double) -> Color {
        Color(r: r * f,
              g: g * f,
              b: b * f)
    }
    
    func pixel() -> Pixel {
        Pixel(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255))
    }
    
    static var white: Color {
        [1, 1, 1, 1.0]
    }
    
    static var blue: Color {
        [0.4, 0.6, 0.8, 1.0]
    }
    
    static var red: Color {
        [0.8, 0.4, 0.6, 1.0]
    }
    
    static var green: Color {
        [0.6, 0.8, 0.4, 1.0]
    }
    
    static func + (c1: Color, c2: Color) -> Color {
        [c1.r + c2.r,
         c1.g + c2.g,
         c1.b + c2.b]
    }
}


struct Pixel {
    var r: UInt8 = 0
    var g: UInt8 = 0
    var b: UInt8 = 0
    var a: UInt8 = 255
    
    init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    init(white: Double) {
        self.init(r: UInt8(white * 255), g: UInt8(white * 255), b: UInt8(white * 255))
    }
}

struct Vector {
    var x: Double
    var y: Double
    var z: Double
}

extension Vector: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Double...) {
        x = elements[0]
        y = elements[1]
        z = elements[2]
    }
}

extension Vector {
    var isNaN: Bool {
        x.isNaN || y.isNaN || z.isNaN
    }
}

func len(_ v: Vector) -> Double {
    sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z))
}

func norm(_ v: Vector) -> Vector {
    v * (1.0/len(v))
}

func dot(_ v1: Vector, _ v2: Vector) -> Double {
      v1.x * v2.x
    + v1.y * v2.y
    + v1.z * v2.z
}

func cross(_ v1: Vector, _ v2: Vector) -> Vector {
    Vector(x: v1.y * v2.z - v1.z * v2.y,
           y: v1.z * v2.x - v1.x * v2.z,
           z: v1.x * v2.y - v1.y * v2.x)
}

func +(v1: Vector, v2: Vector) -> Vector {
    Vector(x: v1.x + v2.x,
           y: v1.y + v2.y,
           z: v1.z + v2.z)
}

func -(v1: Vector, v2: Vector) -> Vector {
    v1 + (v2 * (-1))
}

func *(v: Vector, s: Double) -> Vector {
    Vector(x: v.x * s,
           y: v.y * s,
           z: v.z * s)
}

func rotate(_ v: Vector, axis: Vector, rad: Double) -> Vector { // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    let term1 = v * cos(rad)
    let term2 = cross(v, axis) * sin(rad)
    let term3 = (axis * (dot(axis, v))) * (1 - cos(rad))
    return term1 + term2 + term3
}

// Problem with: v = [0, 1, 0], axis : Vector = [0, 0, 1], rad = Double.pi
func rotate2(_ v: Vector, axis: Vector, rad: Double) -> Vector { // https://www.nagwa.com/en/explainers/616184792816/
    let c = len(v) * len(axis) * sin(rad)
    let n = norm(cross(v, axis))
    let cross = n * c
    return cross
    
}

func testCross() {
    let v : Vector = [0, 1, 0]
    let a : Vector = [0, 0, 1]
    let rad = Double.pi
    let r1 = rotate(v, axis: a, rad: rad)
    let r2 = rotate2(v, axis: a, rad: rad)
    print(r1)
    print(r2)
    print()
}

struct Circle {
    let c: Vector
    let r: Double
    let mat: Material
}

struct Material {
    let colorRGB : Color
    let colorHSV : HSVColor
    let reflectivity = 0.0
    
    init(colorRGB: Color) {
        self.colorRGB = colorRGB
        self.colorHSV = [0, 0, 0]
    }
    
    init(colorHSV: HSVColor) {
        self.colorRGB = [0, 0, 0]
        self.colorHSV = colorHSV
    }
}
