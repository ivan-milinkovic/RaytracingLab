import Foundation

class Camera {
    
    var origin  : Vec3 = [0, 0,  0]
    var right   : Vec3 = [1, 0,  0]
    var up      : Vec3 = [0, 1,  0]
    var forward : Vec3 = [0, 0, -1]
    
    let nearPlaneZDist : Double = 1.0
    
    let RadsPerDeg = Double.pi / 180
    
    // Unlike rasterization, x is expanded, making the rays spread more,
    // and therefore miss objects (objects are hit by less rays, narrower rays).
    // That makes objects appear smaller, compressed over x axis,
    // which compensates the strech from the aspect ratio, and makes objects appear natural
    
    func createViewerRay(x: Int, y: Int, W: Int, H: Int) -> Ray {
        // convert pixel coordinates to world coordinates (plane in the 3D space)
        let aspect = Double(W)/Double(H)
        var canvasX = (Double(x) / Double(W)) * 2 - 1
        canvasX *= aspect
        let canvasY = ((Double(y) / Double(H)) * 2 - 1) * -1 // -1 so +1 is at the top
        let origin2 = origin // + (right * (0.0 * canvasX)) // reduce fish eye effect
        let canvasCenter = origin2 + (forward * nearPlaneZDist)
        var canvasPoint = canvasCenter + right * canvasX
        canvasPoint = canvasPoint + up * canvasY
        
        let rayDir = norm(canvasPoint - origin2)
        
        return Ray(origin: canvasPoint, dir: rayDir)
    }
    
    let radsInDeg = Float.pi / 180
    
    var lookAt : Vec3 = [0, 0, -5]
    
    // https://www.scratchapixel.com/lessons/mathematics-physics-for-computer-graphics/lookat-function/framing-lookat-function.html
    func rotateAroundLookAtPivot(_ dx: Double, _ dy: Double) {
        
        let limit = 1.0
        let dx2 = 0.75 * min(limit, max(dx, -limit))
        let dy2 = 0.75 * min(limit, max(-limit, dy))
        
        // input smoothing: convert input [-limit, limit] to [0,1], apply exponential function that preserves the sign, convert back to [-limit, limit]
        // dx2 = pow((dx2/limit), 3) * limit
        // dy2 = pow((dy2/limit), 3) * limit
        
        let lr_rads = dx2 * RadsPerDeg // left right
        let ud_rads = dy2 * RadsPerDeg // up down
        
        origin = origin - lookAt // tranform to lookAt space
        
        // let worldUp: Vec3 = [0, 1, 0]
        // let worldRight: Vec3 = [1, 0, 0]
        // origin = rotate(origin, axis: worldUp, rad: lr_rads)
        // origin = rotate(origin, axis: worldRight, rad: ud_rads)
        // origin = origin * mult(Mat3.rotationX(ud_rads), Mat3.rotationY(lr_rads))
        origin = origin * Mat3.rotation(x: ud_rads, y: lr_rads, z: 0)
        
        origin = origin + lookAt // transform back to world space
        
        updateOrientationVectors()
    }
    
    func updateOrientationVectors() {
        let worldUp: Vec3 = [0, 1, 0]
        forward = norm(lookAt - origin)
        right = cross(forward, worldUp)
        up = cross(right, forward)
    }
    
    func movePivot(_ dx: Double, _ dy: Double) {
        let limit = 1.0
        let dx2 = -0.1 * min(limit, max(dx, -limit))
        let dy2 = -0.1 * min(limit, max(-limit, dy))
        lookAt.x += dx2
        lookAt.z += dy2
        origin.x += dx2
        origin.z += dy2
        updateOrientationVectors()
    }
    
    func moveForward(ds: Double) {
        origin = origin + forward*ds
    }
    
    func moveRight(ds: Double) {
        origin = origin + right*ds
    }
    
    func moveUp(ds: Double) {
        origin = origin + up*ds
    }
    
    func rotateLR(deg: Double) {
        rotateLR(rad: deg * RadsPerDeg)
    }
    
    func rotateLR(rad: Double) {
        right = norm(rotate(right, axis: up, rad: rad))
        forward = norm(rotate(forward, axis: up, rad: rad))
    }
    
    func rotateUD(deg: Double) {
        rotateUD(rad: deg * RadsPerDeg)
    }
    
    func rotateUD(rad: Double) {
        up = norm(rotate(up, axis: right, rad: rad))
        forward = norm(rotate(forward, axis: right, rad: rad))
    }
}

/*
 struct CameraRayIterator {
     let w: Int
     let h: Int
     let viewerRayBuilder: (_ x: Int, _ y: Int) -> (rayOrigin: Vec3, rayDir: Vector)
     private var i = 0
     mutating func next() -> (rayOrigin: Vector, rayDir: Vector, x:Int, y: Int)? {
         defer { i += 1 }
         if i == w * h { return nil }
         let x = i % w
         let y = i / h + (x != 0 ? 1 : 0)
         let (rayOrigin, rayDir) = viewerRayBuilder(x, y)
         return (rayOrigin: rayOrigin, rayDir: rayDir, x: x, y: y)
     }
 }
 */
