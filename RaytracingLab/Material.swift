
struct Material {
    
    let rgb : RGBColor
    let hsv : HSVColor
    let hsl : HSLColor
    let reflectivity = 0.0
    
    init(_ rgb: RGBColor) {
        self.rgb = rgb
        self.hsv = [1, 1, 1]
        self.hsl = [1, 1, 1]
    }
    
    init(_ hsv: HSVColor) {
        self.rgb = [1, 1, 1]
        self.hsv = hsv
        self.hsl = [1, 1, 1]
    }
    
    init(_ hsl: HSLColor) {
        self.rgb = [1, 1, 1]
        self.hsv = [1, 1, 1]
        self.hsl = hsl
    }
}
