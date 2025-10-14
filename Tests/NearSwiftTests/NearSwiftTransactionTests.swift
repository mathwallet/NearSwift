//
//  NearSwiftTransactionTests.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import XCTest
import Base58Swift
@testable import NearSwift

class NearSwiftTransactionTests: XCTestCase {
    
    static let network = Network(name: "testnet", chainId: "testnet")
    static let url = URL(string: "https://rpc.testnet.near.org")!
    static let provider = JSONRPCProvider(url: url, network: network)

    func testTransactionHumanReadableExample() throws {
        let keyPair = try! keyPairFromString(encodedKey: "ed25519:2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw") as! KeyPairEd25519
        let publicKey = keyPair.getPublicKey()
        let actions: [Action] = [
            .createAccount(CreateAccount()),
            .deployContract(DeployContract(code: [1, 2, 3])),
            .functionCall(FunctionCall(methodName: "qqq", args: [1, 2, 3], gas: 1000, deposit: 1000000)),
            .transfer(Transfer(deposit: 123)),
            .stake(Stake(stake: 1000000, publicKey: publicKey)),
            .addKey(AddKey(publicKey: publicKey, accessKey: .functionCallAccessKey(receiverId: "zzz", methodNames: ["www"], allowance: nil))),
            .deleteKey(DeleteKey(publicKey: publicKey)),
            .deleteAccount(DeleteAccount(beneficiaryId: "123"))
        ]
        let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".base58DecodedData
        let transaction = Transaction(signerId: "test.near",
                                      publicKey: publicKey,
                                      nonce: 1,
                                      receiverId: "123",
                                      blockHash: BlockHash(data: blockHash),
                                      actions: actions)
        //debugPrint(transaction.toHuman())
    }
    
    func testSignTransactionExample() throws {
        let keyPair = try! keyPairFromString(encodedKey: "ed25519:2wyRcSwSuHtRVmkMCGjPwnzZmQLeXLzLLyED1NDMt4BjnKgQL6tF85yBx6Jr26D2dUNeC716RBoTxntVHsegogYw") as! KeyPairEd25519
        let publicKey = keyPair.getPublicKey()
        let actions: [Action] = [
            .createAccount(CreateAccount()),
            .deployContract(DeployContract(code: [1, 2, 3])),
            .functionCall(FunctionCall(methodName: "qqq", args: [1, 2, 3], gas: 1000, deposit: 1000000)),
            .transfer(Transfer(deposit: 123)),
            .stake(Stake(stake: 1000000, publicKey: publicKey)),
            .addKey(AddKey(publicKey: publicKey, accessKey: .functionCallAccessKey(receiverId: "zzz", methodNames: ["www"], allowance: nil))),
            .deleteKey(DeleteKey(publicKey: publicKey)),
            .deleteAccount(DeleteAccount(beneficiaryId: "123"))
        ]
        let blockHash = "244ZQ9cgj3CQ6bWBdytfrJMuMQ1jdXLFGnr4HhvtCTnM".base58DecodedData
        let transaction = Transaction(signerId: "test.near",
                                      publicKey: publicKey,
                                      nonce: 1,
                                      receiverId: "123",
                                      blockHash: BlockHash(data: blockHash),
                                      actions: actions)
        XCTAssertEqual(try transaction.txHash().byteArray.base58EncodedString, "Fo3MJ9XzKjnKuDuQKhDAC6fra5H2UWawRejFSEpPNk3Y")
        let signedTransaction = try transaction.sign(keyPair)
        XCTAssertEqual(signedTransaction.signature.data.byteArray.base58EncodedString, "5TYcQFtqP9PqEHmmyARwi65adQoaAtz6zJyNioXnwxuizQsz9GUkWDef3j1MkLX3p8BfYGsH9nAFTXiY7S528L7K")
    }
    
    func testSendTransactionExample() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let keyPair = try! keyPairFromString(encodedKey: "ed25519:LiVgKxE7jgzPvHaoey6rLT1Mo6pYvt2Lp4dMZoC8S3tdcuSTZ1bk2M5RJmeYjgJgkJSFdywaobHmsE4JeGXEKcp") as! KeyPairEd25519
                let publicKey = keyPair.getPublicKey()
                let actions: [Action] = [
                    .addKey(AddKey(publicKey: try PublicKey(encodedKey: "ed25519:G99cFHwTWvJDqiGWMw7HRA61rsQgk8VqbMq5UmZfbqY8"), accessKey: AccessKey(nonce: 0, permission: .fullAccess(FullAccessPermission()))))
                ]
                let account = Account(provider: Self.provider, accountId: "near2near.testnet")
                let accountState = try account.viewState().wait()
                let accessKey = try account.viewAccessKey(publicKey: publicKey).wait()
                
                let blockHash = try BlockHash(encodedString: accountState.blockHash)
                let transaction = Transaction(signerId: account.accountId,
                                              publicKey: publicKey,
                                              nonce: accessKey.nonce + 1,
                                              receiverId: account.accountId,
                                              blockHash: blockHash,
                                              actions: actions)
                //debugPrint(transaction)
                let signedTransaction = try transaction.sign(keyPair)
                let _ = try account.provider.sendTransactionAsync(signedTransaction: signedTransaction).wait()
                //debugPrint(result)
                reqeustExpectation.fulfill()
            } catch {
                XCTAssertTrue(false)
                //debugPrint(error)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
}
