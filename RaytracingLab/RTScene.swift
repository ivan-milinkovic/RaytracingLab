import Foundation
import QuartzCore

// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
// https://github.com/scratchapixel/code/blob/main/minimal-ray-tracer-rendering-simple-shapes/simpleshapes.cpp


let rtscene = RTScene()

class RTScene {
    
    var pixels_ptr : UnsafeMutablePointer<Pixel>
    let w = 600
    let h = 400
    var numBounces = 3
    var update: (() -> Void)? = nil
    var camera: Camera = Camera()
    let light : Vec3 = [0, 4, 0]
    
    
    let renderFloor = true
    private enum RenderMethod {
        case singleCore
        case parallelGCD
        case parallelTasks
    }
    private let renderMathod = RenderMethod.parallelGCD
    var isRendering = false
    
    var debugPoints = [Vec3]()
    var debugLines = [(Vec3, Vec3)]()
    
    var renderTime: TimeInterval = -1
    
    var circles: [Circle] = [
        Circle(id:1, c: [ -2.5, 0, -5], r: 1, mat: Material(rgb: RGBColor.red)),
        Circle(id:2, c: [    0, 0, -5], r: 1, mat: Material(rgb: RGBColor.blue)),
        Circle(id:3, c: [  2.5, 0, -5], r: 1, mat: Material(rgb: RGBColor.green)),
        
        // Circle(id:4, c: [ 1.5, 2, -6], r: 1, mat: Material(colorHSV: HSVColor.red)),
        // Circle(id:5, c: [  -2, 2, -6], r: 1, mat: Material(colorHSV: HSVColor.yellow))
        
    ]
    
    let plane: Plane
    
    init() {
        pixels_ptr = UnsafeMutablePointer<Pixel>.allocate(capacity: w*h)
        
        let n = Vec3(x: 0, y: 1, z: 0)
        // let n = rotate(Vec3(x: 0, y: 1, z: 0), axis: Vec3(x: 0, y: 0, z: -1), rad: 10*Double.pi/180)
        plane = Plane(p: Vec3(x: 0, y: -1, z: 0), n: n)
        
        // camera.moveForward(ds: -1)
        // camera.moveUp(ds: 4)
    }
    
    func mark(point: CGPoint) {
        let x = Int(point.x)
        let y = Int(point.y)
        guard (0..<w).contains(x), (0..<h).contains(y)
        else { return }
        var px = pixels_ptr[y*w + x]
        px.r = 255
        px.g = 255
        px.b = 255
        pixels_ptr[y*w + x] = px
        update?()
    }
    
    func render() {
        switch renderMathod {
        case .parallelGCD: renderGCD()
        case .singleCore: renderOneCore()
        case .parallelTasks:
            Task { await renderTasksBoxTiles() }
            // Task { await renderTasksRowTiles() }
        }
    }
    
    private func renderOneCore() {
        let start = CACurrentMediaTime()
        // renderIterative()
        renderRecursiveTile(x0: 0, y0: 0, tw: w, th: h)
        renderTime = CACurrentMediaTime() - start
        // dumpDebugPoints()
        // dumpDebugLines()
        update?()
    }
    
    func renderGCD() {
        if isRendering { return }
        isRendering = true
        let start = CACurrentMediaTime()
        
        let width = w
        let height = h
        let tiles = 8
        let tw = width / tiles
        let th = height / tiles
        
        // blocking call
        DispatchQueue.concurrentPerform(iterations: tiles*tiles) { i in
            let (iy, ix) = i.quotientAndRemainder(dividingBy: tiles)
            let x = ix * tw
            let y = iy * th
            let tw2 = (x + tw > width) ? (x + tw - width) : tw
            let th2 = (y + th > height) ? (y + th - height) : (th)
            self.renderRecursiveTile(x0: x, y0: y, tw: tw2, th: th2)
        }
        
        renderTime = CACurrentMediaTime() - start
        update?()
        isRendering = false
    }
    
    func renderRecursiveTile(x0: Int, y0: Int, tw: Int, th: Int) {
        for y in y0..<(y0+th) {
            for x in x0..<(x0+tw) {
                let ray = camera.createViewerRay(x: x, y: y, W: w, H: h)
                if ray.origin.isNaN || ray.dir.isNaN { continue } // invalid state
                let color = trace(rayOrigin: ray.origin, rayDir: ray.dir, iteration: 1)
                pixels_ptr[y*w + x] = color?.pixel() ?? Pixel()
            }
        }
    }
    
