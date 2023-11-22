//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class GenericGFPoly {
    private let field: GenericGF
    let coefficients: [Int]

    init(field: GenericGF, coefficients: [Int]) {
        precondition(!coefficients.isEmpty, "Coefficients must not be empty")
        self.field = field

        let coefficientsLength = coefficients.count

        if coefficientsLength > 1 && coefficients[0] == 0 {
            var firstNonZero = 1
            while firstNonZero < coefficientsLength && coefficients[firstNonZero] == 0 {
                firstNonZero += 1
            }

            if firstNonZero == coefficientsLength {
                self.coefficients = field.getZero().coefficients
            } else {
                self.coefficients = Array(coefficients[firstNonZero..<coefficientsLength])
            }
        } else {
            self.coefficients = coefficients
        }
    }

    var degree: Int {
        return coefficients.count - 1
    }

    var isZero: Bool {
        return coefficients[0] == 0
    }

    func getCoefficient(degree: Int) -> Int {
        return coefficients[coefficients.count - 1 - degree]
    }

    func evaluateAt(a: Int) -> Int {
        switch a {
        case 0:
            return getCoefficient(degree: 0)
        case 1:
            var result = 0
            for coefficient in coefficients {
                result = GenericGF.addOrSubtract(result, coefficient)
            }
            return result
        default:
            var result = coefficients[0]
            for i in 1..<coefficients.count {
                result = GenericGF.addOrSubtract(field.multiply(a, result), coefficients[i])
            }
            return result
        }
    }

    func addOrSubtract(_ other: GenericGFPoly) -> GenericGFPoly {
        precondition(field as! AnyHashable == other.field as! AnyHashable, "GenericGFPolys do not have the same GenericGF field")
        if isZero {
            return other
        }
        if other.isZero {
            return self
        }

        var smallerCoefficients = coefficients
        var largerCoefficients = other.coefficients

        if smallerCoefficients.count > largerCoefficients.count {
            let temp = smallerCoefficients
            smallerCoefficients = largerCoefficients
            largerCoefficients = temp
        }

        var sumDiff = [Int](repeating: 0, count: largerCoefficients.count)
        let lengthDiff = largerCoefficients.count - smallerCoefficients.count

        // Copy high-order terms only found in higher-degree polynomial's coefficients
        sumDiff[0..<lengthDiff] = largerCoefficients[0..<lengthDiff]

        for i in lengthDiff..<largerCoefficients.count {
            sumDiff[i] = GenericGF.addOrSubtract(smallerCoefficients[i - lengthDiff], largerCoefficients[i])
        }

        return GenericGFPoly(field: field, coefficients: sumDiff)
    }

    func multiply(_ other: GenericGFPoly) -> GenericGFPoly {
        precondition(field as! AnyHashable == other.field as! AnyHashable, "GenericGFPolys do not have the same GenericGF field")
        if isZero || other.isZero {
            return field.getZero()
        }

        var product = [Int](repeating: 0, count: coefficients.count + other.coefficients.count - 1)

        for i in 0..<coefficients.count {
            for j in 0..<other.coefficients.count {
                product[i + j] = GenericGF.addOrSubtract(
                    product[i + j],
                    field.multiply(coefficients[i], other.coefficients[j])
                )
            }
        }

        return GenericGFPoly(field: field, coefficients: product)
    }

    func multiply(scalar: Int) -> GenericGFPoly {
        if scalar == 0 {
            return field.getZero()
        }

        if scalar == 1 {
            return self
        }

        let size = coefficients.count
        var product = [Int](repeating: 0, count: size)

        for i in 0..<size {
            product[i] = field.multiply(coefficients[i], scalar)
        }

        return GenericGFPoly(field: field, coefficients: product)
    }

    func multiplyByMonomial(degree: Int, coefficient: Int) -> GenericGFPoly {
        precondition(degree >= 0)

        if coefficient == 0 {
            return field.getZero()
        }

        var product = [Int](repeating: 0, count: coefficients.count + degree)

        for i in 0..<coefficients.count {
            product[i] = field.multiply(coefficients[i], coefficient)
        }

        return GenericGFPoly(field: field, coefficients: product)
    }

    func divide(other: GenericGFPoly) -> [GenericGFPoly] {
        precondition(field as! AnyHashable == other.field as! AnyHashable, "GenericGFPolys do not have the same GenericGF field")
        precondition(!other.isZero, "Divide by 0")

        var quotient = field.getZero()
        var remainder: GenericGFPoly = self
        let denominatorLeadingTerm = other.getCoefficient(degree: other.degree)
        let inverseDenominatorLeadingTerm = field.inverse(denominatorLeadingTerm)

        while remainder.degree >= other.degree && !remainder.isZero {
            let degreeDifference = remainder.degree - other.degree
            let scale = field.multiply(remainder.getCoefficient(degree: remainder.degree), inverseDenominatorLeadingTerm)
            let term = other.multiplyByMonomial(degree: degreeDifference, coefficient: scale)
            let iterationQuotient = field.buildMonomial(degree: degreeDifference, coefficient: scale)
            quotient = quotient.addOrSubtract(iterationQuotient)
            remainder = remainder.addOrSubtract(term)
        }

        return [quotient, remainder]
    }

    var description: String {
        var result = ""
        let zeroCoefficient = getCoefficient(degree: 0)
        if isZero && zeroCoefficient == 0 {
            result = "0"
        } else {
            for degree in (0...degree).reversed() {
                let coefficient = getCoefficient(degree: degree)
                if coefficient == 0 {
                    continue
                }

                if coefficient < 0 {
                    result += " - "
                    result += String(-coefficient)
                } else if !result.isEmpty {
                    result += " + "
                    result += String(coefficient)
                }

                switch field.log(coefficient) {
                case 0:
                    result += "1"
                case 1:
                    result += "a"
                default:
                    result += "a^\(field.log(coefficient))"
                }

                if degree > 0 {
                    result += (degree == 1) ? "x" : "x^\(degree)"
                }
            }
        }
        return result
    }
}

