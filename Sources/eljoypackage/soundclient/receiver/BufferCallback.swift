//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

// Protocol for the parent activity of the recorder
internal protocol BufferCallback {
    // Called when the recorder finishes recording one byte array
    func onBufferAvailable(buffer: [UInt8])
}

