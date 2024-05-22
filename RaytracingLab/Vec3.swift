import Foundation

struct Vec3 {
    var x: Double
    var y: Double
    var z: Double
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Vec3: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Double...) {
        x = elements[0]
        y = elements[1]
        z = elements[2]
    }
}

extension Vec3 {
    var isNaN: Bool {
        x.isNaN || y.isNaN || z.isNaN
    }
}

func len(_ v: Vec3) -> Double {
    sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z))
}

func norm(_ v: Vec3) -> Vec3 {
    v * (1.0/len(v))
}

func dot(_ v1: Vec3, _ v2: Vec3) -> Double {
      v1.x * v2.x
    + v1.y * v2.y
    + v1.z * v2.z
}

func cross(_ v1: Vec3, _ v2: Vec3) -> Vec3 {
    Vec3(x: v1.y * v2.z - v1.z * v2.y,
           y: v1.z * v2.x - v1.x * v2.z,
           z: v1.x * v2.y - v1.y * v2.x)
}

//func testCross() {
//    let v : Vec3 = [0, 1, 0]
//    let a : Vec3 = [0, 0, 1]
//    let rad = Double.pi
//    let r1 = rotate(v, axis: a, rad: rad)
//    let r2 = rotate2(v, axis: a, rad: rad)
//    print(r1)
//    print(r2)
//    print()
//}

func +(v1: Vec3, v2: Vec3) -> Vec3 {
    Vec3(x: v1.x + v2.x,
           y: v1.y + v2.y,
           z: v1.z + v2.z)
}

func -(v1: Vec3, v2: Vec3) -> Vec3 {
    v1 + (v2 * (-1))
}

func *(v: Vec3, s: Double) -> Vec3 {
    Vec3(x: v.x * s,
           y: v.y * s,
           z: v.z * s)
}

func rotate(_ v: Vec3, axis: Vec3, rad: Double) -> Vec3 { // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    let term1 = v * cos(rad)
    let term2 = cross(axis, v) * sin(rad)
    let term3 = (axis * (dot(axis, v))) * (1 - cos(rad))
    return term1 + term2 + term3
}
