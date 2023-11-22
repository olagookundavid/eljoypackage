//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

class AdaptiveHuffmanDecompress {
    
    static func main(args: [String]) throws {
        // Handle command line arguments
        if args.count != 2 {
            print("Usage: AdaptiveHuffmanDecompress InputFile OutputFile")
            exit(1)
        }
        let inputFile = URL(fileURLWithPath: args[0])
        let outputFile = URL(fileURLWithPath: args[1])
        
        let input = InputStream(url: inputFile)!
        input.open()
        let output = OutputStream(url: outputFile, append: false)!
        output.open()
        try decompress(input: BitInputStream.init(input: input), output: output)
        input.close()
        output.close()
    }
    
    static func decompress(input: BitInputStream, output: OutputStream) throws {
        var frequencies = Array(repeating: 1, count: 257)
        var frequencyTable = FrequencyTable(frequencies)
        var decoder = HuffmanDecoder(input: input)
        decoder.codeTree = frequencyTable.buildCodeTree()
        
        var count = 0 // Number of bytes written to the output file
        while true {
            // Decode and write one byte
            let symbol = try decoder.read()
            if symbol == 256 { // EOF symbol
                break
            }
            var byte = UInt8(symbol)
            let bytesWritten = output.write(&byte, maxLength: 1)
            if bytesWritten != 1 {
                throw NSError(domain: "OutputStream", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to write byte"])
            }
            count += 1
            
            // Update the frequency table and possibly the code tree
            frequencyTable.increment(symbol)
            if count < 262144 && count.isPowerOf2() || count % 262144 == 0 {
                // Update code tree
                decoder.codeTree = frequencyTable.buildCodeTree()
            }
            if count % 262144 == 0 {
                // Reset frequency table
                frequencyTable = FrequencyTable(frequencies)
            }
        }
    }
}

