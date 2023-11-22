//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation
internal class ReedSolomonException: Error {
    let message: String

    init(message: String) {
        self.message = message
    }
}
