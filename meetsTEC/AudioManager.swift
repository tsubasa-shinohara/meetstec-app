import AVFoundation
import Combine

class AudioManager: ObservableObject {
    @Published var currentNote: String = ""
    @Published var currentFrequency: Double = 0.0
    @Published var currentColor: String = "gray"
    @Published var isListening: Bool = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let pitchDetector = PitchDetector.shared
    private let colorMapper = ColorMapper.shared
    
    private var audioBuffer: [Float] = []
    private let bufferSize = 4096
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func startListening() {
        guard !isListening else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
            
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            inputNode = audioEngine.inputNode
            guard let inputNode = inputNode else { return }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            let sampleRate = recordingFormat.sampleRate
            
            try audioSession.setPreferredIOBufferDuration(0.005)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self else { return }
                self.processAudioBuffer(buffer, sampleRate: sampleRate)
            }
            
            try audioEngine.start()
            
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        audioBuffer.append(contentsOf: samples)
        
        let hop = bufferSize / 4
        while audioBuffer.count >= bufferSize {
            let bufferToProcess = Array(audioBuffer.prefix(bufferSize))
            audioBuffer.removeFirst(hop)
            
            if let result = pitchDetector.detectPitch(from: bufferToProcess, sampleRate: sampleRate) {
                if result.confidence > 0.3 {
                    DispatchQueue.main.async {
                        self.currentNote = result.note
                        self.currentFrequency = result.frequency
                        self.currentColor = result.note
                    }
                }
            }
        }
    }
}
