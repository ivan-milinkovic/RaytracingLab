import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var vm = ViewModel()
    @State var numBounces = 1
    
    var body: some View {
        VStack {
            Image(cgimage(), scale: 1.0, label: Text(""))
                .resizable(resizingMode: .stretch)
                .aspectRatio(contentMode: .fit)
                // .gesture(dragGesture)
                // .frame(width: CGFloat(rtscene.w), height: CGFloat(rtscene.h))
            HStack {
                Button("up") {
                    rtscene.camera.moveUp(ds: 1)
                    rtscene.render()
                }
                Button("down") {
                    rtscene.camera.moveUp(ds: -1)
                    rtscene.render()
                }
                
                Button("r left") {
                    rtscene.camera.rotateLR(deg: 10)
                    rtscene.render()
                }.keyboardShortcut("q", modifiers: [])
                Button("r right") {
                    rtscene.camera.rotateLR(deg: -10)
                    rtscene.render()
                }.keyboardShortcut("e", modifiers: [])
                Button("look up") {
                    rtscene.camera.rotateUD(deg: 10)
                    rtscene.render()
                }.keyboardShortcut("z", modifiers: [])
                Button("look down") {
                    rtscene.camera.rotateUD(deg: -10)
                    rtscene.render()
                }.keyboardShortcut("c", modifiers: [])
                
                Button("fwd") {
                    rtscene.camera.moveForward(ds: 1)
                    rtscene.render()
                }.keyboardShortcut("w", modifiers: [])
                Button("bck") {
                    rtscene.camera.moveForward(ds: -1)
                    rtscene.render()
                }.keyboardShortcut("s", modifiers: [])
                Button("s left") {
                    rtscene.camera.moveRight(ds: -1)
                    rtscene.render()
                }.keyboardShortcut("a", modifiers: [])
                Button("s right") {
                    rtscene.camera.moveRight(ds: 1)
                    rtscene.render()
                }.keyboardShortcut("d", modifiers: [])
                
                Stepper("Bounces \(numBounces)", value: $numBounces, step: 1)
                
                Text(String(format: "%.2fms, %dfps", rtscene.renderTime*1000, Int(1/rtscene.renderTime)))
            }
        }
        .padding()
        .task {
            vm.initialize()
            numBounces = rtscene.numBounces
            EventMonitor.shared.scrollWheelCallback = { dx, dy in
                let dy2 = 0.05 * min(5, dy)
                rtscene.camera.moveForward(ds: dy2)
                rtscene.render()
            }
            EventMonitor.shared.altMouseDragCallback = { dx, dy in
                rtscene.camera.movePivot(dx, dy)
                rtscene.render()
            }
        }
        .onChange(of: numBounces) { // oldValue, newValue in
            numBounces = max(1, min(20, numBounces))
            rtscene.numBounces = numBounces
            rtscene.render()
        }
        .gesture(DragGesture().onChanged({ drag in
            // let hasControlModifier = NSApp.currentEvent?.modifierFlags.contains(.control)
            rtscene.camera.rotateAroundLookAtPivot(drag.velocity.width, drag.velocity.height)
            rtscene.render()
        }))
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1.0, coordinateSpace: CoordinateSpace.local)
            .onChanged { value in
                let start = value.startLocation
                let end = value.location
                var i = 0.0
                while i <= 1.0 {
                    let x = ((1-i) * start.x + i * end.x)
                    let y = ((1-i) * start.y + i * end.y)
                    let pt = CGPoint(x: x, y: y)
                    rtscene.mark(point: pt)
                    i += 0.1
                }
            }
        
    }
    
    func cgimage() -> CGImage {
        let cgImage = Images.cgImageSRGB(rtscene.pixels, w: rtscene.w, h: rtscene.h, pixelSize: MemoryLayout<Pixel>.size)
        return cgImage
    }
    
    class ViewModel: ObservableObject {
        func initialize() {
            rtscene.update = { [weak self] in
                self?.objectWillChange.send()
            }
            rtscene.render()
        }
    }
}

class EventMonitor {
    static let shared = EventMonitor()
    var scrollWheelCallback: ((Double, Double)->())?
    var altMouseDragCallback: ((Double, Double)->())?
    
    init() {
        NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .rightMouseDragged]) { [weak self] event in
            switch event.type {
            case .scrollWheel:
                self?.scrollWheelCallback?(event.deltaX, event.deltaY)
                return nil
            case .rightMouseDragged:
                self?.altMouseDragCallback?(event.deltaX, event.deltaY)
                return nil
            default:
                return event
            }
        }
    }
    
    
}
