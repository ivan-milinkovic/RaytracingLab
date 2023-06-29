import Foundation
import QuartzCore

let rtscene = RTScene()

struct Circle {
    let c: Vector
    let r: Double
    let mat: Material
}

struct Material {
    let colorRGB : RGBColor
    let colorHSV : HSVColor
    let reflectivity = 0.0
    
    init(colorRGB: RGBColor) {
        self.colorRGB = colorRGB
        self.colorHSV = [0, 0, 0]
    }
    
    init(colorHSV: HSVColor) {
        self.colorRGB = [0, 0, 0]
        self.colorHSV = colorHSV
    }
}

struct Hit {
    let c: Circle
    let its: Intersection
}

struct Intersection {
    let point: Vector
    let normal: Vector
}


class RTScene {
    
    var pixels : [Pixel]
    let w = 400
    let h = 400
    let numBounces = 1
    var update: (() -> Void)? = nil
    var camera: Camera = Camera()
    
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
                
                var colors = [RGBColor]()
                for i in stride(from: bounceResults.count-1, through: 0, by: -1) {
                    let hit = bounceResults[i]
                    let lightAmount = lightAmount(point: hit.its.point, normal: hit.its.normal, light: light)
                    let color = hit.c.mat.colorRGB.multRGB(lightAmount)
                    colors.append(color)
                }
                
                var color : RGBColor = [0, 0, 0, 1]
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
            }
        }
    }
    
    private func trace(rayOrigin: Vector, rayDir: Vector, iteration: Int) -> HSVColor? {
        if iteration > numBounces { return nil }
        guard let hit = closestHit(rayOrigin: rayOrigin, rayDir: rayDir) else { return nil }
        
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
