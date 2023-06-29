import Foundation

class Camera {
    
    var origin  : Vector = [0, 0,  0]
    var right   : Vector = [1, 0,  0]
    var up      : Vector = [0, 1,  0]
    var forward : Vector = [0, 0, -1]
    
    let nearPlaneZDist : Double = 1.0
    
    func rotateLR(rad: Double) {
        right = norm(rotate(right, axis: up, rad: rad))
        forward = norm(rotate(forward, axis: up, rad: rad))
    }
    
    func rotateUD(rad: Double) {
        up = norm(rotate(up, axis: right, rad: rad))
        forward = norm(rotate(forward, axis: right, rad: rad))
    }
    
    func createViewerRay(x: Int, y: Int, W: Int, H: Int) -> Ray {
        // convert pixel coordinates to world coordinates (plane in the 3D space)
        let canvasX = (Double(x) / Double(W)) * 2 - 1
        let canvasY = ((Double(y) / Double(H)) * 2 - 1) * -1 // -1 so +1 is at the top
        let origin2 = origin // + (right * (0.0 * canvasX)) // todo: prevent fish eye effect
        let canvasCenter = origin2 + (forward * nearPlaneZDist)
        var canvasPoint = canvasCenter + right * canvasX
        canvasPoint = canvasPoint + up * canvasY
        
        let rayDir = norm(canvasPoint - origin2)
        return Ray(origin: canvasPoint, dir: rayDir)
    }
}

struct Ray {
    let origin: Vector
    let dir : Vector
}
