//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

class BitInputStream {
    
    private var input: InputStream
    private var currentByte: Int = 0
    private var numOfBitsRemaining: Int = 0
    
    init(input: InputStream) {
        self.input = input
    }
    
    func read() throws -> Int {
        if currentByte == -1 {
            return -1
        }
        if numOfBitsRemaining == 0 {
            var buffer = [UInt8]() // Define an array of UInt8
            let bytesRead = input.read(&buffer, maxLength: 1)
            if bytesRead == -1 {
                return -1
            }
            currentByte = Int(buffer[0]) // Access the first element of the buffer array
            numOfBitsRemaining = 8
        }

        if numOfBitsRemaining <= 0 {
            throw NSError(domain: "BitInputStream", code: 1, userInfo: [NSLocalizedDescriptionKey: "AssertionError"])
        }
        numOfBitsRemaining -= 1
        return (currentByte >> numOfBitsRemaining) & 1
    }
    
    func readNoEof() throws -> Int {
        let result = try read()
        if result != -1 {
            return result
        } else {
            throw NSError(domain: "BitInputStream", code: 2, userInfo: [NSLocalizedDescriptionKey: "EOFException"])
        }
    }
    
    func close() throws {
        input.close()
        currentByte = -1
        numOfBitsRemaining = 0
    }
}

