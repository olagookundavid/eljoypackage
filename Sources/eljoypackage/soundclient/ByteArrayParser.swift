//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

class ByteArrayParser {
    private var outputByteArray: Data?
    
    private func concatenateTwoArrays(array1: Data, array2: Data) -> Data {
        var joinedArray = Data()
        joinedArray.append(array1)
        joinedArray.append(array2)
        return joinedArray
    }
    
    func divideInto256Chunks(input: Data, errorDetectionNumber: Int) -> [Data] {
        var tempList = [Data]()
        var startPos = 0
        var endPos = 256 - errorDetectionNumber
        var bytesLeft = input.count
        
        while bytesLeft + errorDetectionNumber > 256 {
            let tempRange = startPos..<endPos
            let tempChunk = input.subdata(in: tempRange)
            tempList.append(tempChunk)
            
            startPos = endPos
            endPos = startPos + 256 - errorDetectionNumber
            bytesLeft -= 256 - errorDetectionNumber
        }
        
        let tempRange = startPos..<input.count
        let tempChunk = input.subdata(in: tempRange)
        tempList.append(tempChunk)
        
        return tempList
    }
    
    func mergeArray(inputArray: Data) {
        outputByteArray = (outputByteArray != nil) ? concatenateTwoArrays(array1: outputByteArray!, array2: inputArray) : inputArray
    }
    
    func getAndResetOutputByteArray() -> Data? {
        let result = outputByteArray
        outputByteArray = nil
        return result
    }
}

