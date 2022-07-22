//
//  BlockHash.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import Foundation
import Base58Swift

public struct BlockHash: BorshCodable, CustomStringConvertible {
    public static let fixedLength: Int = 32
    public let data: Data
    
    public init(encodedString: String) throws {
        let data = encodedString.base58DecodedData
        guard !data.isEmpty else {
            throw NearError.decodingError
        }
        self.data = data
    }
    public init(data: Data) {
      self.data = data
    }
    
    public func serialize(to writer: inout Data) throws {
        writer.append(data.bytes, count: Self.fixedLength)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.data = Data(reader.read(count: UInt32(Self.fixedLength)))
    }
    
    public var description: String {
        return data.bytes.base58EncodedString
    }
}
