import Foundation

struct Vector {
    var x: Double
    var y: Double
    var z: Double
}

extension Vector: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Double...) {
        x = elements[0]
        y = elements[1]
        z = elements[2]
    }
}

extension Vector {
    var isNaN: Bool {
        x.isNaN || y.isNaN || z.isNaN
    }
}

func len(_ v: Vector) -> Double {
    sqrt((v.x * v.x) + (v.y * v.y) + (v.z * v.z))
}

func norm(_ v: Vector) -> Vector {
    v * (1.0/len(v))
}

func dot(_ v1: Vector, _ v2: Vector) -> Double {
      v1.x * v2.x
    + v1.y * v2.y
    + v1.z * v2.z
}

func cross(_ v1: Vector, _ v2: Vector) -> Vector {
    Vector(x: v1.y * v2.z - v1.z * v2.y,
           y: v1.z * v2.x - v1.x * v2.z,
           z: v1.x * v2.y - v1.y * v2.x)
}

//func testCross() {
//    let v : Vector = [0, 1, 0]
//    let a : Vector = [0, 0, 1]
//    let rad = Double.pi
//    let r1 = rotate(v, axis: a, rad: rad)
//    let r2 = rotate2(v, axis: a, rad: rad)
//    print(r1)
//    print(r2)
//    print()
//}

func +(v1: Vector, v2: Vector) -> Vector {
    Vector(x: v1.x + v2.x,
           y: v1.y + v2.y,
           z: v1.z + v2.z)
}

func -(v1: Vector, v2: Vector) -> Vector {
    v1 + (v2 * (-1))
}

func *(v: Vector, s: Double) -> Vector {
    Vector(x: v.x * s,
           y: v.y * s,
           z: v.z * s)
}

func rotate(_ v: Vector, axis: Vector, rad: Double) -> Vector { // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
    let term1 = v * cos(rad)
    let term2 = cross(v, axis) * sin(rad)
    let term3 = (axis * (dot(axis, v))) * (1 - cos(rad))
    return term1 + term2 + term3
}

// Problem with: v = [0, 1, 0], axis : Vector = [0, 0, 1], rad = Double.pi
func rotate2(_ v: Vector, axis: Vector, rad: Double) -> Vector { // https://www.nagwa.com/en/explainers/616184792816/
    let c = len(v) * len(axis) * sin(rad)
    let n = norm(cross(v, axis))
    let cross = n * c
    return cross
    
}
