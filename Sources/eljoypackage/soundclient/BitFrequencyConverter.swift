//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

class BitFrequencyConverter {
    private let startFrequency: Int
    private var endFrequency: Int
    private let numberOfBitsInOneTone: Int
    
    var padding: Int {
        return (endFrequency - startFrequency) / (4 + Int(pow(2.0, Double(numberOfBitsInOneTone))))
    }
    
    var handshakeStartFreq: Int {
        return endFrequency - padding
    }
    
    var handshakeEndFreq: Int {
        return endFrequency
    }
    
    private var readBytes: [UInt8] = []
    private var currByte: UInt8 = 0x00
    private var currShift = 0
    
    init(startFrequency: Int, endFrequency: Int, numberOfBitsInOneTone: Int) {
        self.startFrequency = startFrequency
        self.endFrequency = endFrequency
        self.numberOfBitsInOneTone = numberOfBitsInOneTone
        self.endFrequency -= 2 * padding
    }
    
    func calculateBits(frequency: Double) {
        var resultBytes: UInt8 = 0x00
        var freqFound = false
        var lastPart = false
        var counter = 0
        var i = startFrequency
        
        while i <= endFrequency {
            if frequency >= Double(i - padding / 2) && frequency <= Double(i + padding / 2) {
                if counter == 0 || counter == 1 {
                    lastPart = true
                } else {
                    freqFound = true
                }
                break
            } else {
                if counter != 0 && counter != 1 {
                    resultBytes += 0x01
                }
            }
            i += padding
            counter += 1
        }
        
        if freqFound {
            var tempCounter = numberOfBitsInOneTone
            while tempCounter > 0 {
                var mask: UInt8 = 0x01
                mask = mask << (tempCounter - 1)
                currByte = currByte << 1
                if mask & resultBytes != 0x00 {
                    currByte += 0x01
                }
                currShift += 1
                if currShift == 8 {
                    readBytes.append(currByte)
                    currShift = 0
                    currByte = 0x00
                }
                tempCounter -= 1
            }
        } else {
            if lastPart {
                currByte = currByte << 1
                if counter == 1 {
                    currByte += 0x01
                }
                currShift += 1
                if currShift == 8 {
                    readBytes.append(currByte)
                    currByte = 0x00
                    currShift = 0
                }
            }
        }
    }
    
    func getAndResetReadBytes() -> [UInt8] {
        var retArr: [UInt8]
        if currShift != 0 {
            retArr = readBytes + [currByte]
        } else {
            retArr = readBytes
        }
        readBytes.removeAll()
        currByte = 0x00
        currShift = 0
        return retArr
    }
    
    private func specificFrequency(sample: UInt8) -> Int {
        var freq = startFrequency + padding * 2
        let numberOfFreq = Int(pow(2.0, Double(numberOfBitsInOneTone)))
        var tempByte: UInt8 = 0x00
        
        for _ in 0..<numberOfFreq {
            if tempByte == sample {
                break
            }
            tempByte += 0x01
            freq += padding
        }
        return freq
    }
    
    private func getBit(check: UInt8, position: Int) -> Int {
        return (Int(check) >> position) & 1
    }
    
    func calculateFrequency(byteArray: [UInt8]) -> [Int] {
        var resultList: [Int] = []
        let isDataModulo = byteArray.count * 8 % numberOfBitsInOneTone == 0
        var currByte: UInt8 = 0x00
        var currShift = 0
        
        for i in 0..<byteArray.count {
            let tempByte = byteArray[i]
            
            for j in (0..<8).reversed() {
                if currShift + j + 1 + (byteArray.count - (i + 1)) * 8 < numberOfBitsInOneTone && !isDataModulo {
                    let temp = getBit(check: tempByte, position: j)
                    if temp == 1 {
                        resultList.append(startFrequency + padding)
                    } else {
                        resultList.append(startFrequency)
                    }
                    continue
                }
                
                let temp = getBit(check: tempByte, position: j)
                currByte = currByte << 1
                if temp == 1 {
                    currByte += 0x01
                }
                currShift += 1
                
                if currShift == numberOfBitsInOneTone {
                    let currFreq = specificFrequency(sample: currByte)
                    resultList.append(currFreq)
                    currByte = 0x00
                    currShift = 0
                }
            }
        }
        return resultList
    }
}

