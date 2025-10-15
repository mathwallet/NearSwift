import XCTest
@testable import NearSwift
@testable import CryptoSwift

final class NearSwiftKeyPairTests: XCTestCase {
    func testPublicKeyExample() throws {
        let pubKey = try PublicKey(encodedKey: "ed25519:AYWv9RAN1hpSQA4p1DLhCNnpnNXwxhfH9qeHN8B4nJ59")
        XCTAssertTrue(pubKey.keyType == .ED25519)
        XCTAssertTrue(pubKey.data.toHexString() == "8dcc038db73ae67aad8b3c7f68821945462ed42506d3d0090182c21907e9f30c")
        
        let pubKey2 = try PublicKey(keyType: .ED25519, data: Data(hex: "8dcc038db73ae67aad8b3c7f68821945462ed42506d3d0090182c21907e9f30c"))
        XCTAssertTrue(pubKey2.description == "ed25519:AYWv9RAN1hpSQA4p1DLhCNnpnNXwxhfH9qeHN8B4nJ59")
    }
    
    func testKeyPairExample() throws {
        let keyPair = try KeyPairEd25519(secretKey: "5JueXZhEEVqGVT5powZ5twyPP8wrap2K7RdAYGGdjBwiBdd7Hh6aQxMP1u3Ma9Yanq1nEv32EW7u8kUJsZ6f315C")
        XCTAssertEqual(keyPair.getPublicKey().description, "ed25519:EWrekY1deMND7N3Q7Dixxj12wD7AVjFRt2H9q21QHUSW")
        
        let keyPair2 = try KeyPairSecp256k1(secretKey: "Cqmi5vHc59U1MHhq7JCxTSJentvVBYMcKGUA7s7kwnKn")
        XCTAssertEqual(keyPair2.getPublicKey().description, "secp256k1:45KcWwYt6MYRnnWFSxyQVkuu9suAzxoSkUMEnFNBi9kDayTo5YPUaqMWUrf7YHUDNMMj3w75vKuvfAMgfiFXBy28")
    }
    
    func testSignMessageExample() throws {
        let message = "message".data(using: .utf8)!.sha256()
        let keyPair = try KeyPairEd25519(secretKey: "5JueXZhEEVqGVT5powZ5twyPP8wrap2K7RdAYGGdjBwiBdd7Hh6aQxMP1u3Ma9Yanq1nEv32EW7u8kUJsZ6f315C")
        let signature = try keyPair.sign(message: message)
        XCTAssertEqual(signature.data.toHexString(), "58c9757fdb44eda0776e4bb2066760921fc80f3bc6d07bc89bfabc8f48b859541b290e1a364651af5c95d655c515c72b7248925051d8dc0ea1928687a8027b05")
        XCTAssertTrue(try keyPair.verify(message: message, signature: signature.data))
        
        let keyPair2 = try KeyPairSecp256k1(secretKey: "Cqmi5vHc59U1MHhq7JCxTSJentvVBYMcKGUA7s7kwnKn")
        let signature2 = try keyPair2.sign(message: message)
        XCTAssertEqual(signature2.data.toHexString(), "218607b6ad5f15c1e95de362dbe2149215f691007399c1f8ccbb1ee4745cee7f7d8b5ff456247c087e9de30794c55242be261e4486a0b1cd70e368f26789674100")
        XCTAssertTrue(try keyPair2.verify(message: message, signature: signature2.data))
    }
    
    func testConvertToStringExample() throws {
        let keyPair = try! KeyPairEd25519.fromRandom()
        let newKeyPair = try! keyPairFromString(encodedKey: keyPair.description) as! KeyPairEd25519
        XCTAssertEqual(newKeyPair.description, keyPair.description)
    }
    
    
    func testPublicKeyEquatableExample() throws {
        let pubKey1 = try PublicKey(encodedKey: "ed25519:AYWv9RAN1hpSQA4p1DLhCNnpnNXwxhfH9qeHN8B4nJ59")
        let pubKey2 = try PublicKey(keyType: .ED25519, data: Data(hex: "8dcc038db73ae67aad8b3c7f68821945462ed42506d3d0090182c21907e9f30c"))
        let pubKey3 = try PublicKey(keyType: .SECP256k1, data: Data(hex: "99c6f51ad6f98c9c583f8e92bb7758ab2ca9a04110c0a1126ec43e5453d196c166b489a4b7c491e7688e6ebea3a71fc3a1a48d60f98d5ce84c93b65e423fde91"))
        let pubKey4 = try PublicKey(encodedKey: "secp256k1:45KcWwYt6MYRnnWFSxyQVkuu9suAzxoSkUMEnFNBi9kDayTo5YPUaqMWUrf7YHUDNMMj3w75vKuvfAMgfiFXBy28")
        
        XCTAssertTrue(pubKey1 == pubKey2)
        XCTAssertTrue(pubKey1 != pubKey3)
        XCTAssertTrue(pubKey3 == pubKey4)
    }
    
}
