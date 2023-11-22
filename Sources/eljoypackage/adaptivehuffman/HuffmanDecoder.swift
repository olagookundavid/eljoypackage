//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class HuffmanDecoder {
    private let input: BitInputStream
    var codeTree: CodeTree?

    init(input: BitInputStream) {
        self.input = input
    }

    func read() throws -> Int {
        guard let codeTree = codeTree else {
            throw NSError(domain: "HuffmanDecoderError", code: 1, userInfo: ["message": "Code tree is nil"])
        }

        var currentNode = codeTree.root

        while true {
            let temp = try input.readNoEof()
            let nextNode: Node?

            switch temp {
            case 0:
                nextNode = currentNode.left
            case 1:
                nextNode = currentNode.right
            default:
                throw NSError(domain: "HuffmanDecoderError", code: 2, userInfo: ["message": "Invalid value from readNoEof()"])
            }
            switch nextNode {
                case .leaf(let leaf):
                    return leaf // since it is coming as an Int
                case .internalNode(left: let leftNode, right: let rightNode):
                    currentNode = InternalNode(left: leftNode, right: rightNode)
                default:
                    fatalError("Invalid node type")
            }


        }
    }
}

