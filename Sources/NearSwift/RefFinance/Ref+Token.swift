//
//  RefFiToken.swift
//  
//
//  Created by mathwallet on 2022/11/10.
//

import Foundation
import PromiseKit

extension Ref.Token {
    public func isRegist(accountId: String? = nil, contractId: String)  -> Promise<Bool> {
        return Promise<Bool>{ seal in
            storageBalance(accountId: accountId, contractId: contractId).done { storageBalance in
                if let total = storageBalance?.total, let _storageBalance = Decimal(string: total), _storageBalance >= Decimal(string: Ref.Storage.MINIMUM_STORAGE_NEAR)!{
                    seal.fulfill(true)
                } else {
                    seal.fulfill(false)
                }
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func storageBalance(accountId: String? = nil, contractId: String) -> Promise<NearSwift.AccountBalance?> {
        return self.account.viewFunction(contractId: contractId, methodName: "storage_balance_of", args: ["account_id": accountId ?? self.account.accountId])
    }
    
    public func balance(accountId: String? = nil, contractId: String) -> Promise<NearSwift.AccountBalance> {
        return Promise { seal in
            self.account.viewFunction(contractId: contractId, methodName: "ft_balance_of", args: ["account_id": account.accountId]).done { (balance: String) in
                seal.fulfill(NearSwift.AccountBalance(total: "0", stateStaked: "0", staked: "0", available: balance))
            }.catch { error in
                seal.reject(error)
            }
        }
    }
    
    public func regist(accountId: String? = nil, publicKey: PublicKey, contractId: String) -> Promise<Transaction> {
        var args: [String: Any] = [:]
        if let _accountId = accountId {
            args =  [
                "account_id": _accountId,
                "registration_only": true
            ]
        }
        let argsBytes = try! JSONSerialization.data(withJSONObject: args).bytes
        let storageAction = Action.functionCall(FunctionCall(methodName: "storage_deposit", args: argsBytes, gas: Ref.Storage.REGISTER_ATTACHED_GAS, deposit: UInt128(stringLiteral: Ref.Storage.REGISTER_TOKEN_COST_NEAR)))
        return configTransaction(account: account, publicKey: publicKey, actions: [storageAction], receiverId: contractId)
    }
    
    public func transfer(account: Account, publicKey: PublicKey, receiverId: String, amount: String) -> Promise<Transaction> {
        let args = [
            "receiver_id": receiverId,
            "amount": amount
        ]
        let argsData = try! JSONSerialization.data(withJSONObject: args)
        let action = Action.functionCall(FunctionCall(methodName: "ft_transfer", args: argsData.bytes, gas: TRANSFER_TOKEN_GAS, deposit: UInt128(stringLiteral: ONE_YOCTO_NEAR)))
        return configTransaction(account: account, publicKey: publicKey, actions: [action], receiverId: receiverId)
    }
    
    func configTransaction(account: Account, publicKey: PublicKey, actions: [Action], receiverId: String) -> Promise<Transaction> {
        let (promise, seal) = Promise<Transaction>.pending()
        firstly {
            when(
                fulfilled: account.viewAccessKeyList(),
                account.viewState()
            )
        }.done { accountAccessKeyList, accountState in
            var nonce: UInt64 = 0
            if let _nonce = accountAccessKeyList.keys.filter({$0.publicKey == publicKey}).first?.accessKey.nonce  {
                nonce = _nonce + 1
            }
            let blockHash = try BlockHash(encodedString: accountState.blockHash)
            let transaction = Transaction(signerId: account.accountId,
                                          publicKey: publicKey,
                                          nonce: nonce,
                                          receiverId: receiverId,
                                          blockHash: blockHash,
                                          actions: actions)
            seal.fulfill(transaction)
        }.catch { error in
            seal.reject(error)
        }
        return promise
    }
}
