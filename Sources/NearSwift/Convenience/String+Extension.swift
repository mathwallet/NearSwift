//
//  Serialize.swift
//  
//
//  Created by mathwallet on 2022/7/13.
//

import Foundation
import Base58Swift
import CryptoSwift

extension String {
    var base58Decoded: Data? {
        guard let decoded = Base58.base58Decode(self) else {
            return nil
        }
        return Data(decoded)
    }
}
