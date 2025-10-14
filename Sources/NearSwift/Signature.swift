//
//  Signature.swift
//  
//
//  Created by mathwallet on 2022/7/13.
//

import Foundation
import Base58Swift

public struct Signature {
    public let data: Data
    public let keyType: KeyType
}

extension Signature: CustomStringConvertible {
    public var description: String {
        return "\(keyType.rawValue):\(data.byteArray.base58EncodedString)"
    }
}

extension Signature: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.data == rhs.data && lhs.keyType == rhs.keyType
    }
}

extension Signature: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try keyType.serialize(to: &writer)
        switch keyType {
        case .ED25519:
            writer.append(data.byteArray, count: 64)
        case .SECP256k1:
            writer.append(data.byteArray, count: 65)
        }
    }

    public init(from reader: inout BinaryReader) throws {
        self.keyType = try .init(from: &reader)
        switch keyType {
        case .ED25519:
            self.data = Data(reader.read(count: 64))
        case .SECP256k1:
            self.data = Data(reader.read(count: 65))
        }
    }
}
