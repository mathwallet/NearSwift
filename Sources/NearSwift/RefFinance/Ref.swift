//
//  Ref.swift
//  
//
//  Created by mathwallet on 2022/11/10.
//

import Foundation

public struct Ref {
    public static let contract = "v2.ref-finance.near"
    
    public struct Storage {
        public static let MINIMUM_STORAGE_NEAR = "1250000000000000000000"
        public static let REGISTER_TOKEN_COST_NEAR = "12500000000000000000000"
        public static let REGISTER_ATTACHED_GAS: UInt64 = 30000000000000
    }
    
    public struct Token {
        public let TRANSFER_TOKEN_GAS: UInt64 = 100000000000000
        public let ONE_YOCTO_NEAR = "1"
        public let account: Account
        
        public init(provider: Provider, accountId: String) {
          self.account = Account(provider: provider, accountId: accountId)
        }
    }
}
