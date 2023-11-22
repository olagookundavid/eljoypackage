//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

struct HuffmanPriorityQueueNodeWithFrequency: Comparable {
    let node: Node
    let lowestSymbol: Int
    let frequency: Int64

    static func < (lhs: HuffmanPriorityQueueNodeWithFrequency, rhs: HuffmanPriorityQueueNodeWithFrequency) -> Bool {
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

    static func == (lhs: HuffmanPriorityQueueNodeWithFrequency, rhs: HuffmanPriorityQueueNodeWithFrequency) -> Bool {
        return lhs.frequency == rhs.frequency && lhs.lowestSymbol == rhs.lowestSymbol
    }
}

struct HuffmanPriorityQueue {
    private var nodes: [HuffmanPriorityQueueNodeWithFrequency]

    init() {
        nodes = []
    }

    var isEmpty: Bool {
        return nodes.isEmpty
    }

    var count: Int {
        return nodes.count
    }

    // Also called [add]
    mutating func enqueue(node: HuffmanPriorityQueueNodeWithFrequency) {
        nodes.append(node)
        heapifyUp(from: nodes.count - 1)
    }

    // Also called [remmove]
    mutating func dequeue() -> HuffmanPriorityQueueNodeWithFrequency? {
        if nodes.isEmpty {
            return nil
        }
        if nodes.count == 1 {
            return nodes.removeLast()
        }
        nodes.swapAt(0, nodes.count - 1)
        let top = nodes.removeLast()
        heapifyDown(from: 0)
        return top
    }

    private mutating func heapifyUp(from index: Int) {
        var child = index
        var parent = (child - 1) / 2
        while child > 0 && nodes[child] < nodes[parent] {
            nodes.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func heapifyDown(from index: Int) {
        var parent = index
        while true {
            let leftChild = 2 * parent + 1
            let rightChild = 2 * parent + 2
            var smallest = parent

            if leftChild < nodes.count && nodes[leftChild] < nodes[smallest] {
                smallest = leftChild
            }
            if rightChild < nodes.count && nodes[rightChild] < nodes[smallest] {
                smallest = rightChild
            }

            if smallest == parent {
                return
            }

            nodes.swapAt(parent, smallest)
            parent = smallest
        }
    }
}
