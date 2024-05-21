
struct Circle {
    let id: Int
    let c: Vector
    let r: Double
    let mat: Material
}

struct Plane {
    let p: Vector
    let n: Vector
    let d: Double
    
    init(p: Vector, n: Vector) {
        self.p = p
        self.n = n
        self.d = dot(p, n)
    }
}

protocol Colored {
    func hsvColor(at point: Vector) -> HSVColor
    func rgbColor(at point: Vector) -> RGBColor
}

extension Circle: Colored {
    func hsvColor(at point: Vector) -> HSVColor {
        mat.colorHSV
    }
    
    func rgbColor(at point: Vector) -> RGBColor {
        mat.colorRGB
    }
}

private let q = 2.0

extension Plane: Colored {
    func hsvColor(at p: Vector) -> HSVColor {
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
    
    func rgbColor(at point: Vector) -> RGBColor {
        RGBColor(r: 0.5, g: 0.3, b: 0.3)
    }
}
