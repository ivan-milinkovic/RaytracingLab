//
//  Mat3.swift
//  RaytracingLab
//
//  Created by Ivan Milinkovic on 22.5.24..
//

import Foundation

struct Mat3 {
    let m11, m12, m13,
        m21, m22, m23,
        m31, m32, m33
        : Double
    
    static var identity: Mat3 {
        Mat3(m11: 1, m12: 0, m13: 0,
             m21: 0, m22: 1, m23: 0,
             m31: 0, m32: 0, m33: 1)
    }
    
    /// In radians
    static func rotation(x: Double, y: Double, z: Double) -> Mat3 { // https://en.wikipedia.org/wiki/Rotation_matrix#General_3D_rotations
        Mat3(m11: cos(y)*cos(z),    m12: sin(x)*sin(y)*cos(z) - cos(x)*sin(z),    m13: cos(x)*sin(y)*cos(z)+sin(x)*sin(z),
             m21: cos(y)*sin(z),    m22: sin(x)*sin(y)*sin(z) + cos(x)*cos(z),    m23: cos(x)*sin(y)*sin(z)-sin(x)*cos(z),
             m31:       -sin(y),    m32:                        sin(x)*cos(y),    m33:                      cos(x)*cos(y))
    }
    
    static func rotationX(_ ax: Double) -> Mat3 {
        Mat3(m11: 1, m12:        0, m13:        0,
             m21: 0, m22:  cos(ax), m23: -sin(ax),
             m31: 0, m32:  sin(ax), m33:  cos(ax))
    }
    
    static func rotationY(_ ay: Double) -> Mat3 {
        Mat3(m11: cos(ay),  m12: 0, m13: sin(ay),
             m21:       0,  m22: 1, m23:       0,
             m31: -sin(ay), m32: 0, m33: cos(ay))
    }
    
    static func rotationZ(_ az: Double) -> Mat3 {
        Mat3(m11:  cos(az), m12: -sin(az), m13: 0,
             m21:  sin(az), m22:  cos(az), m23: 0,
             m31:        0, m32:        0, m33: 1)
    }
}

func *(v: Vec3, mat: Mat3) -> Vec3 {
    let x = v.x * mat.m11  +  v.y * mat.m21  +  v.z * mat.m31
    let y = v.x * mat.m12  +  v.y * mat.m22  +  v.z * mat.m32
    let z = v.x * mat.m13  +  v.y * mat.m23  +  v.z * mat.m33
    return Vec3(x, y, z)
}

func mult(_ m1: Mat3, _ m2: Mat3) -> Mat3 {
    
    let m11 = m1.m11 * m2.m11  +  m1.m12 * m2.m21  +  m1.m13 * m2.m31
    let m12 = m1.m11 * m2.m12  +  m1.m12 * m2.m22  +  m1.m13 * m2.m32
    let m13 = m1.m11 * m2.m13  +  m1.m12 * m2.m23  +  m1.m13 * m2.m33
    
    let m21 = m1.m21 * m2.m11  +  m1.m22 * m2.m21  +  m1.m23 * m2.m31
    let m22 = m1.m21 * m2.m12  +  m1.m22 * m2.m22  +  m1.m23 * m2.m32
    let m23 = m1.m21 * m2.m13  +  m1.m22 * m2.m23  +  m1.m23 * m2.m33
    
    let m31 = m1.m31 * m2.m11  +  m1.m32 * m2.m21  +  m1.m33 * m2.m31
    let m32 = m1.m31 * m2.m12  +  m1.m32 * m2.m22  +  m1.m33 * m2.m32
    let m33 = m1.m31 * m2.m13  +  m1.m32 * m2.m23  +  m1.m33 * m2.m33
    
    return Mat3(m11: m11, m12: m12, m13: m13,
                m21: m21, m22: m22, m23: m23,
                m31: m31, m32: m32, m33: m33)
}

func *(m1: Mat3, m2: Mat3) -> Mat3 {
    mult(m1, m2)
}
