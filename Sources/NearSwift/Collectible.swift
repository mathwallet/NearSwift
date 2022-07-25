//
//  Collectible.swift
//  
//
//  Created by 薛跃杰 on 2022/7/25.
//

import Foundation
import PromiseKit

struct CollectibleResult:Codable {
    let blockHash:String
    let blockHeight:UInt64
    let result:[UInt8]
}

public struct CollectibleMetadata:Codable {
    let spec:String
    let name:String
    let symbol:String
    let icon:String
    let baseUri:String
}

struct CollectibleTokenId:Codable {
    let tokenId:String
    let ownerId:String
    let metadata:CollectibleTokenMetadata
}

struct CollectibleTokenMetadata:Codable {
    let title:String
    let media:String
    let reference:String
    let issuedAt:String
}

struct CollectibleTokenDescription:Codable {
    let description:String
    let collection:String
    let collectionId:String
}

public struct NearCollectible {
    let name:String
    let symbol:String
    let description:String
    let collectionId:String
    let ownerId:String
    let number:String
    let icon:String
}


public final class Collectible {
    public let provider: Provider
    public let accountId: String
    
    public init(provider: Provider, accountId: String) {
      self.provider = provider
      self.accountId = accountId
    }
    
    func query<T: Decodable>(contractName:String,methodName:String,args:[String: Any]) -> Promise<T> {
        let (promise,seal) = Promise<T>.pending()
        let data = try! JSONSerialization.data(withJSONObject: args)
        let base64Args = data.base64EncodedString()
        let params = [
            "request_type": "call_function",
            "finality": Finality.optimistic.rawValue,
            "account_id": contractName,
            "method_name":methodName,
            "args_base64":base64Args
        ]
        provider.query(params: params).done { (result:CollectibleResult) in
            let data = Data(result.result)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(T.self, from: data)
            seal.fulfill(decoded)
        }.catch { error in
            seal.reject(error)
        }
        return promise
    }
    
    public func getContractName() -> Promise<[String]> {
        let url = "https://api.kitwallet.app/account/\(self.accountId)/likelyNFTs"
        let headers = [
            "origin":"https://wallet.near.org",
            "referer":"https://wallet.near.org"
        ]
        return self.GET(url: url, headers: headers)
    }
    
    public func getMetadata(contractName:String) -> Promise<CollectibleMetadata> {
        let args = [String : Any]()
        return self.query(contractName: contractName, methodName: "nft_metadata", args: args)
    }
    
    func getTokenIds(contractName:String,fromIndex:String) -> Promise<[CollectibleTokenId]> {
        let args = ["account_id":self.accountId,"from_index":fromIndex,"limit":4] as [String : Any]
        return self.query(contractName: contractName, methodName:"nft_tokens_for_owner" , args: args)
    }
    
    func getNumberOfTokens(contractName:String) -> Promise<String> {
        let args = ["account_id":self.accountId] as [String : Any]
        return self.query(contractName: contractName, methodName: "nft_supply_for_owner", args: args)
    }
    
    func getDescription(path:String) -> Promise<CollectibleTokenDescription> {
        return self.GET(url: path)
    }
    
    public func GET<T: Codable>(url:String,headers:[String:String]? = nil) -> Promise<T>  {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "near.get")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        queue.async {
            let url = URL(string: url)
            var urlRequest = URLRequest(url: url!, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            if let _headers = headers {
                _headers.forEach { (key: String, value: String) in
                    urlRequest.addValue(value, forHTTPHeaderField: key)
                }
            }
            
            task = session.dataTask(with: urlRequest){ (data, response, error) in
                guard error == nil else {
                    rp.resolver.reject(error!)
                    return
                }
                guard data != nil else {
                    rp.resolver.reject( NearError.unknown)
                    return
                }
                rp.resolver.fulfill(data!)
            }
            task?.resume()
        }
        return rp.promise.ensure(on: queue) {
            task = nil
        }.map(on: queue){ (data: Data) throws -> T in
            if let resp = try? JSONDecoder().decode(T.self, from: data) {
                return resp
            }
            throw NearError.unknown
        }
    }
}
