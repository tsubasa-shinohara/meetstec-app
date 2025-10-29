import SwiftUI

struct GeometricPatternView: View {
    let frequency: Double
    let amplitude: Double
    let colorTheme: ColorTheme
    
    @State private var animationPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let midY = height / 2
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: midY))
                
                let segments = 100
                let segmentWidth = width / CGFloat(segments)
                
                for i in 0...segments {
                    let x = CGFloat(i) * segmentWidth
                    
                    let distortion = amplitude * sin(Double(i) * 0.3 + animationPhase)
                    let frequencyEffect = frequency > 0 ? sin(frequency / 100.0 * Double(i)) * amplitude : 0
                    
                    let y = midY + CGFloat(distortion + frequencyEffect)
                    
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.black, lineWidth: 3)
            .shadow(color: .white.opacity(0.5), radius: 2)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

struct WavePatternView: View {
    let frequency: Double
    let note: String
    let colorTheme: ColorTheme
    
    @State private var phase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                ForEach(0..<5, id: \.self) { layer in
                    Path { path in
                        let amplitude = frequency > 0 ? 30.0 + Double(layer) * 10.0 : 5.0
                        let wavelength = frequency > 0 ? max(50.0, 200.0 - frequency / 10.0) : 100.0
                        
                        path.move(to: CGPoint(x: 0, y: height / 2))
                        
                        for x in stride(from: 0, through: width, by: 2) {
                            let relativeX = x / wavelength
                            let y = height / 2 + CGFloat(sin((relativeX + phase + Double(layer) * 0.2) * .pi * 2) * amplitude)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(
                        Color.white.opacity(0.3 - Double(layer) * 0.05),
                        lineWidth: 2
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}