    private func trace(rayOrigin: Vec3, rayDir: Vec3, iteration: Int) -> RGBColor? {
        
        if iteration > numBounces { return nil }
        
        guard let hit = closestHit(rayOrigin: rayOrigin, rayDir: rayDir) else {
            return nil
        }
        
        let reflectedRayDir = rayDir - (hit.its.normal * dot(rayDir, hit.its.normal) * 2)
        
        let self_color = hit.c
        let scene_color = trace(rayOrigin: hit.its.point, rayDir: reflectedRayDir, iteration: iteration + 1)
        let light_color = RGBColor.white
        var light_diffuse_f = 0.0
        var light_spec_f = 0.0
        let reflectivity = 0.5
        
        // check if light is visible
        let hitToLightDir = norm(light - hit.its.point)
        if closestHit(rayOrigin: hit.its.point, rayDir: hitToLightDir) == nil {
            light_diffuse_f = max(0, dot(hit.its.normal, hitToLightDir))
            light_spec_f = max(0, dot(reflectedRayDir, hitToLightDir))
        }
        
        var color = self_color * light_diffuse_f
        if light_spec_f > 0.99 {
            color = color + (light_color * light_spec_f)
        }
        if let scene_color {
            color = add(c1: self_color, w1: 1 - reflectivity, c2: scene_color, w2: reflectivity)
        }
        
        return color
    }
    
    func closestHit(rayOrigin: Vec3, rayDir: Vec3) -> Hit? {
        var result : Hit? = nil
        let cnt = circles.count
        var i = 0; while i<cnt { defer { i += 1 }
            let c = circles[i]
            guard let i = ray_circle_intersection(rayOrigin: rayOrigin, rayDir: rayDir, circle: c)
            else { continue }
            
            if result == nil {
                result = Hit(c: c.rgbColor(at: i.point), its: i)
                continue
            }
            if len(i.point - rayOrigin) < len(result!.its.point - rayOrigin) {
                result = Hit(c: c.rgbColor(at: i.point), its: i)
            }
        }
        
        if renderFloor, result == nil {
            if let intersectionPoint = ray_plane_intersection(plane: plane, rayOrigin: rayOrigin, rayDir: rayDir) {
                if len(intersectionPoint) < 20 {
                    result = Hit(c: plane.rgbColor(at: intersectionPoint), its: Intersection(point: intersectionPoint, normal: plane.n))
                }
            }
        }
        
        return result
    }
    
    // Random is slow, so compute in advance
    let randoms = [Double.random(in: 0..<10)/1000.0,
                   Double.random(in: 0..<10)/1000.0,
                   Double.random(in: 0..<10)/1000.0,
                   Double.random(in: 0..<10)/1000.0,
                   Double.random(in: 0..<10)/1000.0]
    let randoms_cnt = 5
    var irandoms = 0 // not thread safe
    
    func nextRandom() -> Double {
        irandoms = (irandoms + 1) % randoms_cnt
        return randoms[irandoms]
    }
    
    func movePivot(_ dx: Double, _ dy: Double) {
        if rtscene.isRendering { return }
        camera.movePivot(dx, dy)
    }
    
    func moveForward(ds: Double) {
        if rtscene.isRendering { return }
        camera.moveForward(ds: ds)
    }
    
    func rotateAroundLookAtPivot(_ dx: Double, _ dy: Double) {
        if rtscene.isRendering { return }
        camera.rotateAroundLookAtPivot(dx, dy)
    }
    
    func dumpDebugPoints() {
        var data = Data()
        for p in debugPoints {
            let pstr = "\(p.x),\(p.y),\(p.z)\n"
            data.append(pstr.data(using: .ascii)!)
        }
        
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let url = downloads.appending(path: "points.txt", directoryHint: .notDirectory)
        try! data.write(to: url)
        print("dumped to:", url)
    }
    
    func dumpDebugLines() {
        var data = Data()
        for i in debugLines {
            let str = "\(i.0.x),\(i.0.y),\(i.0.z);\(i.1.x),\(i.1.y),\(i.1.z)\n"
            data.append(str.data(using: .ascii)!)
        }
        
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let url = downloads.appending(path: "lines.txt", directoryHint: .notDirectory)
        try! data.write(to: url)
        print("dumped to:", url)
    }
}
