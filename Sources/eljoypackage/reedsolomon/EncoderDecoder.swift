//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

/**
 * Purpose: to provide a simple class for encoding and decoding/repairing
 * data using Reed-Solomon forward error correction codes.
 * Data can only be encoded/decoded in 256 byte chunks, which is a limitation
 * of the Reed-Solomon classes that this class wraps
 *
 * Author: Blake Hamilton <blake.a.hamilton@gmail.com>
 * http://www.casual-coding.blogspot.com/
 * Version: 1.0
 */
internal class EncoderDecoder {
    private let decoder: ReedSolomonDecoder = ReedSolomonDecoder(field: GenericGF.QR_CODE_FIELD_256)
    private let encoder: ReedSolomonEncoder = ReedSolomonEncoder(field: GenericGF.QR_CODE_FIELD_256)

    /**
     * Encodes the supplied byte array, generating and appending the supplied number of error correction bytes to be used.
     *
     * - Parameters:
     *   - data: The bytes to be encoded
     *   - numErrorCorrectionBytes: The number of error correction bytes to be generated from the user-supplied data
     *
     * - Returns: The encoded bytes, where the size of the encoded data is the original size + the number of bytes used for error correction
     *
     * - Throws:
     *   - DataTooLargeError if the total size of data supplied by the user to be encoded, plus the number of error
     * correction bytes, is greater than 256 bytes
     */
    @discardableResult
    func encodeData(data: [UInt8], numErrorCorrectionBytes: Int) throws -> [UInt8] {
        guard !data.isEmpty else {
            return []
        }

        if data.count + numErrorCorrectionBytes > 256 {
            throw DataTooLargeError.dataTooLarge(message: "Data Length + Number of error correction bytes cannot exceed 256 bytes")
        }

        let totalBytes = numErrorCorrectionBytes + data.count
        var dataInts = [Int](repeating: 0, count: totalBytes)
        for i in 0..<data.count {
            dataInts[i] = Int(data[i]) & 0xFF
        }

        encoder.encode(toEncode: &dataInts, ecBytes: numErrorCorrectionBytes)

        var encodedData = [UInt8]()
        for i in dataInts {
            encodedData.append(UInt8(i))
        }

        return encodedData
    }

    /**
     * Repairs and decodes the supplied byte array, removing the error correction codes and returning the original data.
     *
     * - Parameters:
     *   - data: The bytes to be repaired/decoded
     *   - numErrorCorrectionBytes: The number of error correction bytes present in the encoded data. If this field is incorrect, the encoded data may not be able to be repaired/encoded
     *
     * - Returns: The decoded/repaired data. The returned byte array will be N bytes shorter than the supplied
     * encoded data, where N equals the number of error correction bytes within the encoded byte array
     *
     * - Throws:
     *   - ReedSolomonError if the data is not able to be repaired/decoded
     *   - DataTooLargeError if the supplied byte array is greater than 256 bytes
     */
    @discardableResult
    func decodeData(data: [UInt8], numErrorCorrectionBytes: Int) throws -> [UInt8] {
        guard !data.isEmpty else {
            return []
        }

        if data.count > 256 {
            throw DataTooLargeError.dataTooLarge(message: "Data exceeds 256 bytes! Too large")
        }

        var dataInts = [Int](repeating: 0, count: data.count)
        for i in 0..<data.count {
            dataInts[i] = Int(data[i]) & 0xFF
        }

        let totalBytes = data.count - numErrorCorrectionBytes
        try decoder.decode(received: &dataInts, twoS: numErrorCorrectionBytes)

        var decodedData = [UInt8]()
        for i in 0..<totalBytes {
            decodedData.append(UInt8(dataInts[i]))
        }

        return decodedData
    }
}

