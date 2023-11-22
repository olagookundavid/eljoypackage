//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class ReedSolomonEncoder {
    private let field: GenericGF
    private var cachedGenerators: [GenericGFPoly] = []

    init(field: GenericGF) {
        precondition(GenericGF.QR_CODE_FIELD_256 === field, "Only QR Code is supported at this time")
        cachedGenerators.append(GenericGFPoly(field: field, coefficients: [1]))
        self.field = field
    }

    private func buildGenerator(degree: Int) -> GenericGFPoly {
        if degree >= cachedGenerators.count {
            var lastGenerator = cachedGenerators[cachedGenerators.count - 1]
            for d in cachedGenerators.count...degree {
                let nextGenerator = lastGenerator.multiply(GenericGFPoly(field: field, coefficients: [1, field.exp(d - 1)]))
                cachedGenerators.append(nextGenerator)
                lastGenerator = nextGenerator
            }
        }
        return cachedGenerators[degree]
    }

    func encode(toEncode: inout [Int], ecBytes: Int) {
        precondition(ecBytes != 0, "No error correction bytes")
        let dataBytes = toEncode.count - ecBytes
        precondition(dataBytes > 0, "No data bytes provided")
        let generator = buildGenerator(degree: ecBytes)
        let infoCoefficients = Array(toEncode[0..<dataBytes])
        var info = GenericGFPoly(field: field, coefficients: infoCoefficients)
        info = info.multiplyByMonomial(degree: ecBytes, coefficient: 1)
        let remainder = info.divide(other: generator)[1]
        var coefficients = remainder.coefficients
        let numZeroCoefficients = ecBytes - coefficients.count
        for i in 0..<numZeroCoefficients {
            toEncode[dataBytes + i] = 0
        }
        toEncode.replaceSubrange(dataBytes + numZeroCoefficients..<toEncode.endIndex, with: coefficients)
    }
}

