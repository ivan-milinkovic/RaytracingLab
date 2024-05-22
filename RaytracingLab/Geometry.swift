
struct Circle {
    let id: Int
    let c: Vec3
    let r: Double
    let mat: Material
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

func ray_plane_intersection(plane: Plane, rayOrigin: Vec3, rayDir: Vec3) -> Vec3? {
    let denom = dot(rayDir, plane.n)
    if denom < 0 {
        let t = (plane.d - dot(rayOrigin, plane.n)) / denom
        let intersectionPoint = rayOrigin + (rayDir * t)
        return intersectionPoint
    }
    return nil
}

protocol Colored {
    func hsvColor(at point: Vec3) -> HSVColor
    func rgbColor(at point: Vec3) -> RGBColor
}

extension Circle: Colored {
    func hsvColor(at point: Vec3) -> HSVColor {
        mat.colorHSV
    }
    
    func rgbColor(at point: Vec3) -> RGBColor {
        mat.colorRGB
    }
}

private let q = 0.8

extension Plane: Colored {
    func hsvColor(at p: Vec3) -> HSVColor {
        // checkerboard pattern
        let qx = Int(p.x / q)
        let qz = Int(p.z / q)
        
        let c1 = HSVColor(h: 0.5, s: 0, v: 1)
        let c2 = HSVColor(h: 0, s: 0, v: 0)
        
        let xtest = qx % 2 == 0
        let ztest = qz % 2 == 0
        
        let col = switch (xtest, ztest) {
        case (true, true), (false, false): c1
        case (true, false), (false, true): c2
        }
        
        return col
    }
    
    func rgbColor(at point: Vec3) -> RGBColor {
        RGBColor(r: 0.5, g: 0.3, b: 0.3)
    }
}
