//
//  Permission.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import Foundation
import BigInt

public struct FunctionCallPermission {
    public let allowance: UInt128?
    public let receiverId: String
    public let methodNames: [String]
    
    public init(allowance: UInt128? = nil, receiverId: String, methodNames: [String]) {
        self.allowance = allowance
        self.receiverId = receiverId
        self.methodNames = methodNames
    }
}

extension FunctionCallPermission: HumanReadable {
    public func toHuman() -> Any {
        if let _allowance = allowance {
            return [
                "allowance": _allowance.toString(),
                "receiverId": receiverId,
                "methodNames": methodNames
            ]
        }
        return [
            "receiverId": receiverId,
            "methodNames": methodNames
        ]
    }
}

extension FunctionCallPermission: Decodable {
    private enum CodingKeys: String, CodingKey {
      case allowance, receiverId, methodNames
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let allowanceLiteral = try container.decode(String?.self, forKey: .allowance)
      allowance = allowanceLiteral != nil ? UInt128(stringLiteral: allowanceLiteral!) : nil
      receiverId = try container.decode(String.self, forKey: .receiverId)
      methodNames = try container.decode([String].self, forKey: .methodNames)
    }
}

extension FunctionCallPermission: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try allowance.serialize(to: &writer)
        try receiverId.serialize(to: &writer)
        try methodNames.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.allowance = try .init(from: &reader)
        self.receiverId = try .init(from: &reader)
        self.methodNames = try .init(from: &reader)
    }
}

public struct FullAccessPermission {}

extension FullAccessPermission: HumanReadable {
    public func toHuman() -> Any {
        return "FullAccess"
    }
}

extension FullAccessPermission: BorshCodable {
  public func serialize(to writer: inout Data) throws {}

  public init(from reader: inout BinaryReader) throws {
    self.init()
  }
}

public enum AccessKeyPermission {
    case functionCall(FunctionCallPermission)
    case fullAccess(FullAccessPermission)
    
    var rawValue: UInt8 {
        switch self {
        case .functionCall: return 0
        case .fullAccess: return 1
        }
    }
}

extension AccessKeyPermission: HumanReadable {
    public func toHuman() -> Any {
        switch self {
        case .functionCall(let functionCallPermission):
            return functionCallPermission.toHuman()
        case .fullAccess(let fullAccessPermission):
            return fullAccessPermission.toHuman()
        }
    }
}

extension AccessKeyPermission: Decodable {
    private enum CodingKeys: String, CodingKey {
      case functionCall = "FunctionCall"
    }
    
    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            let value = try? container.decode(String.self)
            if value == "FullAccess" {
              self = .fullAccess(FullAccessPermission())
              return
            }
        }
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let permission = try container.decode(FunctionCallPermission.self, forKey: .functionCall)
            self = .functionCall(permission)
        } else {
            throw NearError.decodingError
        }
    }
}

extension AccessKeyPermission: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try rawValue.serialize(to: &writer)
        switch self {
        case .functionCall(let permission): try permission.serialize(to: &writer)
        case .fullAccess(let permission): try permission.serialize(to: &writer)
        }
    }

    public init(from reader: inout BinaryReader) throws {
        let rawValue = try UInt8(from: &reader)
        switch rawValue {
        case 0: self = .functionCall(try FunctionCallPermission(from: &reader))
        case 1: self = .fullAccess(try FullAccessPermission(from: &reader))
        default: fatalError()
        }
    }
}

public struct AccessKey: Decodable {
    public var nonce: UInt64
    public let permission: AccessKeyPermission
    
    public init(nonce: UInt64, permission: AccessKeyPermission) {
        self.nonce = nonce
        self.permission = permission
    }
    
    public static func fullAccessKey() -> AccessKey {
        return AccessKey(nonce: 0, permission: .fullAccess(FullAccessPermission()))
    }
    
    public static func functionCallAccessKey(receiverId: String, methodNames: [String], allowance: UInt128?) -> AccessKey {
      let callPermission = FunctionCallPermission(allowance: allowance, receiverId: receiverId, methodNames: methodNames)
      return AccessKey(nonce: 0, permission: .functionCall(callPermission))
    }
}

extension AccessKey: HumanReadable {
    public func toHuman() -> Any {
        return [
            "nonce": nonce,
            "permission": permission.toHuman()
        ]
    }
}

extension AccessKey {
    public func serialize(to writer: inout Data) throws {
        try nonce.serialize(to: &writer)
        try permission.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.nonce = try .init(from: &reader)
        self.permission = try .init(from: &reader)
    }
}
