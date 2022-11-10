//
//  NearSwiftRefTests.swift
//  
//
//  Created by 薛跃杰 on 2022/11/10.
//

import XCTest
@testable import NearSwift

final class NearSwiftRefTests: XCTestCase {

    static let network = Network(name: "testnet", chainId: "testnet")
    static let url = URL(string: "https://rpc.mainnet.near.org")!
    static let provider = JSONRPCProvider(url: url, network: network)

    func testTokenExample() throws {
        let token = Ref.Token(provider: Self.provider, accountId: "mathtest.near")
        
        let reqeustExpectation = expectation(description: "Tests")
        DispatchQueue.global().async {
            do {
                let isRegist = try token.isRegist(contractId: "wrap.near").wait()
                let tokenbalance = try token.balance(contractId: "wrap.near").wait()
                print(isRegist,tokenbalance)
            } catch let error {
                XCTAssertTrue(false)
                //debugPrint(error)
                reqeustExpectation.fulfill()
            }
        }
        wait(for: [reqeustExpectation], timeout: 30)
        
    }

}
