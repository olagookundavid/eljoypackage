//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//
#if os(iOS)
import Foundation
import AVFoundation

class SenderTask {
    private let startFrequency: Int
    private let endFrequency: Int
    private let bitsPerTone: Int
    private let encoding: Bool
    private let errorDetectionNumber: Int?
    private let message: [UInt8]
    private let file: [UInt8]?
    private let onProgress: (Int) -> Void
    private let onDone: () -> Void
    private var tone: AVAudioPlayer?
    
    init(
        startFrequency: Int = DEFAULT_START_FREQUENCY,
        endFrequency: Int = DEFAULT_END_FREQUENCY,
        bitsPerTone: Int = DEFAULT_BITS_PER_TONE,
        encoding: Bool = DEFAULT_ENCODING,
        errorDetectionNumber: Int? = nil,
        message: [UInt8],
        file: [UInt8]? = nil,
        onProgress: @escaping (Int) -> Void,
        onDone: @escaping () -> Void
    ) {
        self.startFrequency = startFrequency
        self.endFrequency = endFrequency
        self.bitsPerTone = bitsPerTone
        self.encoding = encoding
        self.errorDetectionNumber = errorDetectionNumber
        self.message = message
        self.file = file
        self.onProgress = onProgress
        self.onDone = onDone
    }
    
    func start() {
        // Create bit to frequency converter
        let bitConverter = BitFrequencyConverter(startFrequency: startFrequency, endFrequency: endFrequency, bitsPerTone: bitsPerTone)
        var encodedMessage = message
        var encodedMessageFile = file

        // If encoding is on
        if encoding {
            // Encode message with adaptive huffman
            let input = Data(encodedMessage)
            if let compressedData = try? AdaptiveHuffmanCompress.compress(input: input, output: <#OutputStream#>) {
                encodedMessage = [UInt8](compressedData)
            }

            // If it's data transfer, encode data of the file
            if let fileData = encodedMessageFile {
                let fileInput = Data(fileData)
                if let compressedFileData = try? AdaptiveHuffmanCompress.compress(input: fileInput, output: OutputStream) {
                    encodedMessageFile = [UInt8](compressedFileData)
                }
            }
        }

        // If error detection is on
        if let errorDetectionNumber = errorDetectionNumber {
            let parser = ByteArrayParser()
            var list = parser.divideInto256Chunks(encodedMessage, errorDetectionNumber)
            let encoder = EncoderDecoder()

            // Encode byte arrays with Reed Solomon
            for i in 0..<list.count {
                do {
                    if let encodedData = try encoder.encodeData(list[i], errorDetectionNumber) {
                        parser.mergeArray(encodedData)
                    }
                } catch {
                    return
                }
            }
            
            // Merge encoded chunks
            encodedMessage = parser.getAndResetOutputByteArray() ?? encodedMessage

            // If file is being sent, do the same for the data of the file
            if let encodedFileData = encodedMessageFile {
                list = parser.divideInto256Chunks(encodedFileData, errorDetectionNumber)

                for i in 0..<list.count {
                    do {
                        if let encodedData = try encoder.encodeData(list[i], errorDetectionNumber) {
                            parser.mergeArray(encodedData)
                        }
                    } catch {
                        return
                    }
                }

                encodedMessageFile = parser.getAndResetOutputByteArray()
            }
        }

        let frequencies = bitConverter.calculateFrequency(encodedMessage)
        var frequenciesFile: [Int]?

        if let encodedFileData = encodedMessageFile {
            frequenciesFile = bitConverter.calculateFrequency(encodedFileData)
        }

        // Create an audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            return
        }
        
        tone = AVAudioPlayer()
        tone?.numberOfLoops = 0
        tone?.volume = 1.0
        
        var progress = 0
        var allLength = frequencies.count * 2 + 4
        
        if let frequenciesFile = frequenciesFile {
            allLength += frequenciesFile.count * 2 + 4
        }

