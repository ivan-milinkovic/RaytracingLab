import Foundation
import QuartzCore

let rtscene = RTScene()

class RTScene {
    
    var pixels : [Pixel]
    let w = 400
    let h = 400
    var update: (() -> Void)? = nil
    
    var circles: [Circle] = [
        Circle(c: [-2, 0, -5], r: 1, mat: Material(color: Color.red)),
        Circle(c: [ 0, 1, -5], r: 1, mat: Material(color: Color.blue)),
        Circle(c: [ 2, 0, -5], r: 1, mat: Material(color: Color.green))
    ]
    
    let light : Vector = [0, 3, 0]
    
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
//        render1()
        render2()
    }
    
    func render1() {
        let start = CACurrentMediaTime()
        // define viewing frustum
        // projection plane x=[-1, 1], y=[-1, 1], z = -1
        
        for y in 0..<h {
            for x in 0..<w {
                // create ray
                let (rayOrigin, rayDir) = createViewerRay(x: x, y: y)
                if rayOrigin.isNaN || rayDir.isNaN {
                    continue
                }
                
                // initial hit test
                guard let hit = closestIntersection(rayOrigin: rayOrigin, rayDir: rayDir)
                else {
                    pixels[y*w + x] = Pixel(r: 0, g: 0, b: 0)
                    continue
                }
                
                // Scene light contribution
                let toLight = norm(light - hit.its.point)
                let cos = abs(dot(hit.its.normal, toLight))
                let ratio = cos
                let color = hit.c.mat.color.multRGB(ratio)

                // store the pixel
                pixels[y*w + x] = color.pixel()
            }
        }
        
        let dt = CACurrentMediaTime() - start
        print("render time: \(Int(dt*1000))ms")
        update?()
    }
    
    
    func render2() {
        let start = CACurrentMediaTime()
        // define viewing frustum
        // projection plane x=[-1, 1], y=[-1, 1], z = -1
        
        let numBounces = 2 // self + 1 bounce
        
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
                        let prevIts = bounceResults[i-1].its
                        rayOrigin = prevIts.point
                        rayDir = rot(rayDir, axis: prevIts.normal, rad: Double.pi)
                    }
                    guard let h = closestIntersection(rayOrigin: rayOrigin, rayDir: rayDir) else { break }
                    bounceResults.append(h)
                }
                
                var colors = [Color]()
                for i in stride(from: bounceResults.count-1, to: 0, by: -1) {
                    let hit = bounceResults[i]
                    let toLight = norm(light - hit.its.point)
                    let cos = abs(dot(hit.its.normal, toLight))
                    let ratio = cos
                    let color = hit.c.mat.color.multRGB(ratio)
                    colors.append(color)
                }
                
                var color : Color
                if colors.count == 0 {
                    color = [0, 0, 0, 1]
                }
                else if colors.count == 1 {
                    color = colors[0]
                }
                else {
                    color = colors[0]
                    for i in 1..<colors.count {
                        color = color.multRGB(0.8) + colors[i+1].multRGB(0.2)
                    }
                }
                pixels[y*w + x] = color.pixel()
            }
        }
        
        let dt = CACurrentMediaTime() - start
        print("render time: \(Int(dt*1000))ms")
        update?()
    }
    
    
    func createViewerRay(x: Int, y: Int) -> (rayOrigin: Vector, rayDir: Vector) {
        let viewer : Vector = [0, 0, 0]
        let rayOriginX = (Double(x)/Double(w))*2 - 1
        let rayOriginY = ((Double(y)/Double(h))*2 - 1) * -1 // * -1 because world and swiftui Y are oposite
//        let ratio = Double(h) / Double(w)
//        let rayOriginY = (((Double(y)/Double(h))*2 - 1) * -1) * ratio
        
        let rayOriginZ = Double(-1)
        let rayOrigin : Vector = [rayOriginX, rayOriginY, rayOriginZ]
        let rayDir = norm(rayOrigin - viewer)
        return (rayOrigin: rayOrigin, rayDir: rayDir)
    }
    
    func closestIntersection(rayOrigin: Vector, rayDir: Vector) -> Hit? {
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

struct Color {
    var r: Double = 0
    var g: Double = 0
    var b: Double = 0
    var a: Double = 255
    
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
        [0, 0.1, 0.8, 1.0]
    }
    
    static var red: Color {
        [0.8, 0.0, 0.1, 1.0]
    }
    
    static var green: Color {
        [0.1, 0.8, 0.0, 1.0]
    }
}

extension Color: ExpressibleByArrayLiteral {
    init(arrayLiteral arr: Double...) {
        r = arr[0]
        g = arr[1]
        b = arr[2]
        if arr.count == 4 {
            a = arr[3]
        }
    }
}

func +(c1: Color, c2: Color) -> Color {
    [c1.r + c2.r,
     c1.g + c2.g,
     c1.b + c2.b]
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

func rot(_ v: Vector, axis: Vector, rad: Double) -> Vector { // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    let term1 = v * cos(rad)
    let term2 = cross(v, axis) * sin(rad)
    let term3 = (axis * (dot(axis, v))) * (1 - cos(rad))
    return term1 + term2 + term3
}

// Problem with: v = [0, 1, 0], axis : Vector = [0, 0, 1], rad = Double.pi
func rot2(_ v: Vector, axis: Vector, rad: Double) -> Vector { // https://www.nagwa.com/en/explainers/616184792816/
    let c = len(v) * len(axis) * sin(rad)
    let n = norm(cross(v, axis))
    let cross = n * c
    return cross
    
}

func testCross() {
    let v : Vector = [0, 1, 0]
    let a : Vector = [0, 0, 1]
    let rad = Double.pi
    let r1 = rot(v, axis: a, rad: rad)
    let r2 = rot2(v, axis: a, rad: rad)
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
    let color : Color
    let reflectivity = 0.0
}
