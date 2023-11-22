//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

// A class for writing bits to an output stream.
internal class BitOutputStream {
    private let output: OutputStream // The underlying output stream.
    private var currentByte: UInt8 = 0 // The current byte being constructed.
    private var numOfBitsFilled: Int = 0 // Number of bits filled in the current byte.

    // Initialize the BitOutputStream with an underlying output stream.
    init(output: OutputStream) {
        self.output = output
    }

    // Write a bit to the stream. The bit must be 0 or 1.
    @discardableResult
    func write(_ bit: Int) throws -> Int {
        if bit != 0 && bit != 1 {
            throw BitOutputStreamError.argumentMustBeZeroOrOne
        }
        // Append the bit to the current byte.
        currentByte = currentByte << 1 | UInt8(bit)
        numOfBitsFilled += 1
        // If the current byte is full (8 bits), write it to the output stream.
        if numOfBitsFilled == 8 {
            output.write(&currentByte, maxLength: 1)
            currentByte = 0
            numOfBitsFilled = 0

        }
        return bit
    }

    // Close the stream, adding padding bits if necessary to reach the next byte boundary.
    func close() throws {
        while numOfBitsFilled != 0 {
            try write(0) // Add padding bits (0) to reach the next byte boundary.
        }
        output.close()
    }
}

// Define a custom error enum for the BitOutputStream class.
enum BitOutputStreamError: Error {
    case argumentMustBeZeroOrOne
}

