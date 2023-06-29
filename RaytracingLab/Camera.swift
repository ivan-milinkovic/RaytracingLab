import Foundation

class Camera {
    
    var origin : Vector = [0, 0, 0]
    var right  : Vector = [1, 0, 0]
    var up     : Vector = [0, 1, 0]
    
    let nearPlaneZ = 1
    
    func rotateLR() {
        
    }
    
    func createViewerRay(x: Int, y: Int, W: Int, H: Int) -> Ray {
        let eye : Vector = [0, 0, 0]
        // convert pixel coordinates to world coordinates (plane in the 3D space)
        let canvasX = (Double(x)/Double(W))*2 - 1
        let canvasY = ((Double(y)/Double(H))*2 - 1) * -1 // * -1 to flip for UI
//        let ratio = Double(h) / Double(w)
//        let dy = (((Double(y)/Double(h))*2 - 1) * -1) * ratio
        let nearPlaneZ = Double(-1)
        let pixelWorldPosition : Vector = [canvasX, canvasY, nearPlaneZ]
        
        let viewerRight : Vector = [1, 0, 0]
        let viewerAdjusted = eye + (viewerRight * (0.0 * canvasX)) // todo: prevent fish eye effect
        let rayDir = norm(pixelWorldPosition - viewerAdjusted)
        
        return Ray(origin: pixelWorldPosition, dir: rayDir)
    }
}

struct Ray {
    let origin: Vector
    let dir : Vector
}
