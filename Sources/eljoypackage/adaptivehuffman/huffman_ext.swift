//
//  File.swift
//  
//
//  Created by Mac on 11/5/23.
//

import Foundation

extension Int {
    func isPowerOf2() -> Bool {
        return self > 0 && (self & (self - 1)) == 0
    }
}
