//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class InternalNode: NodeProtocol {
    let left: Node
    let right: Node

    init(left: Node, right: Node) {
        self.left = left
        self.right = right
    }

    func isInternalNode() -> Bool {
        return true
    }
}
