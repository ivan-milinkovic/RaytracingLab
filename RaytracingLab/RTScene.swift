import Foundation
import QuartzCore

let rtscene = RTScene()

class RTScene {
    
    var pixels : [Pixel]
    let w = 200
    let h = 200
    var update: (() -> Void)? = nil
    
    var circles: [Circle] = [
        Circle(c: [-3, 0, -5], r: 1),
        Circle(c: [ 0, 1, -5], r: 1),
        Circle(c: [ 2, 0, -5], r: 1)
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
                
                // iterate objects
                var colorValue : UInt8 = 0
                guard let (_, its) = closestIntersection(rayOrigin: rayOrigin, rayDir: rayDir)
                else {
                    pixels[y*w + x] = Pixel(r: colorValue, g: colorValue, b: colorValue)
                    continue
                }
                
                // bounce intersections towards light
                
                // calculate level of radiance
                let toLight = norm(light - its.point)
                let cos = abs(dot(its.normal, toLight))
                let ratio = cos
                colorValue = UInt8(255.0 * ratio)
                
                // store in pixel y*w + x
                pixels[y*w + x] = Pixel(a: colorValue, r: colorValue, g: colorValue, b: colorValue)
            }
        }
        
        let dt = CACurrentMediaTime() - start
        print("render time: \(dt*1000)ms")
        update?()
    }
    
    let viewer : Vector = [0, 0, 0]
    
    func createViewerRay(x: Int, y: Int) -> (rayOrigin: Vector, rayDir: Vector) {
        let rayOriginX = (Double(x)/Double(w))*2 - 1
        let rayOriginY = ((Double(y)/Double(h))*2 - 1) * -1 // * -1 because world and swiftui Y are oposite
//        let ratio = Double(h) / Double(w)
//        let rayOriginY = (((Double(y)/Double(h))*2 - 1) * -1) * ratio
        
        let rayOriginZ = Double(-1)
        let rayOrigin : Vector = [rayOriginX, rayOriginY, rayOriginZ]
        let rayDir = norm(rayOrigin - viewer)
        return (rayOrigin: rayOrigin, rayDir: rayDir)
    }
    
    func closestIntersection(rayOrigin: Vector, rayDir: Vector) -> (Circle, Intersection)? {
        var result : (c: Circle, i: Intersection)? = nil
        for c in circles {
            guard let i = intersection(rayOrigin: rayOrigin, rayDir: rayDir, circle: c)
            else { continue }
            
            if result == nil {
                result = (c, i)
                continue
            }
            if len(i.point - rayOrigin) < len(result!.i.point - rayOrigin) {
                result = (c, i)
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

struct Intersection {
    let point: Vector
    let normal: Vector
}

struct Pixel {
    var a: UInt8 = 255
    var r: UInt8 = 0
    var g: UInt8 = 0
    var b: UInt8 = 0
    
    init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    init(a: UInt8 = 255, r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0) {
        self.a = a
        self.r = r
        self.g = g
        self.b = b
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

struct Circle {
    let c: Vector
    let r: Double
}
