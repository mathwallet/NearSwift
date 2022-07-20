//
//  Transaction.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import UIKit
import CryptoSwift

public struct Transaction {
    public let signerId: String
    public let publicKey: PublicKey
    public let nonce: UInt64
    public let receiverId: String
    public let blockHash: BlockHash
    public let actions: [Action]
    
    public init(signerId: String, publicKey: PublicKey, nonce: UInt64, receiverId: String, blockHash: BlockHash, actions: [Action]) {
        self.signerId = signerId
        self.publicKey = publicKey
        self.nonce = nonce
        self.receiverId = receiverId
        self.blockHash = blockHash
        self.actions = actions
    }
    
    public func txHash() throws -> Data {
        return try BorshEncoder().encode(self).sha256()
    }
    
    public func sign(_ keypair: KeyPair) throws -> SignedTransaction {
        let hash = try txHash()
        let signature = try keypair.sign(message: hash)
        return SignedTransaction(transaction: self, signature: signature)
    }
}

extension Transaction: HumanReadable {
    public func toHuman() -> Any {
        return [
            "signerId": signerId,
            "publicKey": publicKey.description,
            "nonce": nonce,
            "receiverId": receiverId,
            "blockHash": blockHash.description,
            "actions": actions.map{ $0.toHuman() }
        ]
    }
}

extension Transaction: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try signerId.serialize(to: &writer)
        try publicKey.serialize(to: &writer)
        try nonce.serialize(to: &writer)
        try receiverId.serialize(to: &writer)
        try blockHash.serialize(to: &writer)
        try actions.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.signerId = try .init(from: &reader)
        self.publicKey = try .init(from: &reader)
        self.nonce = try .init(from: &reader)
        self.receiverId = try .init(from: &reader)
        self.blockHash = try .init(from: &reader)
        self.actions = try .init(from: &reader)
    }
}

public struct SignedTransaction {
    public let transaction: Transaction
    public let signature: Signature
}

extension SignedTransaction: BorshCodable {
    public func serialize(to writer: inout Data) throws {
        try transaction.serialize(to: &writer)
        try signature.serialize(to: &writer)
    }

    public init(from reader: inout BinaryReader) throws {
        self.transaction = try .init(from: &reader)
        self.signature = try .init(from: &reader)
    }
}
