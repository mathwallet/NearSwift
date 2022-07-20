//
//  Action.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import Foundation
import CryptoSwift

public protocol IAction {}

public struct CreateAccount: IAction {}

extension CreateAccount: HumanReadable {
    public func toHuman() -> Any {
        return [:]
    }
}

extension CreateAccount: BorshCodable {
    public func serialize(to writer: inout Data) throws {}

    public init(from reader: inout BinaryReader) throws {
        self.init()
    }
}

public struct DeployContract: IAction {
    public let code: [UInt8]
    
    public init(code: [UInt8]) {
        self.code = code
    }
}

extension DeployContract: HumanReadable {
    public func toHuman() -> Any {
        return [
            "code": code.toHexString()
        ]
    }
}

extension DeployContract: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try code.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        let code: [UInt8] = try .init(from: &reader)
        self.init(code: code)
    }
}

public struct FunctionCall: IAction {
    public let methodName: String
    public let args: [UInt8]
    public let gas: UInt64
    public let deposit: UInt128
    
    public init(methodName: String, args: [UInt8], gas: UInt64, deposit: UInt128) {
        self.methodName = methodName
        self.args = args
        self.gas = gas
        self.deposit = deposit
    }
}

extension FunctionCall: HumanReadable {
    public func toHuman() -> Any {
        return [
            "methodName": methodName,
            "args": args.toHexString(),
            "gas": gas,
            "deposit": deposit.toString()
        ]
    }
}

extension FunctionCall: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try methodName.serialize(to: &writer)
        try args.serialize(to: &writer)
        try gas.serialize(to: &writer)
        try deposit.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.methodName = try .init(from: &reader)
        self.args = try .init(from: &reader)
        self.gas = try .init(from: &reader)
        self.deposit = try .init(from: &reader)
    }
}

public struct Transfer: IAction {
  public let deposit: UInt128
    
    public init(deposit: UInt128) {
        self.deposit = deposit
    }
}

extension Transfer: HumanReadable {
    public func toHuman() -> Any {
        return [
            "deposit": deposit.toString()
        ]
    }
}

extension Transfer: BorshCodable {
  public func serialize(to writer: inout Data) throws {
    try deposit.serialize(to: &writer)
  }

  public init(from reader: inout BinaryReader) throws {
    self.deposit = try .init(from: &reader)
  }
}

public struct Stake: IAction {
    public let stake: UInt128
    public let publicKey: PublicKey
    
    public init(stake: UInt128, publicKey: PublicKey) {
        self.stake = stake
        self.publicKey = publicKey
    }
}

extension Stake: HumanReadable {
    public func toHuman() -> Any {
        return [
            "stake": stake.toString(),
            "publicKey": publicKey.description
        ]
    }
}

extension Stake: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try stake.serialize(to: &writer)
        try publicKey.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.stake = try .init(from: &reader)
        self.publicKey = try .init(from: &reader)
    }
}

public struct AddKey: IAction {
    public let publicKey: PublicKey
    public let accessKey: AccessKey
    
    public init(publicKey: PublicKey, accessKey: AccessKey) {
        self.publicKey = publicKey
        self.accessKey = accessKey
    }
}

extension AddKey: HumanReadable {
    public func toHuman() -> Any {
        return [
            "publicKey": publicKey.description,
            "accessKey": accessKey.toHuman()
        ]
    }
}

extension AddKey: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try publicKey.serialize(to: &writer)
        try accessKey.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.publicKey = try .init(from: &reader)
        self.accessKey = try .init(from: &reader)
    }
}

public struct DeleteKey: IAction {
    public let publicKey: PublicKey
    
    public init(publicKey: PublicKey) {
        self.publicKey = publicKey
    }
}

extension DeleteKey: HumanReadable {
    public func toHuman() -> Any {
        return [
            "publicKey": publicKey.description
        ]
    }
}

extension DeleteKey: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try publicKey.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.publicKey = try .init(from: &reader)
    }
}

public struct DeleteAccount: IAction {
    public let beneficiaryId: String
    
    public init(beneficiaryId: String) {
        self.beneficiaryId = beneficiaryId
    }
}

extension DeleteAccount: HumanReadable {
    public func toHuman() -> Any {
        return [
            "beneficiaryId": beneficiaryId
        ]
    }
}

extension DeleteAccount: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try beneficiaryId.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.beneficiaryId = try .init(from: &reader)
    }
}

public enum Action {
    case createAccount(CreateAccount)
    case deployContract(DeployContract)
    case functionCall(FunctionCall)
    case transfer(Transfer)
    case stake(Stake)
    case addKey(AddKey)
    case deleteKey(DeleteKey)
    case deleteAccount(DeleteAccount)

    public var rawValue: UInt8 {
        switch self {
        case .createAccount: return 0
        case .deployContract: return 1
        case .functionCall: return 2
        case .transfer: return 3
        case .stake: return 4
        case .addKey: return 5
        case .deleteKey: return 6
        case .deleteAccount: return 7
        }
    }
    
    public var name: String {
        switch self {
        case .createAccount: return "Create Account"
        case .deployContract: return "Deploy Contract"
        case .functionCall: return "Function Call"
        case .transfer: return "Transfer"
        case .stake: return "Stake"
        case .addKey: return "Add Key"
        case .deleteKey: return "Delete Key"
        case .deleteAccount: return "Delete Account"
        }
    }
}

extension Action: HumanReadable {
    public func toHuman() -> Any {
        var readable: [String: Any] = [
            "name": self.name
        ]
        switch self {
        case .createAccount(let createAccount):
            readable["value"] = createAccount.toHuman()
        case .deployContract(let deployContract):
            readable["value"] = deployContract.toHuman()
        case .functionCall(let functionCall):
            readable["value"] = functionCall.toHuman()
        case .transfer(let transfer):
            readable["value"] = transfer.toHuman()
        case .stake(let stake):
            readable["value"] = stake.toHuman()
        case .addKey(let addKey):
            readable["value"] = addKey.toHuman()
        case .deleteKey(let deleteKey):
            readable["value"] = deleteKey.toHuman()
        case .deleteAccount(let deleteAccount):
            readable["value"] = deleteAccount.toHuman()
        }
        return readable
    }
}

extension Action: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try rawValue.serialize(to: &writer)
        switch self {
        case .createAccount(let payload): try payload.serialize(to: &writer)
        case .deployContract(let payload): try payload.serialize(to: &writer)
        case .functionCall(let payload): try payload.serialize(to: &writer)
        case .transfer(let payload): try payload.serialize(to: &writer)
        case .stake(let payload): try payload.serialize(to: &writer)
        case .addKey(let payload): try payload.serialize(to: &writer)
        case .deleteKey(let payload): try payload.serialize(to: &writer)
        case .deleteAccount(let payload): try payload.serialize(to: &writer)
        }
    }

    public init(from reader: inout BinaryReader) throws {
        let rawValue = try UInt8.init(from: &reader)
        switch rawValue {
        case 0: self = .createAccount(try CreateAccount(from: &reader))
        case 1: self = .deployContract(try DeployContract(from: &reader))
        case 2: self = .functionCall(try FunctionCall(from: &reader))
        case 3: self = .transfer(try Transfer(from: &reader))
        case 4: self = .stake(try Stake(from: &reader))
        case 5: self = .addKey(try AddKey(from: &reader))
        case 6: self = .deleteKey(try DeleteKey(from: &reader))
        case 7: self = .deleteAccount(try DeleteAccount(from: &reader))
        default: fatalError()
        }
    }
}
