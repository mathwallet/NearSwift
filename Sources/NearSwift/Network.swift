//
//  Network.swift
//  
//
//  Created by mathwallet on 2022/7/14.
//

import Foundation

public struct Network {
    public let name: String
    public let chainId: String
    
    public init(name: String, chainId: String) {
        self.name = name
        self.chainId = chainId
    }
}
