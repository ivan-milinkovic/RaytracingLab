import Foundation
import QuartzCore

let rtscene = RTScene()

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
    let colorRGB : RGBColor
    let colorHSV : HSVColor
    let reflectivity = 0.0
    
    init(colorRGB: RGBColor) {
        self.colorRGB = colorRGB
        self.colorHSV = [1, 1, 1]
    }
    
    init(colorHSV: HSVColor) {
        self.colorRGB = [1, 1, 1]
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
    let light : Vector = [0, 5, 0]
    
    var debugPointsNormals = [Intersection]()
    var debugRays = [Ray]()
    
    var circles: [Circle] = [
//        Circle(c: [-3, 0, -5], r: 1, mat: Material(colorRGB: RGBColor.red)),
//        Circle(c: [ 0, 1, -5], r: 1, mat: Material(colorRGB: RGBColor.blue)),
//        Circle(c: [ 2, 0, -5], r: 1, mat: Material(colorRGB: RGBColor.green))
        
        Circle(c: [-3, 0, -5], r: 1, mat: Material(colorHSV: HSVColor.red)),
        Circle(c: [ 0, 1, -5], r: 1, mat: Material(colorHSV: HSVColor.blue)),
        Circle(c: [ 2, 0, -5], r: 1, mat: Material(colorHSV: HSVColor.green))
        
//        Circle(c: [ 0, 0, 0], r: 1, mat: Material(colorHSV: HSVColor.white)),
//        Circle(c: [ 1, 0, 0], r: 1, mat: Material(colorHSV: HSVColor.red)),
//        Circle(c: [ 0, 1, 0], r: 1, mat: Material(colorHSV: HSVColor.green)),
//        Circle(c: [ 0, 0,-1], r: 1, mat: Material(colorHSV: HSVColor.blue))
    ]
    
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
//        dumpDebug()
//        dumpDebugCenters()
        update?()
    }
    
    func dumpDebug() {
        var data = Data()
        for i in debugPointsNormals {
            let nworld = i.point + i.normal
            let pstr = "\(i.point.x),\(i.point.y),\(i.point.z);\(nworld.x),\(nworld.y),\(nworld.z)\n"
            data.append(pstr.data(using: .ascii)!)
        }
        
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let url = downloads.appending(path: "lines.txt", directoryHint: .notDirectory)
        try! data.write(to: url)
        print("dumped to:", url)
    }
    
    func dumpDebugCenters() {
        var data = Data()
        for c in circles {
            let pstr = "\(c.c.x),\(c.c.y),\(c.c.z)\n"
            data.append(pstr.data(using: .ascii)!)
        }
        
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let url = downloads.appending(path: "centers.txt", directoryHint: .notDirectory)
        try! data.write(to: url)
        print("dumped to:", url)
    }
    
//    func dumpDebug() {
//        var pdata = Data()
//        var ndata = Data()
//        for i in debug {
//            let pstr = "\(i.point.x),\(i.point.y),\(i.point.z)\n"
//            pdata.append(pstr.data(using: .ascii)!)
//
//            let nstr = "\(i.normal.x),\(i.normal.y),\(i.normal.z)\n"
//            ndata.append(nstr.data(using: .ascii)!)
//        }
//
//        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
//        let purl = downloads.appending(path: "points.txt", directoryHint: .notDirectory)
//        let nurl = downloads.appending(path: "normals.txt", directoryHint: .notDirectory)
//
//        try! pdata.write(to: purl)
//        try! ndata.write(to: nurl)
//    }
    
//    func dumpDebug() {
//        let pointsPath = "file://Users/ivan/labs/RaytracingLab/RaytracingLab/points.txt"
//        let normalsPath = "file://Users/ivan/labs/RaytracingLab/RaytracingLab/normals.txt"
//        let pointsFileHandle = FileHandle(forWritingAtPath: pointsPath)!
//        let normalsFileHandle = FileHandle(forWritingAtPath: normalsPath)!
//        defer {
//            try! pointsFileHandle.close()
//        }
//        try! pointsFileHandle.seekToEnd()
//
//        for i in debug {
//            let pstr = "\(i.point.x),\(i.point.y),\(i.point.z);\(i.normal.x),\(i.normal.y),\(i.normal.z)\n"
//            let pdata = str.data(using: .ascii)
//            try! pointsFileHandle.write(contentsOf: pdata)
//
//            let nstr = "\(i.point.x),\(i.point.y),\(i.point.z);\(i.normal.x),\(i.normal.y),\(i.normal.z)\n"
//            let ndata = str.data(using: .ascii)
//        }
//    }
    
    func renderRecursive() {
        for y in 0..<h {
            for x in 0..<w {
                let ray = camera.createViewerRay(x: x, y: y, W: w, H: h)
                if ray.origin.isNaN || ray.dir.isNaN { continue } // invalid state
                if x == 176 && y == 192 {
                    print()
                }
                let color = trace(rayOrigin: ray.origin, rayDir: ray.dir, iteration: 1)
                pixels[y*w + x] = color?.pixel() ?? Pixel()
            }
        }
    }
    
    private func trace(rayOrigin: Vector, rayDir: Vector, iteration: Int) -> HSVColor? {
        if iteration > numBounces { return nil }
        guard let hit = closestHit(rayOrigin: rayOrigin, rayDir: rayDir) else { return nil }
        debugPointsNormals.append(hit.its)
        
        let lightAmount = lightAmount(point: hit.its.point, normal: hit.its.normal, light: light)
        var selfColor : HSVColor = hit.c.mat.colorHSV
        selfColor.v *= lightAmount
        var color = selfColor
        
        // don't depend on camera direction only (a mirror), but sample a dome above
        let reflectedRayDir = rotate(rayDir, axis: hit.its.normal, rad: Double.pi)
        if let sceneColor = trace(rayOrigin: hit.its.point, rayDir: reflectedRayDir, iteration: iteration + 1),
           sceneColor.v != 0 {
            
//            color = HSVColor.avg(color, sceneColor)
            
            let fSelf = selfColor.v / (selfColor.v + sceneColor.v)
            let fScene = 1 - fSelf
            let h = (selfColor.h * fSelf) + (sceneColor.h * fScene)
            let s = (selfColor.s * fSelf) + (sceneColor.s * fScene)
            let v = max(selfColor.v, sceneColor.v)
            
            color = [h, s, v]
        }
        
        if color.h == .nan || color.s == .nan {
            print()
        }
        
        return color
    }
    
    func lightAmount(point: Vector, normal: Vector, light: Vector) -> Double {
        let toLight = norm(light - point)
        let cos = dot(normal, toLight)
        let amount = cos > 0 ? cos : 0.0
        return amount
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
        // need a drawing to understand this
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
    
    func renderIterative() {
        // define viewing frustum
        // projection plane x=[-1, 1], y=[-1, 1], z = -1
        
        for y in 0..<h {
            for x in 0..<w {
                
                var rayOrigin : Vector
                var rayDir : Vector
                var bounceResults = [Hit]()
                
                let ray = camera.createViewerRay(x: x, y: y, W: w, H: h)
                rayOrigin = ray.origin
                rayDir = ray.dir
                
                if rayOrigin.isNaN || rayDir.isNaN {
                    continue
                }
                
                for i in 0..<numBounces {
                    if i > 0 {
                        let prevIntersection = bounceResults[i-1].its
                        rayOrigin = prevIntersection.point
                        // don't depend on camera position only (a mirror), but in a dome above
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
    
}
