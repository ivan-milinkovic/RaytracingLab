import Foundation
import QuartzCore

// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
// https://github.com/scratchapixel/code/blob/main/minimal-ray-tracer-rendering-simple-shapes/simpleshapes.cpp


let rtscene = RTScene()

class RTScene {
    
    var pixels_ptr : UnsafeMutablePointer<Pixel>
    let w = 600
    let h = 400
    var numBounces = 5
    var update: (() -> Void)? = nil
    var camera: Camera = Camera()
    let light : Vec3 = [0, 4, 0]
    
    private enum RenderMethod {
        case singleCore
        case parallelGCD
        case parallelTasks
    }
    private let renderMethod = RenderMethod.parallelGCD
    let renderFloor = true
    var isRendering = false
    
    var debugPoints = [Vec3]()
    var debugLines = [(Vec3, Vec3)]()
    
    var renderTime: TimeInterval = -1
    
    var debugPoint: (Int, Int)?
    
    var spheres: [Sphere] = [
        Sphere(id:1, c: [ -2.5, 0, -5], r: 1, mat: Material(rgb: RGBColor.red)),
        Sphere(id:2, c: [    0, 0, -5], r: 1, mat: Material(rgb: RGBColor.blue)),
        Sphere(id:3, c: [  2.5, 0, -5], r: 1, mat: Material(rgb: RGBColor.green)),
        
        // Circle(id:4, c: [ 1.5, 2, -6], r: 1, mat: Material(rgb: RGBColor.red)),
        // Circle(id:5, c: [  -2, 2, -6], r: 1, mat: Material(rgb: RGBColor.yellow))
    ]
    
//    var spheres: [Circle] = { // Grid of spheres
//        let cols: [RGBColor] = [.red, .blue, .green, .yellow]
//        var i_cols = 0
//        let stride = stride(from: -10.0, through: 10.0, by: 4.0)
//        return stride.flatMap { x in
//            stride.map { z in
//                let c = Circle(id: 0, c: Vec3(x, 0, z-5), r: 1, mat: Material(rgb: cols[i_cols]))
//                i_cols = (i_cols + 1) % cols.count
//                return c
//            }
//        }
//    }()
    
    let floor = Plane(p: Vec3(x: 0, y: -1, z: 0), n: Vec3(x: 0, y: 1, z: 0))
    
    init() {
        pixels_ptr = UnsafeMutablePointer<Pixel>.allocate(capacity: w*h)
    }
    
    func render() {
        switch renderMethod {
        case .parallelGCD: renderGCD()
        case .singleCore: renderOneCore()
        case .parallelTasks:
            Task { await renderTasksBoxTiles() }
            // Task { await renderTasksRowTiles() }
        }
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
                let isDebug = (x == debugPoint?.0 && y == debugPoint?.1)
                let color = trace(rayOrigin: ray.origin, rayDir: ray.dir, iteration: 0, isDebug: isDebug)
                pixels_ptr[y*w + x] = color?.pixel() ?? Pixel()
            }
        }
    }
    
    private func trace(rayOrigin: Vec3, rayDir: Vec3, iteration: Int, isDebug: Bool = false) -> RGBColor? {
        if iteration >= numBounces { return nil }
        
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
            color = add(c1: color, w1: 1 - reflectivity, c2: scene_color, w2: reflectivity)
        }
        
        return color
    }
    
    func closestHit(rayOrigin: Vec3, rayDir: Vec3) -> Hit? {
        var result : Hit? = nil
        let cnt = spheres.count
        var i = 0; while i<cnt { defer { i += 1 }
            let c = spheres[i]
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
            if let intersectionPoint = ray_plane_intersection(plane: floor, rayOrigin: rayOrigin, rayDir: rayDir) {
                if len(intersectionPoint) < 20 {
                    result = Hit(c: floor.rgbColor(at: intersectionPoint), its: Intersection(point: intersectionPoint, normal: floor.n))
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
}
