//
//  KeyPair.swift
//  
//
//  Created by mathwallet on 2022/7/13.
//

import Foundation
import TweetNacl
import Secp256k1Swift

public protocol KeyPair {
    func sign(message: Data) throws -> Signature
    func verify(message: Data, signature: Data) throws -> Bool
    func getPublicKey() -> PublicKey
    func getSecretKey() -> String
}

public struct KeyPairEd25519: KeyPair, CustomStringConvertible {
    private let publicKey: PublicKey
    private let secretKey: String
    
    public init(secretKey: String) throws {
        guard let _keyData = secretKey.base58Decoded else { throw NearError.keyError("Unknown key:\(secretKey)") }
        let keyPair = try NaclSign.KeyPair.keyPair(fromSecretKey: _keyData)
        self.publicKey = try PublicKey(keyType: .ED25519, data: keyPair.publicKey)
        self.secretKey = secretKey
    }
    
    public static func fromSeed(seed: Data) throws -> Self {
      let newKeyPair = try NaclSign.KeyPair.keyPair(fromSeed: seed )
      return try KeyPairEd25519(secretKey: newKeyPair.secretKey.base58Encoded)
    }
    
    public static func fromRandom() throws -> Self {
        let newKeyPair = try NaclSign.KeyPair.keyPair()
        return try KeyPairEd25519(secretKey: newKeyPair.secretKey.base58Encoded)
    }
    
    public func getPublicKey() -> PublicKey {
        return publicKey
    }
    
    public func getSecretKey() -> String {
        return secretKey
    }
    
    public func sign(message: Data) throws -> Signature {
        guard let bs58Data = secretKey.base58Decoded else { throw NearError.keyError("Unknown key:\(secretKey)") }
        let signature = try NaclSign.signDetached(message: message, secretKey: bs58Data)
        return Signature(data: signature, keyType: publicKey.keyType)
    }
    
    public func verify(message: Data, signature: Data) throws -> Bool {
        return try NaclSign.signDetachedVerify(message: message, sig: signature, publicKey: publicKey.rawData)
    }
    
    public var description: String {
        return "ed25519:\(secretKey)"
    }
}

public struct KeyPairSecp256k1: KeyPair, CustomStringConvertible {
    private let publicKey: PublicKey
    private let secretKey: String
    
    public init(secretKey: String) throws {
        guard let _keyData = secretKey.base58Decoded else { throw NearError.keyError("Unknown key:\(secretKey)") }
        guard SECP256K1.verifyPrivateKey(privateKey: _keyData) else { throw NearError.keyError("Unknown key:\(secretKey)") }
        guard let pubKey = SECP256K1.privateToPublic(privateKey: _keyData, compressed: false) else { throw NearError.keyError("Unknown key:\(secretKey)") }
        self.publicKey = try PublicKey(keyType: .SECP256k1, data: pubKey.subdata(in: 1..<pubKey.count))
        self.secretKey = secretKey
    }
    
    public static func fromRandom() throws -> Self {
        guard let privateKey = SECP256K1.generatePrivateKey() else { throw NearError.notExpected }
        return try KeyPairSecp256k1(secretKey: privateKey.base58Encoded)
    }
    
    public func getPublicKey() -> PublicKey {
        return publicKey
    }
    
    public func getSecretKey() -> String {
        return secretKey
    }
    
    public func sign(message: Data) throws -> Signature {
        guard let privateKey = secretKey.base58Decoded else { throw NearError.keyError("Unknown key:\(secretKey)") }
        let (serializedSignature, _) = SECP256K1.signForRecovery(hash: message, privateKey: privateKey, useExtraVer: false)
        guard let signature = serializedSignature else { throw NearError.keyError(secretKey) }
        return Signature(data: signature, keyType: publicKey.keyType)
    }
    
    public func verify(message: Data, signature: Data) throws -> Bool {
        guard let pubKey = SECP256K1.recoverPublicKey(hash: message, signature: signature, compressed: false) else { return false }
        return pubKey == publicKey.rawData
    }
    
    public var description: String {
        return "secp256k1:\(secretKey)"
    }
}

public func keyPairFromString(encodedKey: String) throws -> KeyPair {
    let parts = encodedKey.components(separatedBy: ":")
    if parts.count == 1 {
        return try KeyPairEd25519(secretKey: parts[0])
    } else if parts.count == 2 {
        guard let curve = KeyType(rawValue: parts[0]) else {
            throw NearError.keyError("Unknown curve: \(parts[0])")
        }
        switch curve {
        case .ED25519: return try KeyPairEd25519(secretKey: parts[1])
        case .SECP256k1: return try KeyPairSecp256k1(secretKey: parts[1])
        }
    } else {
        throw NearError.keyError("Invalid encoded key format, must be <curve>:<encoded key>")
    }
}
