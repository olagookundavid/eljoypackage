//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal indirect enum Node: NodeProtocol {
    case internalNode(left: Node, right: Node)
    case leaf(symbol: Int)
}

internal extension Node {
    func isInternalNode() -> Bool {
        if case .internalNode = self {
            return true
        }
        return false
    }
}

internal protocol NodeProtocol {
    func isInternalNode() -> Bool
}
