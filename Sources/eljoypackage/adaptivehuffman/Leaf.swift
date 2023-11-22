//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class Leaf {
    let symbol: Int

    init(symbol: Int) {
        precondition(symbol >= 0, "Symbol value must be non-negative")
        self.symbol = symbol
    }
}

