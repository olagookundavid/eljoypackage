//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//
// A binary tree that represents a mapping between symbols and binary strings.
// The data structure is immutable. There are two main uses of a code tree:
// 1. Read the root field and walk through the tree to extract the desired information.
// 2. Call getCode() to get the binary code for a particular encodable symbol.
//
// The path to a leaf node determines the leaf's symbol's code. Starting from the root, going
// to the left child represents a 0, and going to the right child represents a 1.
// Constraints:
// - The root must be an internal node, and the tree is finite.
// - No symbol value is found in more than one leaf.
// - Not every possible symbol value needs to be in the tree.

// Illustrated example:
// Huffman codes:
// 0: Symbol A
// 10: Symbol B
// 110: Symbol C
// 111: Symbol D

// Code tree:
// .
// / \
// A   .
// / \
// B   .
// / \
// C   D
import Foundation

class CodeTree {
    // Definition of your Node types
    private var codes: [Int: [Int]?] = [:]
    var root: InternalNode // Define InternalNode or adjust this based on your code structure

    init(root: InternalNode, symbolLimit: Int) {
        precondition(symbolLimit >= 2, "At least 2 symbols needed")
        self.root = root
        for i in 0..<symbolLimit {
            codes[i] = nil
        }
        buildCodeList(node: Node.internalNode(left: root.left, right: root.right), prefix: [])
    }

    private func buildCodeList(node: Node, prefix: [Int]) {
        switch node {
        case .internalNode(let left, let right):
            var leftPrefix = prefix + [0]
            buildCodeList(node: left, prefix: leftPrefix)
            var rightPrefix = prefix + [1]
            buildCodeList(node: right, prefix: rightPrefix)

        case .leaf(let symbol):
            precondition(symbol < codes.count, "Symbol exceeds symbol limit")
            precondition(codes[symbol] == nil, "Symbol has more than one code")
            codes[symbol] = prefix
        }
    }

    func getCode(symbol: Int) -> [Int]? {
        guard symbol >= 0 else {
            preconditionFailure("Illegal symbol")
        }
        guard let code = codes[symbol] else {
            preconditionFailure("No code for the given symbol")
        }
        return code
    }

    func toString() -> String {
        var result = StringBuilder()
        recursiveToString(prefix: "", node: Node.internalNode(left: root.left, right: root.right), builder: &result)
        return result.toString()
    }

    private func recursiveToString(prefix: String, node: Node, builder: inout StringBuilder) {
        switch node {
        case .internalNode(let left, let right):
               recursiveToString(prefix: prefix + "0", node: left, builder: &builder)
               recursiveToString(prefix: prefix + "1", node: right, builder: &builder)

           case .leaf(let symbol):
               builder.append("Code \(prefix): Symbol \(symbol)\n")
        }
    }
}
