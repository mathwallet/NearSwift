//
//  PublicKey.swift
//  
//
//  Created by mathwallet on 2022/7/13.
//

import Foundation
import Base58Swift

public enum KeyType: String, BorshCodable, Equatable {
    case ED25519 = "ed25519"
    case SECP256k1 = "secp256k1"
    
    public func serialize(to writer: inout Data) throws {
        switch self {
        case .ED25519: return try UInt8(0).serialize(to: &writer)
        case .SECP256k1: return try UInt8(1).serialize(to: &writer)
        }
    }

    public init(from reader: inout BinaryReader) throws {
        let value = try UInt8(from: &reader)
        switch value {
        case 0: self = .ED25519
        case 1: self = .SECP256k1
        default: throw NearError.decodingError
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public struct PublicKey: CustomStringConvertible {
    public let keyType: KeyType
    public let data: Data
    
    public var rawData: Data {
        switch keyType {
        case .ED25519:
            return data
        case .SECP256k1:
            // inject the first byte back into the data, it will always be 0x04 since we always use SECP256K1_EC_UNCOMPRESSED
            return Data([0x04]) + data
        }
    }
    
    public init(keyType: KeyType, data: Data) throws {
        switch keyType {
        case .ED25519:
            guard data.count == 32 else { throw NearError.decodingError }
        case .SECP256k1:
            guard data.count == 64 else { throw NearError.decodingError }
        }
        self.keyType = keyType
        self.data = data
    }
    
    public init(encodedKey: String) throws {
        let parts = encodedKey.components(separatedBy: ":")
        switch parts.count {
        case 1:
            try self.init(keyType: .ED25519, data: parts[0].base58DecodedData)
        case 2:
            guard let keyType = KeyType(rawValue: parts[0]) else { throw NearError.decodingError }
            try self.init(keyType: keyType, data: parts[1].base58DecodedData)
        default:
            throw NearError.keyError("Invlaid encoded key format, must be <curve>:<encoded key>")
        }
    }
    
    public var description: String {
        return "\(keyType.rawValue):\(data.bytes.base58EncodedString)"
    }
}

extension PublicKey: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.keyType == rhs.keyType && lhs.data == rhs.data
    }
}

extension PublicKey: Decodable {
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), let value = try? container.decode(String.self) {
            self = try PublicKey(encodedKey: value)
        } else {
            throw NearError.notExpected
        }
    }
}

extension PublicKey: BorshCodable {

    public func serialize(to writer: inout Data) throws {
        try keyType.serialize(to: &writer)
        writer.append(data.bytes, count: Int(keyType == .ED25519 ? 32 : 64))
    }

    public init(from reader: inout BinaryReader) throws {
        self.keyType = try .init(from: &reader)
        self.data = Data(reader.read(count: keyType == .ED25519 ? 32 : 64))
    }
}
