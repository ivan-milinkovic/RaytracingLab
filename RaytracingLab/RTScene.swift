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
    let renderParallel = true
    private(set) var isRendering = false
    
    var debugPoints = [Vec3]()
    var debugLines = [(Vec3, Vec3)]()
    
    var renderTime: TimeInterval = -1
    
    var circles: [Circle] = [
        Circle(id:1, c: [ -2.5, 0, -5], r: 1, mat: Material(colorHSV: HSVColor.red)),
        Circle(id:2, c: [    0, 0, -5], r: 1, mat: Material(colorHSV: HSVColor.blue)),
        Circle(id:3, c: [  2.5, 0, -5], r: 1, mat: Material(colorHSV: HSVColor.green)),
        
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
        if renderParallel {
            renderInParallel()
        } else {
            renderOneCore()
        }
    }
    
    private func renderOneCore() {
        let start = CACurrentMediaTime()
        // renderIterative()
        renderRecursive()
        renderTime = CACurrentMediaTime() - start
        // dumpDebugPoints()
        // dumpDebugLines()
        update?()
    }
    
    private func renderInParallel() {
        if isRendering { return }
        isRendering = true
        let start = CACurrentMediaTime()
        Task {
            await renderRecursiveParallel()
            renderTime = CACurrentMediaTime() - start
            await MainActor.run {
                self.update?()
                isRendering = false
            }
        }
    }
    
    func renderRecursive() {
        renderRecursiveTile(x: 0, y: 0, w: w, h: h)
    }
    
    func renderRecursiveParallel() async {
        let width = w
        let height = h
        let xtiles = 10
        let ytiles = 10
        let tw = width / xtiles
        let th = height / ytiles
        await withTaskGroup(of: Void.self) { group in
            for iy in 0..<ytiles {
                for ix in 0..<xtiles {
                    group.addTask {
                        let x = ix * tw
                        let y = iy * th
                        var tw2 = tw
                        var th2 = th
                        if x + tw > width {
                            tw2 = x + tw - width
                        }
                        if y + th > height {
                            th2 = y + th - height
                        }
                        self.renderRecursiveTile(x: x, y: y, w: tw2, h: th2)
                    }
                }
            }
        }
    }
    
    private func renderRecursiveTile(x x0: Int, y y0: Int, w: Int, h: Int) {
        for y in y0..<(y0+h) {
            for x in x0..<(x0+w) {
                let ray = camera.createViewerRay(x: x, y: y, W: self.w, H: self.h)
                if ray.origin.isNaN || ray.dir.isNaN { continue } // invalid state
                let color = trace(rayOrigin: ray.origin, rayDir: ray.dir, iteration: 1)
                pixels_ptr[y*self.w + x] = color?.pixel() ?? Pixel()
            }
        }
    }
    
    private func trace(rayOrigin: Vec3, rayDir: Vec3, iteration: Int) -> HSVColor? {
        if iteration > numBounces { return nil }
        guard let hit = closestHit(rayOrigin: rayOrigin, rayDir: rayDir) else { return nil }
        
        let lightAmount = lightAmount(point: hit.its.point, normal: hit.its.normal, light: light)
        var selfColor : HSVColor = hit.c.hsvColor(at: hit.its.point)
        selfColor.v *= lightAmount
        var color = selfColor
        
        // todo: don't depend on camera direction only (a mirror), but sample a dome above
        let reflectedRayDir = rotate(rayDir, axis: hit.its.normal, rad: Double.pi) * -1 // -1: reflect back into the scene
        let sceneColorOpt = trace(rayOrigin: hit.its.point, rayDir: reflectedRayDir, iteration: iteration + 1)
        if let sceneColor = sceneColorOpt, sceneColor.v != 0 {
            let fSelf = 0.5 // selfColor.v / (selfColor.v + sceneColor.v)
            let fScene = 1 - fSelf
            let h = (selfColor.h * fSelf) + (sceneColor.h * fScene)
            let s = (selfColor.s * fSelf) + (sceneColor.s * fScene)
            let v = max(selfColor.v, sceneColor.v)
            color = [h, s, v]
        }
        
        return color
    }
    
    func lightAmount(point: Vec3, normal: Vec3, light: Vec3) -> Double {
        let toLight = norm(light - point)
        let cos = dot(normal, toLight)
        let amount = max(0, cos)
        return amount
    }
    
    func closestHit(rayOrigin: Vec3, rayDir: Vec3) -> Hit? {
        var result : Hit? = nil
        let cnt = circles.count
        var i = 0; while i<cnt { defer { i += 1 }
            let c = circles[i]
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
        
        if renderFloor, result == nil {
            if let intersectionPoint = ray_plane_intersection(plane: plane, rayOrigin: rayOrigin, rayDir: rayDir) {
                if len(intersectionPoint) < 10 {
                    result = Hit(c: plane, its: Intersection(point: intersectionPoint, normal: plane.n))
                }
            }
        }
        
        return result
    }
    
    func intersection(rayOrigin: Vec3, rayDir: Vec3, circle: Circle) -> Intersection? {
        // need a drawing to understand
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
        let intersection = rayOrigin + rayDir * offset
        let normal = norm(intersection - circle.c)
        return Intersection(point: intersection, normal: normal)
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
    
    func renderIterative() {
        // define viewing frustum
        // projection plane x=[-1, 1], y=[-1, 1], z = -1
        
        for y in 0..<h {
            for x in 0..<w {
                
                var rayOrigin : Vec3
                var rayDir : Vec3
                var bounceResults = [Hit]()
                
                let ray = camera.createViewerRay(x: x, y: y, W: w, H: h)
                rayOrigin = ray.origin
                rayDir = ray.dir
                
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
                    let color = hit.c.rgbColor(at: hit.its.point).multRGB(lightAmount)
                    colors.append(color)
                }
                
                var color : RGBColor = [0, 0, 0, 1]
                if colors.count > 0 {
                    color = colors[0]
                    var i = 1; while i < colors.count-1 { defer { i += 1 }
                        color = color.multRGB(0.8) + colors[i].multRGB(0.2)
                    }
                }
                
                pixels_ptr[y*w + x] = color.pixel()
            }
        }
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
