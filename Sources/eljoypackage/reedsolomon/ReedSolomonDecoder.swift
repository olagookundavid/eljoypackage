//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class ReedSolomonDecoder {
    let field: GenericGF

    init(field: GenericGF) {
        self.field = field
    }

    func decode(received: inout [Int], twoS: Int) throws {
        let poly = GenericGFPoly(field: field, coefficients: received)
        var syndromeCoefficients = [Int](repeating: 0, count: twoS)
        let dataMatrix = field === GenericGF.DATA_MATRIX_FIELD_256
        var noError = true

        for i in 0..<twoS {
            let eval = poly.evaluateAt(a: field.exp(dataMatrix ? (i + 1) : i))
            syndromeCoefficients[syndromeCoefficients.count - 1 - i] = eval
            if eval != 0 {
                noError = false
            }
        }

        if noError {
            return
        }

        let syndrome = GenericGFPoly(field: field, coefficients: syndromeCoefficients)
        let sigmaOmega = try runEuclideanAlgorithm(a: field.buildMonomial(degree: twoS, coefficient: 1), b: syndrome, R: twoS)
        let sigma = sigmaOmega[0]
        let omega = sigmaOmega[1]
        let errorLocations = try findErrorLocations(errorLocator: sigma)
        let errorMagnitudes = findErrorMagnitudes(errorEvaluator: omega, errorLocations: errorLocations, dataMatrix: dataMatrix)

        for i in 0..<errorLocations.count {
            let position = received.count - 1 - field.log(errorLocations[i])
            if position < 0 {
                throw ReedSolomonException(message: "Bad error location")
            }
            received[position] = GenericGF.addOrSubtract(received[position], errorMagnitudes[i])
        }
    }

    private func runEuclideanAlgorithm(a: GenericGFPoly, b: GenericGFPoly, R: Int) throws -> [GenericGFPoly] {
        var a = a
        var b = b

        if a.degree < b.degree {
            let temp = a
            a = b
            b = temp
        }

        var rLast = a
        var r = b
        var tLast = field.getZero()
        var t = field.getOne()

        while r.degree >= R / 2 {
            let rLastLast = rLast
            let tLastLast = tLast
            rLast = r
            tLast = t

            if rLast.isZero {
                throw ReedSolomonException(message: "r_{i-1} was zero")
            }

            r = rLastLast
            var q = field.getZero()
            let denominatorLeadingTerm = rLast.getCoefficient(degree: rLast.degree)
            let dltInverse = field.inverse(denominatorLeadingTerm)

            while r.degree >= rLast.degree && !r.isZero {
                let degreeDiff = r.degree - rLast.degree
                let scale = field.multiply(r.getCoefficient(degree: r.degree), dltInverse)
                q = q.addOrSubtract(field.buildMonomial(degree: degreeDiff, coefficient: scale))
                r = r.addOrSubtract(rLast.multiplyByMonomial(degree: degreeDiff, coefficient: scale))
            }

            t = q.multiply(tLast).addOrSubtract(tLastLast)
        }

        let sigmaTildeAtZero = t.getCoefficient(degree: 0)

        if sigmaTildeAtZero == 0 {
            throw ReedSolomonException(message: "sigmaTilde(0) was zero")
        }

        let inverse = field.inverse(sigmaTildeAtZero)
        let sigma = t.multiply(scalar: inverse)
        let omega = r.multiply(scalar: inverse)

        return [sigma, omega]
    }

    private func findErrorLocations(errorLocator: GenericGFPoly) throws -> [Int] {
        let numErrors = errorLocator.degree

        if numErrors == 1 {
            return [errorLocator.getCoefficient(degree: 1)]
        }

        var result = [Int]()
        var e = 0
        var i = 1

        while i < field.size && e < numErrors {
            if errorLocator.evaluateAt(a: i) == 0 {
                result.append(field.inverse(i))
                e += 1
            }
            i += 1
        }

        if e != numErrors {
            throw ReedSolomonException(message: "Error locator degree does not match number of roots")
        }

        return result
    }

    private func findErrorMagnitudes(errorEvaluator: GenericGFPoly, errorLocations: [Int], dataMatrix: Bool) -> [Int] {
        let s = errorLocations.count
        var result = [Int]()

        for i in 0..<s {
            let xiInverse = field.inverse(errorLocations[i])
            var denominator = 1

            for j in 0..<s {
                if i != j {
                    let term = field.multiply(errorLocations[j], xiInverse)
                    let termPlus1 = (term & 0x1 == 0) ? (term | 1) : (term & ~1)
                    denominator = field.multiply(denominator, termPlus1)
                }
            }

            result.append(field.multiply(errorEvaluator.evaluateAt(a: xiInverse), field.inverse(denominator)))

            if dataMatrix {
                result[i] = field.multiply(result[i], xiInverse)
            }
        }

        return result
    }
}

