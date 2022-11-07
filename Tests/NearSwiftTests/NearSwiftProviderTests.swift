//
//  NearSwiftProviderTests.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import XCTest
@testable import NearSwift

class NearSwiftProviderTests: XCTestCase {
    
    // mainnet, testnet
    //let network = Network(name: "mainnet", chainId: "mainnet")
    static let network = Network(name: "testnet", chainId: "testnet")
    //  https://rpc.mainnet.near.org
    //  https://rpc.testnet.near.org
    static let url = URL(string: "https://rpc.mainnet.near.org")!
    static let provider = JSONRPCProvider(url: url, network: network)

    
    func testNetworksExamples() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let network = try Self.provider.getNetwork().wait()
                XCTAssertEqual(network.chainId, network.chainId)
                
                let status = try Self.provider.status().wait()
                XCTAssertEqual(status.chainId, network.chainId)
                
                reqeustExpectation.fulfill()
            } catch let error {
                //debugPrint(error.localizedDescription)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testAccountExamples() throws {
        let reqeustExpectation = expectation(description: "Tests")
        let account = Account(provider: Self.provider, accountId: "near2near.testnet")
        DispatchQueue.global().async {
            do {
                let _ = try account.viewState().wait()
                let _ = try account.viewAccessKeyList().wait()
                let _ = try account.balance().wait()
                reqeustExpectation.fulfill()
            } catch let error {
                XCTAssertTrue(false)
                debugPrint(error.localizedDescription)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
    }
    
    func testAccountTokenExamples() throws {
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let result:String? = try Self.provider.viewFunction(contractId: "wrap.near", methodName: "storage_balance_of", args: ["account_id": account.accountId]).wait()
                reqeustExpectation.fulfill()
            } catch let error {
                XCTAssertTrue(false)
                debugPrint(error.localizedDescription)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 60)
    }

}
