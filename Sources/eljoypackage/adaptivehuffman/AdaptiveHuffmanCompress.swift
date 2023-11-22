//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

class AdaptiveHuffmanCompress {
    
    static func main(args: [String]) throws {
        // Handle command line arguments
        if args.count != 2 {
            print("Usage: AdaptiveHuffmanCompress InputFile OutputFile")
            exit(1)
        }
        let inputFile = URL(fileURLWithPath: args[0])
        let outputFile = URL(fileURLWithPath: args[1])
        
        let input = try Data(contentsOf: inputFile)
        let output = OutputStream(url: outputFile, append: false)!
        output.open()
        try compress(input: input, output: output)
        output.close()
    }
    
    static func compress(input: Data, output: OutputStream) throws {
        var frequencies = Array(repeating: 1, count: 257)
        var frequencyTable = FrequencyTable(frequencies)
        var encoder = HuffmanEncoder(output: BitOutputStream.init(output: output))
        encoder.codeTree =  frequencyTable.buildCodeTree()
        
        var count = 0 // Number of bytes read from the input file
        for symbol in input {
            try encoder.write(symbol: Int(symbol))
            count += 1
            
            // Update the frequency table and possibly the code tree
            frequencyTable.increment(Int(symbol))
            if count < 262144 && count.isPowerOf2() || count % 262144 == 0 {
                // Update code tree
                encoder.codeTree =  frequencyTable.buildCodeTree()
            }
            if count % 262144 == 0 {
                // Reset frequency table
                frequencyTable = FrequencyTable(frequencies)
            }
        }
        try encoder.write(symbol: 256) // EOF
    }
}

