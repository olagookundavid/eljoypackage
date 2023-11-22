//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

// A table of symbol frequencies. Mutable and not thread-safe. Symbols values are
// numbered from 0 to symbolLimit1. A frequency table is mainly used like this:
//
//  1. Collect the frequencies of symbols in the stream that we want to compress.
//  2. Build a code tree that is statically optimal for the current frequencies.
//
// This implementation is designed to avoid arithmetic overflow - it correctly builds
// an optimal code tree for any legal number of symbols (2 to Int.max), with each symbol having a legal frequency (0 to Int.max).
class FrequencyTable {
    // An array of frequencies of all symbols
    private var frequencies: [Int]

    init(_ frequencies: [Int]) {
        precondition(frequencies.count >= 2, "At least 2 symbols needed")
        for frequency in frequencies {
            precondition(frequency >= 0, "Negative frequency")
        }
        self.frequencies = frequencies
    }

    // Returns the number of symbols in this frequency table. The result is always at least 2.
    var symbolLimit: Int {
        return frequencies.count
    }

    subscript(symbol: Int) -> Int {
        // Returns the frequency of the specified symbol in this frequency table.
        get {
            checkSymbol(symbol)
            return frequencies[symbol]
        }
        // Sets the frequency of the specified symbol in this frequency table to the specified value.
        set {
            checkSymbol(symbol)
            precondition(newValue >= 0, "Negative frequency")
            frequencies[symbol] = newValue
        }
    }


    // Increments the frequency of the specified symbol in this frequency table.
    func increment(_ symbol: Int) {
        checkSymbol(symbol)
        precondition(frequencies[symbol] != Int.max, "Maximum frequency reached")
        frequencies[symbol] += 1
    }

    // Returns silently if 0 <= symbol < frequencies.count, otherwise throws an exception.
    private func checkSymbol(_ symbol: Int) {
        precondition(symbol >= 0 && symbol < frequencies.count, "Symbol out of range")
    }

    // Returns a code tree that is optimal for the symbol frequencies in this table.
    func buildCodeTree() -> CodeTree {
        var queue: HuffmanPriorityQueue = HuffmanPriorityQueue()

        // Add leaves for symbols with non-zero frequency
        for i in 0..<frequencies.count {
            if frequencies[i] > 0 {
                queue.enqueue(node: HuffmanPriorityQueueNodeWithFrequency(node: Node.leaf(symbol: i), lowestSymbol: i, frequency: Int64(frequencies[i])))
            }
        }

        // Pad with zero-frequency symbols until queue has at least 2 items
        var i = 0
        while i < frequencies.count && queue.count < 2 {
            if frequencies[i] == 0 {
                queue.enqueue(node: HuffmanPriorityQueueNodeWithFrequency(node: Node.leaf(symbol: i), lowestSymbol: i, frequency: 0))
            }
            i += 1
        }

        if queue.count < 2 {
            fatalError("Assertion Error")
        }

        while queue.count > 1 {
            guard let x = queue.dequeue(), let y = queue.dequeue() else {
                fatalError("Insufficient nodes in the queue")
            }
            let internalNode = InternalNode(left: x.node, right: y.node)
            let lowestSymbol = min(x.lowestSymbol, y.lowestSymbol)
            let frequency = x.frequency + y.frequency
            let nodeWithFrequency = HuffmanPriorityQueueNodeWithFrequency(node: Node.internalNode(left: internalNode.left, right: internalNode.right), lowestSymbol: lowestSymbol, frequency: frequency)
            queue.enqueue(node: nodeWithFrequency)

        }


        if let rootNode = queue.dequeue()?.node as? InternalNode {
            return CodeTree(root: rootNode, symbolLimit: frequencies.count)
        } else {
            fatalError("Failed to retrieve an InternalNode from the queue")
        }
    }

    // Helper structure for buildCodeTree()
    private class NodeWithFrequency: Comparable {
        let node: Node
        let lowestSymbol: Int // Using wider type prevents overflow
        let frequency: Int64

        init(_ node: Node, _ lowestSymbol: Int, _ frequency: Int64) {
            self.node = node
            self.lowestSymbol = lowestSymbol
            self.frequency = frequency
        }

        static func < (lhs: NodeWithFrequency, rhs: NodeWithFrequency) -> Bool {
            if lhs.frequency < rhs.frequency {
                return true
            } else if lhs.frequency > rhs.frequency {
                return false
            } else if lhs.lowestSymbol < rhs.lowestSymbol {
                return true
            } else if lhs.lowestSymbol > rhs.lowestSymbol {
                return false
            } else {
                return true
            }
        }

        static func == (lhs: NodeWithFrequency, rhs: NodeWithFrequency) -> Bool {
            return lhs.frequency == rhs.frequency && lhs.lowestSymbol == rhs.lowestSymbol
        }
    }
}
