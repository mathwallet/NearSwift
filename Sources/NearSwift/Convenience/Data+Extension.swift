//
//  Serialize.swift
//  
//
//  Created by mathwallet on 2022/7/13.
//

import Foundation
import Base58Swift
import CryptoSwift

extension Data {
    var base58Encoded: String {
        return Base58.base58Encode(self.bytes)
    }
}
