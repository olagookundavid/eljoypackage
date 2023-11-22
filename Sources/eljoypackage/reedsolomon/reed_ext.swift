//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

/**
 * Convert a hex string to a byte array
 */
internal extension String {
    func toBytes() -> [UInt8] {
        let len = self.count / 2
        var result = [UInt8](repeating: 0, count: len)
        for i in 0..<len {
            let startIndex = index(self.startIndex, offsetBy: 2 * i)
            let endIndex = index(startIndex, offsetBy: 2)
            let hexString = String(self[startIndex..<endIndex])
            if let byteValue = UInt8(hexString, radix: 16) {
                result[i] = byteValue
            }
        }
        return result
    }
}

/**
 * Convert a byte array to a hex string
 */
extension Collection where Element == UInt8 {
    func toHex() -> String {
        let result = self.reduce(into: "") { (hexString, byte) in
            appendHex(to: &hexString, byte: byte)
            if hexString.count > 0 && hexString.count % 4 == 0 {
                hexString.append(" ")
            }
        }
        return result
    }

    private func appendHex(to builder: inout String, byte: UInt8) {
        let hex = String(format: "%02X", byte)
        builder.append(hex)
    }
}

