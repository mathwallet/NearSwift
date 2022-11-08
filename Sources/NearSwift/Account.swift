//
//  Account.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import Foundation
import PromiseKit

public struct AccountState: Codable {
    public let accountId: String?
    public let staked: String?
    public let locked: String
    public let amount: String
    public let codeHash: String
    public let blockHash: String
    public let blockHeight: UInt64
    public let storagePaidAt: Int
    public let storageUsage: Int
}

public struct AccountAccessKey: Decodable {
    public let accessKey: AccessKey
    public let publicKey: PublicKey
}

public struct AccountAccessKeyList: Decodable {
    public let keys: [AccountAccessKey]
}

public struct QueryResult: Codable {
    public let logs: [String]
    public let result: [UInt8]
}

public struct AccountBalance: Codable {
    public let total: String
    public let stateStaked: String?
    public let staked: String?
    public let available: String
}

public final class Account {
    public let provider: Provider
    public let accountId: String
    
    public init(provider: Provider, accountId: String) {
      self.provider = provider
      self.accountId = accountId
    }
    
    public func viewState() -> Promise<AccountState> {
        let params = [
            "request_type": "view_account",
            "finality": Finality.optimistic.rawValue,
            "account_id": accountId
        ]
        return provider.query(params: params)
    }
    
    public func viewAccessKey(publicKey: PublicKey) -> Promise<AccessKey> {
        let params = [
            "request_type": "view_access_key",
            "finality": Finality.optimistic.rawValue,
            "account_id": accountId,
            "public_key": publicKey.description
        ]
        return provider.query(params: params)
    }
    
    public func viewAccessKeyList() -> Promise<AccountAccessKeyList> {
        let params = [
            "request_type": "view_access_key_list",
            "finality": Finality.optimistic.rawValue,
            "account_id": accountId
        ]
        return provider.query(params: params)
    }
    
    public func viewFunction<T: Decodable>(contractId: String, methodName: String, args: [String: Any] = [:], decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> Promise<T> {
        let (promise, seal) = Promise<T>.pending()
        let data = try! JSONSerialization.data(withJSONObject: args).base64EncodedString()
        let params = [
            "request_type": "call_function",
            "finality": Finality.optimistic.rawValue,
            "account_id": contractId,
            "method_name": methodName,
            "args_base64": data
        ]
        provider.query(params: params).done { (result: QueryResult) in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let resultData = Data(result.result)
                let decodedResult = try decoder.decode(T.self, from: resultData)
                seal.fulfill(decodedResult)
            } catch let error {
                seal.reject(error)
            }
        }.catch { error in
            seal.reject(error)
        }
        return promise
    }
    
    public func balance() -> Promise<AccountBalance> {
        firstly {
            when(fulfilled: provider.experimentalProtocolConfig(blockQuery: .finality(.final)), viewState())
        }.map { (protocolConfig, state) -> AccountBalance in
            guard let storageAmountPerByte = protocolConfig.runtimeConfig?.storageAmountPerByte else {
                throw NearError.providerError("Protocol Config Error")
            }
            let costPerByte = UInt128(stringLiteral: storageAmountPerByte)
            let stateStaked = UInt128(integerLiteral: UInt64(state.storageUsage)) * costPerByte
            let staked = UInt128(stringLiteral: state.locked)
            let totalBalance = UInt128(stringLiteral: state.amount) + staked
            let availableBalance = totalBalance - max(staked, stateStaked)
            
            return AccountBalance(total: totalBalance.toString(), stateStaked: stateStaked.toString(), staked: staked.toString(), available: availableBalance.toString())
        }
    }
}
