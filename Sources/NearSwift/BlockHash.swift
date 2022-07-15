//
//  BlockHash.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import Foundation

public struct BlockHash: BorshCodable, CustomStringConvertible {
    public static let fixedLength: Int = 32
    public let data: Data
    
    public init(encodedString: String) throws {
        guard let _data = encodedString.base58Decoded else {
            throw NearError.decodingError
        }
        self.data = _data
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
        return data.base58Encoded
    }
}
