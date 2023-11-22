//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//
#if os(iOS)
import Foundation

class ReceiverTask {
    private let lock = "lock"
    private let mutex = DispatchSemaphore(value: 1)

    private var recordedArray = [ChunkElement]()
    private var job: DispatchWorkItem?

    private let recorder = Recorder(delegate: self)
    

    private lazy var bitConverter: BitFrequencyConverter = {
        return BitFrequencyConverter(startFrequency: startFrequency, endFrequency: endFrequency, bitPerTone: bitPerTone)
    }()

    init(startFrequency: Int = SenderTask.DEFAULT_START_FREQUENCY,
         endFrequency: Int = SenderTask.DEFAULT_END_FREQUENCY,
         bitPerTone: Int = SenderTask.DEFAULT_BITS_PER_TONE,
         encoding: Bool = SenderTask.DEFAULT_ENCODING,
         errorDetectionNumber: Int? = nil,
         fileName: String? = nil,
         onStarted: @escaping () -> Void,
         onDone: @escaping (String) -> Void) {
        // Initialized the properties
        self.startFrequency = frequency
        self.endFrequency = endFrequency
        self.bitPerTone = bitPerTone
        self.encoding = encoding
        self.errorDetectionNumber = errorDetectionNumber
        self.fileName = fileName
        self.onStarted = onStarted
        self.onDone = onDone
    }

    func start() {
        // Load channel syncorization parameters
        let halfPad = bitConverter.padding / 2
        let handshakeStart = bitConverter.handshakeStartFreq
        let handshakeEnd = bitConverter.handshakeEndFreq
        
        // Start the recorder
        recorder.start()
        
        var listeningStarted = false
        var startCounter = 0
        var endCounter = 0
        var lastInfo = 2
        
        while true {
            // Wait and get recorded data
            var tempElem: ChunkElement
            
            do {
                while recordedArray.isEmpty {
                    locks()
                }
                tempElem = recordedArray.remove(at: 0)
            } catch {
                print("Failed to get first element")
                continue
            }
            
            defer {
                unlock()
            }
            
            // Calculate frequency from recorded data
            let currNum = calculate(buffer: tempElem.buffer, startFrequency: startFrequency, endFrequency: endFrequency, halfPad: halfPad)
            
            // Check if listening started
            if !listeningStarted {
                // If listening didn't start and frequency is in the range of Start Handshake Frequency
                if currNum > handshakeStart - halfPad && currNum < handshakeStart + halfPad {
                    startCounter += 1
                    // If there were two Start Handshake Frequency one after another, start recording
                    if startCounter >= 2 {
                        listeningStarted = true
                        // Used to tell callback that receiving started
                        onStarted()
                    }
                } else {
                    // If it's not Start Handshake Frequency, reset counter
                    startCounter = 0
                }
            } else {
                // Check if it's Start Handshake Frequency (used as a synchronization bit) after receiving starts
                if currNum > handshakeStart - halfPad && currNum < handshakeStart + halfPad {
                    // Reset the flag for received data
                    lastInfo = 2
                    // Reset end counter
                    endCounter = 0
                } else {
                    // Check if it's End Handshake Frequency
                    if currNum > handshakeEnd - halfPad {
                        endCounter += 1
                        // If there were two End Handshake Frequencies one after another, stop recording if
                        // a chat message is expected (fileName != nil) or if it's data transfer and only the name
                        // has been received, reset counters and flags and start receiving file data.
                        if endCounter >= 2 {
                            if let fileName = fileName {
                                namePartBArray = bitConverter.getAndResetReadBytes()
                            }
                            print("Receiving done")
                            onDone()
                            break
                        }
                    } else {
                        // Reset end counter
                        endCounter = 0
                        // Check if data has been received before the last synchronization bit
                        if lastInfo != 0 {
                            // Set the flag
                            lastInfo = 0
                            // Add frequency to received frequencies
                            bitConverter.calculateBits(frequency: currNum)
                        }
                    }
                }
            }
        }
    }


    func close() {
        recorder.close()
        job?.cancel()
        job = nil
    }

    private func calculate(buffer: [UInt8], startFrequency: Int, endFrequency: Int, halfPad: Int) -> Double {
        // Implement the calculation function
    }

    private func locks() {
        mutex.wait()
    }

    private func unlock() {
        mutex.signal()
    }

    private func onDone() {
        // Implement the onDone function
    }
}

extension ReceiverTask: BufferCallback {
    func onBufferAvailable(buffer: [UInt8]) {
        recordedArray.append(ChunkElement(buffer: buffer))
        unlock()
        while recordedArray.count > 100 {
            locks()
        }
    }
}

#endif
