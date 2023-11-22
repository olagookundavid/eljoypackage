//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal struct Complex {
    let real: Double
    let imaginary: Double

    // Return the absolute value (magnitude) of the complex number.
    func abs() -> Double {
        return hypot(real, imaginary)
    }

    // Return the phase (argument) of the complex number, normalized to be between -pi and pi.
    func phase() -> Double {
        return atan2(imaginary, real)
    }

    // Return a new Complex object whose value is (this + b).
    func plus(_ b: Complex) -> Complex {
        let a = self
        let real = a.real + b.real
        let imaginary = a.imaginary + b.imaginary
        return Complex(real: real, imaginary: imaginary)
    }

    // Return a new Complex object whose value is (this - b).
    func minus(_ b: Complex) -> Complex {
        let a = self
        let real = a.real - b.real
        let imaginary = a.imaginary - b.imaginary
        return Complex(real: real, imaginary: imaginary)
    }

    // Return a new Complex object whose value is (this * b).
    func times(_ b: Complex) -> Complex {
        let a = self
        let real = a.real * b.real - a.imaginary * b.imaginary
        let imaginary = a.real * b.imaginary + a.imaginary * b.real
        return Complex(real: real, imaginary: imaginary)
    }

    // Return a new Complex object whose value is (this * alpha).
    func scale(_ alpha: Double) -> Complex {
        return Complex(real: alpha * real, imaginary: alpha * imaginary)
    }

    // Return a new Complex object whose value is the conjugate of this.
    func conjugate() -> Complex {
        return Complex(real: real, imaginary: -imaginary)
    }

    // Return a new Complex object whose value is the reciprocal of this.
    func reciprocal() -> Complex {
        let scale = real * real + imaginary * imaginary
        return Complex(real: real / scale, imaginary: -imaginary / scale)
    }

    // Return a / b.
    func divides(_ b: Complex) -> Complex {
        return times(b.reciprocal())
    }

    // Return a new Complex object whose value is the complex exponential of this.
    func exp() -> Complex {
        return Complex(
            real: Darwin.exp(real) * Darwin.cos(imaginary),
            imaginary: Darwin.exp(real) * Darwin.sin(imaginary)
        )
    }

    // Return a new Complex object whose value is the complex sine of this.
    func sin() -> Complex {
        return Complex(
            real: Darwin.sin(real) * Darwin.cosh(imaginary),
            imaginary: Darwin.cos(real) * Darwin.sinh(imaginary)
        )
    }

    // Return a new Complex object whose value is the complex cosine of this.
    func cos() -> Complex {
        return Complex(
            real: Darwin.cos(real) * Darwin.cosh(imaginary),
            imaginary: -Darwin.sin(real) * Darwin.sinh(imaginary)
        )
    }

    // Return a new Complex object whose value is the complex tangent of this.
    func tan() -> Complex {
        return sin().divides(cos())
    }

    // Return a string representation of the complex number.
    func toString() -> String {
        if imaginary == 0.0 {
            return "\(real)"
        } else if real == 0.0 {
            return "\(imaginary)i"
        } else if imaginary < 0 {
            return "\(real) - \(-imaginary)i"
        } else {
            return "\(real) + \(imaginary)i"
        }
    }
    // Custom addition operator for Complex numbers
    static func +(lhs: Complex, rhs: Complex) -> Complex {
        return Complex(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
    }

    // Custom subtraction operator for Complex numbers
    static func -(lhs: Complex, rhs: Complex) -> Complex {
        return Complex(real: lhs.real - rhs.real, imaginary: lhs.imaginary - rhs.imaginary)
    }

}

