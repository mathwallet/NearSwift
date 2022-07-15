//
//  Borsh.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import Foundation

public typealias BorshCodable = BorshSerializable & BorshDeserializable

public enum BorshDecodingError: LocalizedError {
    case unknownData
    
    public var errorDescription: String? {
        switch self {
        case .unknownData:
            return "Unknown Data"
        }
    }
    
}
