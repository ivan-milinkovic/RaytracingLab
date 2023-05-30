import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var vm = ViewModel()
    var body: some View {
        VStack {
            Image(cgimage(), scale: 1.0, label: Text(""))
                .resizable(resizingMode: .stretch)
                .aspectRatio(contentMode: .fit)
//                .frame(width: CGFloat(rtscene.w), height: CGFloat(rtscene.h))
//                .border(Color.orange)
//                .gesture(dragGesture)
        }
        .padding()
        .task {
            vm.initialize()
        }
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
