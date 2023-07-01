
struct Material {
    let colorRGB : RGBColor
    let colorHSV : HSVColor
    let reflectivity = 0.0
    
    init(colorRGB: RGBColor) {
        self.colorRGB = colorRGB
        self.colorHSV = [1, 1, 1]
    }
    
    init(colorHSV: HSVColor) {
        self.colorRGB = [1, 1, 1]
        self.colorHSV = colorHSV
    }
}
