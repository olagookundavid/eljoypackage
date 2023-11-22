//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class HuffmanEncoder {
    private var output: BitOutputStream
    var codeTree: CodeTree?

    init(output: BitOutputStream) {
        self.output = output
    }

    func write(symbol: Int) throws {
        guard let codeTree = codeTree else {
            throw NSError(domain: "HuffmanEncoder", code: 1, userInfo: [NSLocalizedDescriptionKey: "Code tree is null"])
        }
        
        guard let bits = codeTree.getCode(symbol: symbol) else {
            throw NSError(domain: "HuffmanEncoder", code: 2, userInfo: [NSLocalizedDescriptionKey: "No code for the given symbol"])
        }

        for b in bits {
            try output.write(b)
        }
    }
}

