import Foundation
import Accelerate

class PitchDetector {
    static let shared = PitchDetector()
    
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    func detectPitch(from buffer: [Float], sampleRate: Double) -> (frequency: Double, note: String, confidence: Double)? {
        guard buffer.count > 0 else { return nil }
        
        let fftSize = min(4096, buffer.count)
        let halfSize = fftSize / 2
        
        var realPart = [Float](repeating: 0, count: halfSize)
        var imagPart = [Float](repeating: 0, count: halfSize)
        
        var complexBuffer = DSPSplitComplex(realp: &realPart, imagp: &imagPart)
        
        let log2n = vDSP_Length(log2(Float(fftSize)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return nil
        }
        
        var paddedBuffer = buffer
        if paddedBuffer.count < fftSize {
            paddedBuffer.append(contentsOf: [Float](repeating: 0, count: fftSize - paddedBuffer.count))
        }
        
        paddedBuffer.withUnsafeBufferPointer { bufferPointer in
            bufferPointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfSize) { complexPointer in
                vDSP_ctoz(complexPointer, 2, &complexBuffer, 1, vDSP_Length(halfSize))
            }
        }
        
        vDSP_fft_zrip(fftSetup, &complexBuffer, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0, count: halfSize)
        vDSP_zvmags(&complexBuffer, 1, &magnitudes, 1, vDSP_Length(halfSize))
        
        vDSP_destroy_fftsetup(fftSetup)
        
        var maxMagnitude: Float = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxvi(magnitudes, 1, &maxMagnitude, &maxIndex, vDSP_Length(halfSize))
        
        guard maxIndex > 0 && maxIndex < halfSize else { return nil }
        
        let frequency = Double(maxIndex) * sampleRate / Double(fftSize)
        
        guard frequency > 20 && frequency < 4000 else { return nil }
        
        let note = frequencyToNote(frequency)
        
        let avgMagnitude = magnitudes.reduce(0, +) / Float(magnitudes.count)
        let confidence = min(Double(maxMagnitude / (avgMagnitude * 10)), 1.0)
        
        return (frequency, note, confidence)
    }
    
    private func frequencyToNote(_ frequency: Double) -> String {
        let a4 = 440.0
        let c0 = a4 * pow(2.0, -4.75)
        
        let halfSteps = 12.0 * log2(frequency / c0)
        let noteIndex = Int(round(halfSteps)) % 12
        
        return noteNames[noteIndex]
    }
}
