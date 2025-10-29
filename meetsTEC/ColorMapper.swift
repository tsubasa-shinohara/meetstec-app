import SwiftUI

enum ColorTheme: String, CaseIterable {
    case rainbow = "虹色"
    case passionate = "情熱的"
    case calm = "静か"
}

class ColorMapper {
    static let shared = ColorMapper()
    
    private let rainbowColors: [String: Color] = [
        "C": Color(red: 1.0, green: 0.0, blue: 0.0),
        "C#": Color(red: 1.0, green: 0.5, blue: 0.0),
        "D": Color(red: 1.0, green: 1.0, blue: 0.0),
        "D#": Color(red: 0.5, green: 1.0, blue: 0.0),
        "E": Color(red: 0.0, green: 1.0, blue: 0.0),
        "F": Color(red: 0.0, green: 1.0, blue: 0.5),
        "F#": Color(red: 0.0, green: 1.0, blue: 1.0),
        "G": Color(red: 0.0, green: 0.5, blue: 1.0),
        "G#": Color(red: 0.0, green: 0.0, blue: 1.0),
        "A": Color(red: 0.5, green: 0.0, blue: 1.0),
        "A#": Color(red: 1.0, green: 0.0, blue: 1.0),
        "B": Color(red: 1.0, green: 0.0, blue: 0.5)
    ]
    
    private let passionateColors: [String: Color] = [
        "C": Color(red: 0.8, green: 0.0, blue: 0.0),
        "C#": Color(red: 0.9, green: 0.1, blue: 0.0),
        "D": Color(red: 1.0, green: 0.2, blue: 0.0),
        "D#": Color(red: 1.0, green: 0.3, blue: 0.0),
        "E": Color(red: 1.0, green: 0.4, blue: 0.0),
        "F": Color(red: 1.0, green: 0.5, blue: 0.0),
        "F#": Color(red: 1.0, green: 0.6, blue: 0.0),
        "G": Color(red: 1.0, green: 0.7, blue: 0.0),
        "G#": Color(red: 1.0, green: 0.8, blue: 0.0),
        "A": Color(red: 1.0, green: 0.9, blue: 0.0),
        "A#": Color(red: 1.0, green: 1.0, blue: 0.0),
        "B": Color(red: 0.9, green: 0.5, blue: 0.0)
    ]
    
    private let calmColors: [String: Color] = [
        "C": Color(red: 0.0, green: 0.1, blue: 0.3),
        "C#": Color(red: 0.0, green: 0.15, blue: 0.4),
        "D": Color(red: 0.0, green: 0.2, blue: 0.5),
        "D#": Color(red: 0.0, green: 0.3, blue: 0.6),
        "E": Color(red: 0.0, green: 0.4, blue: 0.7),
        "F": Color(red: 0.0, green: 0.5, blue: 0.8),
        "F#": Color(red: 0.0, green: 0.6, blue: 0.9),
        "G": Color(red: 0.1, green: 0.7, blue: 1.0),
        "G#": Color(red: 0.2, green: 0.6, blue: 0.9),
        "A": Color(red: 0.3, green: 0.5, blue: 0.8),
        "A#": Color(red: 0.4, green: 0.4, blue: 0.7),
        "B": Color(red: 0.5, green: 0.3, blue: 0.6)
    ]
    
    func color(for note: String, theme: ColorTheme) -> Color {
        let colorMap: [String: Color]
        
        switch theme {
        case .rainbow:
            colorMap = rainbowColors
        case .passionate:
            colorMap = passionateColors
        case .calm:
            colorMap = calmColors
        }
        
        return colorMap[note] ?? Color.gray
    }
    
    func interpolateColor(from: Color, to: Color, progress: Double) -> Color {
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * progress
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * progress
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * progress
        
        return Color(red: r, green: g, blue: b)
    }
}
