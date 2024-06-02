import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var vm = ViewModel()
    @State var numBounces = 1
    
    var body: some View {
        VStack {
            GeometryReader { g in
                Image(cgimage(), scale: 1.0, label: Text(""))
                    .resizable(resizingMode: .stretch)
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture(count: 1, coordinateSpace: .local, perform: { point in
                        let hasControl = NSApp.currentEvent?.modifierFlags.contains(.control) ?? false
                        if hasControl {
                            rtscene.debugPoint = (Int(point.x/g.size.width * CGFloat(rtscene.w)),
                                                  Int(point.y/g.size.height * CGFloat(rtscene.h)))
                            rtscene.render()
                            rtscene.debugPoint = nil
                        }
                    })
            }
                // .frame(width: CGFloat(rtscene.w), height: CGFloat(rtscene.h))
                // .gesture(drawingDragGesture)
            Text("Mouse Drag - rotate, Mouse Right Drag - move pivot, Scroll Wheel - zoom")
            HStack {
                // axisControls
                Stepper("Bounces \(numBounces)", value: $numBounces, step: 1)
                Text(String(format: "%dx%d, %.2fms, %dfps", rtscene.w, rtscene.h, rtscene.renderTime*1000, Int(1/rtscene.renderTime)))
            }
        }
        .padding()
        .task {
            vm.initialize()
            numBounces = rtscene.numBounces
            listenToEventMonitor()
        }
        .onChange(of: numBounces) {
            numBounces = max(1, min(20, numBounces))
            rtscene.numBounces = numBounces
            rtscene.render()
        }
        .gesture(DragGesture().onChanged({ drag in
            let limit = 2.0
            let dx2 = 0.75 * min(limit, max(drag.velocity.width, -limit))
            let dy2 = 0.75 * min(limit, max(-limit, drag.velocity.height))
            // input smoothing: convert input [-limit, limit] to [0,1], apply exponential function that preserves the sign, convert back to [-limit, limit]
            // dx2 = pow((dx2/limit), 3) * limit
            // dy2 = pow((dy2/limit), 3) * limit
            rtscene.rotateAroundLookAtPivot(dx2, dy2)
            rtscene.render()
        }))
        .onReceive(timer, perform: { _ in
            rtscene.camera.rotateAroundLookAtPivot(-0.75, 0)
            rtscene.render()
        })
    }
    
    // auto-rotate timer
    var timer = Timer.publish(every: 0.016, on: .main, in: .common)
                     .autoconnect()
    
    func listenToEventMonitor() {
        EventMonitor.shared.callback = { event in
            switch event.type {
            case .scrollWheel:
                let dy = 0.05 * min(5, event.deltaY)
                rtscene.moveForward(ds: dy)
                
            case .rightMouseDragged:
                rtscene.movePivot(event.deltaX, event.deltaY)
                
            default: return false
            }
            
            rtscene.render()
            return true
        }
    }
    
    var axisControls: some View {
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
        }
    }
    
    var drawingDragGesture: some Gesture {
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
        let cgImage = Images.cgImageSRGB(rtscene.pixels_ptr, w: rtscene.w, h: rtscene.h, pixelSize: MemoryLayout<Pixel>.size)
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
    var callback: ((NSEvent) -> Bool)?
    
    init() {
        NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .rightMouseDragged]) { [weak self] event in
            if self?.callback?(event) ?? false {
                return nil
            }
            return event
        }
    }
    
    
}
