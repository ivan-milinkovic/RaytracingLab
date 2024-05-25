import Foundation
import QuartzCore

extension RTScene {
    
    func renderOneCore() {
        let start = CACurrentMediaTime()
        // renderIterative()
        renderRecursiveTile(x0: 0, y0: 0, tw: w, th: h)
        renderTime = CACurrentMediaTime() - start
        // dumpDebugPoints()
        // dumpDebugLines()
        update?()
    }
    
    func renderTasksBoxTiles() async {
        if isRendering { return }
        isRendering = true
        let start = CACurrentMediaTime()
        
        let width = w
        let height = h
        let tiles = 8
        let tw = width / tiles
        let th = height / tiles
        await withTaskGroup(of: Void.self) { group in
            for iy in 0..<tiles {
                for ix in 0..<tiles {
                    group.addTask {
                        let x = ix * tw
                        let y = iy * th
                        let tw2 = (x + tw > width) ? (x + tw - width) : tw
                        let th2 = (y + th > height) ? (y + th - height) : (th)
                        self.renderRecursiveTile(x0: x, y0: y, tw: tw2, th: th2)
                    }
                }
            }
        }
        
        renderTime = CACurrentMediaTime() - start
        await MainActor.run {
            self.update?()
            isRendering = false
        }
    }
    
    func renderTasksRowTiles() async {
        if isRendering { return }
        isRendering = true
        let start = CACurrentMediaTime()
        
        let width = w
        let height = h
        let tile_rows = 8
        let (tile_h, _) = height.quotientAndRemainder(dividingBy: tile_rows)
        
        await withTaskGroup(of: Void.self) { group in
            for row in 0..<tile_rows {
                group.addTask {
                    let x0 = 0 // row starting x
                    let y0 = row * tile_h // row starting y
                    var th2 = tile_h
                    if row == tile_rows - 1 {
                        th2 = width - y0 // take the remander of pixel rows, which can be either smaller or larger than tile height
                    }
                    self.renderRecursiveTile(x0: x0, y0: y0, tw: width, th: th2)
                }
            }
        }
        
        renderTime = CACurrentMediaTime() - start
        await MainActor.run {
            self.update?()
            isRendering = false
        }
    }
    
    func renderIterative() {
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
                    let toLightDir = norm(light - rayOrigin)
                    let lightf = max(0, dot(hit.its.normal, toLightDir))
                    let rgbColor = hit.c.multRGB(lightf)
                    colors.append(rgbColor)
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
