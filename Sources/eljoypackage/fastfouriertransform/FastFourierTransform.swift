//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

internal class FastFourierTransform {
    // compute the FFT of x[], assuming its length is a power of 2
    static func fft(x: [Complex?]) -> [Complex?] {
        let n = x.count

        // base case
        if n == 1 {
            return [x[0]]
        }

        // radix 2 Cooley-Tukey FFT
        precondition(n % 2 == 0, "n is not a power of 2")

        // fft of even terms
        var even = [Complex?](repeating: nil, count: n / 2)
        for k in 0..<n / 2 {
            even[k] = x[2 * k]
        }
        let q = fft(x: even)

        // fft of odd terms
        for k in 0..<n / 2 {
            even[k] = x[2 * k + 1]
        }
        let r = fft(x: even)

        // combine
        var y = [Complex?](repeating: nil, count: n)
        for k in 0..<n / 2 {
            let kth = -2 * Double(k) * Double.pi / Double(n)
            let wk = Complex(real: Darwin.cos(kth), imaginary: Darwin.sin(kth))
            y[k] = q[k]! + wk.times(r[k]!)
            y[k + n / 2] = q[k]! - wk.times(r[k]!)
        }
        return y
    }

    // compute the inverse FFT of x[], assuming its length is a power of 2
    static func ifft(x: [Complex?]) -> [Complex?] {
        let n = x.count
        var y = [Complex?](repeating: nil, count: n)

        // take conjugate
        for i in 0..<n {
            y[i] = x[i]!.conjugate()
        }

        // compute forward FFT
        y = fft(x: y)

        // take conjugate again
        for i in 0..<n {
            y[i] = y[i]!.conjugate()
        }

        // divide by n
        for i in 0..<n {
            y[i] = y[i]!.scale(1.0 / Double(n))
        }
        return y
    }

    // compute the circular convolution of x and y
    static func cconvolve(x: [Complex?], y: [Complex?]) -> [Complex?] {
        // should probably pad x and y with 0s so that they have the same length
        // and are powers of 2
        precondition(x.count == y.count, "Dimensions don't agree")
        let n = x.count

        // compute FFT of each sequence
        let a = fft(x: x)
        let b = fft(x: y)

        // point-wise multiply
        var c = [Complex?](repeating: nil, count: n)
        for i in 0..<n {
            c[i] = a[i]!.times(b[i]!)
        }

        // compute inverse FFT
        return ifft(x: c)
    }

    // compute the linear convolution of x and y
    static func convolve(x: [Complex?], y: [Complex?]) -> [Complex?] {
        let zero = Complex(real: 0.0, imaginary: 0.0)
        var a = [Complex?](repeating: nil, count: 2 * x.count)
        for i in x.indices {
            a[i] = x[i]
        }
        for i in x.count..<2 * x.count {
            a[i] = zero
        }
        var b = [Complex?](repeating: nil, count: 2 * y.count)
        for i in y.indices {
            b[i] = y[i]
        }
        for i in y.count..<2 * y.count {
            b[i] = zero
        }
        return cconvolve(x: a, y: b)
    }
    
}

