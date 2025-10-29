import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var displayColor: Color = .gray
    @State private var targetColor: Color = .gray
    @State private var selectedTheme: ColorTheme = .rainbow
    @State private var showThemeSelector: Bool = false
    
    private let colorMapper = ColorMapper.shared
    
    var body: some View {
        ZStack {
            displayColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: displayColor)
            
            GeometricPatternView(
                frequency: audioManager.currentFrequency,
                amplitude: audioManager.currentFrequency > 0 ? 50.0 : 5.0,
                colorTheme: selectedTheme
            )
            .ignoresSafeArea()
            
            WavePatternView(
                frequency: audioManager.currentFrequency,
                note: audioManager.currentNote,
                colorTheme: selectedTheme
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        showThemeSelector.toggle()
                    }) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(15)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                
                if showThemeSelector {
                    VStack(spacing: 10) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Button(action: {
                                selectedTheme = theme
                                showThemeSelector = false
                            }) {
                                Text(theme.rawValue)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(selectedTheme == theme ? Color.white.opacity(0.3) : Color.black.opacity(0.5))
                                    )
                            }
                        }
                    }
                    .padding(.trailing, 20)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    Text(audioManager.currentNote.isEmpty ? "♪" : audioManager.currentNote)
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    if audioManager.currentFrequency > 0 {
                        Text(String(format: "%.1f Hz", audioManager.currentFrequency))
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if audioManager.isListening {
                        audioManager.stopListening()
                    } else {
                        audioManager.requestMicrophonePermission { granted in
                            if granted {
                                audioManager.startListening()
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: audioManager.isListening ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 30))
                        Text(audioManager.isListening ? "Stop" : "Start")
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .fill(audioManager.isListening ? Color.red.opacity(0.7) : Color.blue.opacity(0.7))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10)
                }
                .padding(.bottom, 50)
            }
        }
        .onChange(of: audioManager.currentColor) { newNote in
            if !newNote.isEmpty && newNote != "gray" {
                targetColor = colorMapper.color(for: newNote, theme: selectedTheme)
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayColor = targetColor
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

