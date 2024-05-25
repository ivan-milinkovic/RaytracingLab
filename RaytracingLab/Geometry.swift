import Foundation

struct Ray {
    let origin: Vec3
    let dir : Vec3
}

struct Circle {
    let id: Int
    let c: Vec3
    let r: Double
    let mat: Material
    
    func rgbColor(at point: Vec3) -> RGBColor {
        mat.rgb
    }
}

struct Plane {
    let p: Vec3
    let n: Vec3
    let d: Double
    
    init(p: Vec3, n: Vec3) {
        self.p = p
        self.n = n
        self.d = dot(p, n)
    }
}

struct Hit {
    let c: RGBColor
    let its: Intersection
}

struct Intersection {
    let point: Vec3
    let normal: Vec3
}

func ray_circle_intersection(rayOrigin: Vec3, rayDir: Vec3, circle: Circle) -> Intersection? {
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

func ray_plane_intersection(plane: Plane, rayOrigin: Vec3, rayDir: Vec3) -> Vec3? {
    let denom = dot(rayDir, plane.n)
    if denom < 0 {
        let t = (plane.d - dot(rayOrigin, plane.n)) / denom
        let intersectionPoint = rayOrigin + (rayDir * t)
        return intersectionPoint
    }
    return nil
}

extension Plane {
    
    func rgbColor(at point: Vec3) -> RGBColor {
        checkerboard_pick_flag(at: point)
            ? RGBColor.white
            : RGBColor.black
    }
    
    private func checkerboard_pick_flag(at point: Vec3) -> Bool {
        // checkerboard pattern
        // the sign check because checkerboard repeats around 0
        // and the boxes are the same around 0 and combine to a rectangle (streched)
        
        // assume this is the xz plain, no transformation to local plane space
        
        let q = 2.0 // quantization value
        let x_offset = (point.x < 0 ? -q : 0)
        let z_offset = (point.z < 0 ? -q : 0)
        let x2 = point.x + x_offset
        let z2 = point.z + z_offset
        let qx = Int(x2 / q)
        let qz = Int(z2 / q)
        
        let xtest = qx % 2 == 0
        let ztest = qz % 2 == 0
        
        switch (xtest, ztest) {
        case (true, true), (false, false): return true
        case (true, false), (false, true): return false
        }
    }
}