        // Start communication with start handshake
        playTone(Double(bitConverter.handshakeStartFreq))
        onProgress(++progress * 100 / allLength)
        playTone(Double(bitConverter.handshakeStartFreq))
        onProgress(++progress * 100 / allLength)

        // Transfer message if chat and file extension if data
        for freq in frequencies {
            playTone(Double(freq), duration: DURATION_SEC / 2)
            onProgress(++progress * 100 / allLength)
            playTone(Double(bitConverter.handshakeStartFreq))
            onProgress(++progress * 100 / allLength)
        }

        // End communication with end handshake
        playTone(Double(bitConverter.handshakeEndFreq))
        onProgress(++progress * 100 / allLength)
        playTone(Double(bitConverter.handshakeEndFreq))
        onProgress(++progress * 100 / allLength)

        // If the file is being sent, send file data too
        if let frequenciesFile = frequenciesFile {
            playTone(Double(bitConverter.handshakeStartFreq))
            onProgress(++progress * 100 / allLength)
            playTone(Double(bitConverter.handshakeStartFreq))
            onProgress(++progress * 100 / allLength)

            for freq in frequenciesFile {
                playTone(Double(freq), duration: DURATION_SEC / 2)
                onProgress(++progress * 100 / allLength)
                playTone(Double(bitConverter.handshakeStartFreq))
                onProgress(++progress * 100 / allLength)
            }

            playTone(Double(bitConverter.handshakeEndFreq))
            onProgress(++progress * 100 / allLength)
            playTone(Double(bitConverter.handshakeEndFreq))
            onProgress(++progress * 100 / allLength)
        }

        onDone()
    }

    func close() {
        tone?.stop()
        tone = nil
    }

    // Called to play a tone of a specific frequency for a specific duration
    private func playTone(_ frequencyOfTone: Double, duration: Double = DURATION_SEC) {
        let numberOfSamples = Int(ceil(duration * Double(SAMPLE_RATE)))
        var sample = [Double](repeating: 0.0, count: numberOfSamples)
        var generatedSnd = [UInt8](repeating: 0, count: 2 * numberOfSamples)
        let anglePadding = frequencyOfTone * 2 * Double.pi / Double(SAMPLE_RATE)
        var angleCurrent = 0.0
        
        for i in 0..<numberOfSamples {
            sample[i] = sin(angleCurrent)
            angleCurrent += anglePadding
        }

        var idx = 0
        let ramp = numberOfSamples / 20
        
        var i = 0
        while i < ramp {
            let value = Int16(sample[i] * 32767 * Double(i) / Double(ramp))
            generatedSnd[idx] = UInt8(value & 0x00ff)
            generatedSnd[idx + 1] = UInt8((value & 0xff00) >> 8)
            idx += 2
            i += 1
        }
        
        i = ramp
        while i < numberOfSamples - ramp {
            let value = Int16(sample[i] * 32767)
            generatedSnd[idx] = UInt8(value & 0x00ff)
            generatedSnd[idx + 1] = UInt8((value & 0xff00) >> 8)
            idx += 2
            i += 1
        }

        i = numberOfSamples - ramp
        while i < numberOfSamples {
            let value = Int16(sample[i] * 32767 * (numberOfSamples - i) / ramp)
            generatedSnd[idx] = UInt8(value & 0x00ff)
            generatedSnd[idx + 1] = UInt8((value & 0xff00) >> 8)
            idx += 2
            i += 1
        }
        
        tone?.stop()
        tone?.prepareToPlay()
        tone?.data = Data(generatedSnd)
        tone?.play()
    }

    static let DEFAULT_START_FREQUENCY = 17_500
    static let DEFAULT_END_FREQUENCY = 20_000
    static let DEFAULT_BITS_PER_TONE = 4
    static let DEFAULT_ENCODING = false
    static let DEFAULT_ERROR_DETECTION_NUMBER = 4
    static let SAMPLE_RATE = 44100
    private let DURATION_SEC = 0.270
}

#endif
