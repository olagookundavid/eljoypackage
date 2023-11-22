//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//
#if os(iOS)
import Foundation
import AVFoundation

class Recorder {
    // Callback used to set up filled buffer
    private var callback: BufferCallback?

    // Recorder parameters
    private let audioSource = AVAudioSession.sharedInstance().inputDataSource?.dataSourceName

    // Mono=8b, Stereo=16b
    private let channelConfig = AVAudioSession.sharedInstance().inputDataSources?.first?.dataSourceName == "Stereo" ? AVAudioSession.ChannelCountStereo : AVAudioSession.ChannelCountMono

    // 16b or 8b per sample
    private let audioEncoding = AVAudioPCMFormat(supportedFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 44100, channels: 1)

    // Number of samples in 1sec
    private let sampleRate = 44100

    // Recording job
    private var job: DispatchWorkItem?

    private var optimalBufSize = 12000

    func start() {
        if job != nil { return }
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            let audioSession = AVAudioSession.sharedInstance()

            do {
                try audioSession.setCategory(.record)
                try audioSession.setActive(true)

                // Create an audio input for recording
                let audioInput = try AVAudioInputNode(format: self.audioEncoding)

                let audioFormat = audioInput.inputFormat(forBus: 0)
                let bufferSize = AVAudioFrameCount(self.optimalBufSize)

                audioInput.installTap(onBus: 0, bufferSize: bufferSize, format: audioFormat) { (buffer, time) in
                    guard let bufferData = buffer.floatChannelData?.pointee else { return }
                    let data = bufferData.withMemoryRebound(to: Int16.self, capacity: Int(buffer.frameLength)) {
                        return UnsafeBufferPointer(start: $0, count: Int(buffer.frameLength))
                    }
                    let byteArray = [Int16](data)
                    let buffer = byteArray.withUnsafeBytes { [UInt8]($0) }
                    self.callback?.onBufferAvailable(buffer)
                }

                // Start the audio engine
                audioSession.setActive(true)
                self.job = DispatchWorkItem { [weak audioInput] in
                    audioInput?.removeTap(onBus: 0)
                    audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                }
                DispatchQueue.global(qos: .background).async(execute: self.job!)
            } catch {
                print("Failed to start audio recording: \(error)")
            }
        }
    }

    func close() {
        job?.cancel()
        job = nil
    }
}

#endif
