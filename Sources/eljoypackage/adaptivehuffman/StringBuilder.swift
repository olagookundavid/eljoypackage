//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

class StringBuilder {
    private var buffer: String = ""

    init() {}

    func append(_ str: String) {
        buffer += str
    }

    func appendLine(_ str: String) {
        buffer += str + "\n"
    }

    func clear() {
        buffer = ""
    }

    func toString() -> String {
        return buffer
    }
}
