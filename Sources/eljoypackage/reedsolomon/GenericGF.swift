//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class GenericGF {
    private let primitive: Int
    let size: Int
    private var expTable: [Int]?
    private var logTable: [Int]?
    private var zero: GenericGFPoly?
    private var one: GenericGFPoly?
    private var initialized = false

    init(primitive: Int, size: Int) {
        self.primitive = primitive
        self.size = size
        if size <= GenericGF.INITIALIZATION_THRESHOLD {
            initialize()
        }
    }

    private func initialize() {
        var expTable = [Int](repeating: 0, count: size)
        var logTable = [Int](repeating: 0, count: size)
        var x = 1
        for i in 0..<size {
            expTable[i] = x
            x = x << 1
            if x >= size {
                x = x ^ primitive
                x = x & (size - 1)
            }
        }
        for i in 0..<(size - 1) {
            logTable[expTable[i]] = i
        }
        zero = GenericGFPoly(field: self, coefficients: [0])
        one = GenericGFPoly(field: self, coefficients: [1])
        initialized = true
    }

    private func checkInit() {
        if !initialized {
            initialize()
        }
    }

    func getZero() -> GenericGFPoly {
        checkInit()
        return zero!
    }

    func getOne() -> GenericGFPoly {
        checkInit()
        return one!
    }

    func buildMonomial(degree: Int, coefficient: Int) -> GenericGFPoly {
        checkInit()
        assert(degree >= 0)
        if coefficient == 0 {
            return zero!
        }
        var coefficients = [Int](repeating: 0, count: degree + 1)
        coefficients[0] = coefficient
        return GenericGFPoly(field: self, coefficients: coefficients)
    }

    func exp(_ a: Int) -> Int {
        checkInit()
        return expTable![a]
    }

    func log(_ a: Int) -> Int {
        checkInit()
        assert(a != 0)
        return logTable![a]
    }

    func inverse(_ a: Int) -> Int {
        checkInit()
        if a == 0 {
            // Throw an exception in Swift
            fatalError("ArithmeticException")
        }
        return expTable![size - logTable![a] - 1]
    }

    func multiply(_ a: Int, _ b: Int) -> Int {
        checkInit()
        if a == 0 || b == 0 {
            return 0
        }
        return expTable![(logTable![a] + logTable![b]) % (size - 1)]
    }

    static let AZTEC_DATA_12 = GenericGF(primitive: 0x1069, size: 4096)
    static let AZTEC_DATA_10 = GenericGF(primitive: 0x409, size: 1024)
    static let AZTEC_DATA_6 = GenericGF(primitive: 0x43, size: 64)
    static let AZTEC_PARAM = GenericGF(primitive: 0x13, size: 16)
    static let QR_CODE_FIELD_256 = GenericGF(primitive: 0x011D, size: 256)
    static let DATA_MATRIX_FIELD_256 = GenericGF(primitive: 0x012D, size: 256)
    static let AZTEC_DATA_8 = DATA_MATRIX_FIELD_256
    static let MAXICODE_FIELD_64 = AZTEC_DATA_6
    private static let INITIALIZATION_THRESHOLD = 0

    static func addOrSubtract(_ a: Int, _ b: Int) -> Int {
        return a ^ b
    }
}

