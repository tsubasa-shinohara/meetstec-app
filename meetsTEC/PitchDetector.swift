import Foundation
import Accelerate

class PitchDetector {
    static let shared = PitchDetector()
    
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    private let fftSize = 4096
    private var fftSetup: FFTSetup?
    
    private var lastFrequency: Double = 0.0
    private var lastNote: String = ""
    private var lastNoteTime: Date = Date()
    private var frequencyHistory: [Double] = []
    private let historySize = 1
    
    init() {
        let log2n = vDSP_Length(log2(Float(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_destroy_fftsetup(setup)
        }
    }
    
    func detectPitch(from buffer: [Float], sampleRate: Double) -> (frequency: Double, note: String, confidence: Double)? {
        guard buffer.count > 0 else { return nil }
        
        let rms = calculateRMS(buffer)
        let noiseThreshold: Float = 0.002
        guard rms > noiseThreshold else { return nil }
        
        guard let fftSetup = fftSetup else { return nil }
        
        let halfSize = fftSize / 2
        
        var realPart = [Float](repeating: 0, count: halfSize)
        var imagPart = [Float](repeating: 0, count: halfSize)
        
        var complexBuffer = DSPSplitComplex(realp: &realPart, imagp: &imagPart)
        
        let log2n = vDSP_Length(log2(Float(fftSize)))
        
        var paddedBuffer = buffer
        if paddedBuffer.count < fftSize {
            paddedBuffer.append(contentsOf: [Float](repeating: 0, count: fftSize - paddedBuffer.count))
        }
        
        var windowedBuffer = applyHannWindow(paddedBuffer, size: fftSize)
        
        windowedBuffer.withUnsafeBufferPointer { bufferPointer in
            bufferPointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfSize) { complexPointer in
                vDSP_ctoz(complexPointer, 2, &complexBuffer, 1, vDSP_Length(halfSize))
            }
        }
        
        vDSP_fft_zrip(fftSetup, &complexBuffer, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0, count: halfSize)
        vDSP_zvmags(&complexBuffer, 1, &magnitudes, 1, vDSP_Length(halfSize))
        
        let minBin = Int(80.0 * Double(fftSize) / sampleRate)
        let maxBin = min(Int(2000.0 * Double(fftSize) / sampleRate), halfSize - 2)
        
        guard minBin < maxBin else { return nil }
        
        var maxMagnitude: Float = 0
        var maxIndex: vDSP_Length = 0
        let searchRange = Array(magnitudes[minBin...maxBin])
        vDSP_maxvi(searchRange, 1, &maxMagnitude, &maxIndex, vDSP_Length(searchRange.count))
        
        let actualIndex = maxIndex + vDSP_Length(minBin)
        
        guard actualIndex > 0 && actualIndex < halfSize - 1 else { return nil }
        
        let refinedIndex = parabolicInterpolation(
            magnitudes: magnitudes,
            peakIndex: Int(actualIndex)
        )
        
        var frequency = refinedIndex * sampleRate / Double(fftSize)
        
        guard frequency > 20 && frequency < 4000 else { return nil }
        
        frequency = smoothFrequency(frequency)
        
        let note = frequencyToNote(frequency)
        
        let noteHoldTime: TimeInterval = 0.1
        if note != lastNote && Date().timeIntervalSince(lastNoteTime) < noteHoldTime {
            return (frequency, lastNote, 0.8)
        }
        
        if note != lastNote {
            lastNote = note
            lastNoteTime = Date()
        }
        
        let avgMagnitude = searchRange.reduce(0, +) / Float(searchRange.count)
        
        guard avgMagnitude.isFinite && avgMagnitude > 1e-6 else { return nil }
        
        let snr = maxMagnitude / max(avgMagnitude, 1e-6)
        guard snr > 2.0 else { return nil }
        
        let confidence = min(max(Double((snr - 1) / 9), 0.0), 1.0)
        
        return (frequency, note, confidence)
    }
    
    private func calculateRMS(_ buffer: [Float]) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(buffer, 1, &rms, vDSP_Length(buffer.count))
        return rms
    }
    
    private func applyHannWindow(_ buffer: [Float], size: Int) -> [Float] {
        var window = [Float](repeating: 0, count: size)
        vDSP_hann_window(&window, vDSP_Length(size), Int32(vDSP_HANN_NORM))
        
        var result = [Float](repeating: 0, count: size)
        vDSP_vmul(buffer, 1, window, 1, &result, 1, vDSP_Length(size))
        
        return result
    }
    
    private func parabolicInterpolation(magnitudes: [Float], peakIndex: Int) -> Double {
        guard peakIndex > 0 && peakIndex < magnitudes.count - 1 else {
            return Double(peakIndex)
        }
        
        let alpha = magnitudes[peakIndex - 1]
        let beta = magnitudes[peakIndex]
        let gamma = magnitudes[peakIndex + 1]
        
        let denom = (alpha - 2 * beta + gamma)
        guard abs(denom) > .leastNonzeroMagnitude else {
            return Double(peakIndex)
        }
        
        let p = 0.5 * (alpha - gamma) / denom
        
        return Double(peakIndex) + Double(p)
    }
    
    private func smoothFrequency(_ frequency: Double) -> Double {
        frequencyHistory.append(frequency)
        if frequencyHistory.count > historySize {
            frequencyHistory.removeFirst()
        }
        
        let sorted = frequencyHistory.sorted()
        let median = sorted[sorted.count / 2]
        
        let alpha = 0.7
        lastFrequency = alpha * median + (1 - alpha) * lastFrequency
        
        return lastFrequency
    }
    
    private func frequencyToNote(_ frequency: Double) -> String {
        let a4 = 440.0
        let c0 = a4 * pow(2.0, -4.75)
        
        let halfSteps = 12.0 * log2(frequency / c0)
        let noteIndex = Int(round(halfSteps)) % 12
        
        return noteNames[noteIndex]
    }
}
