//
//  JSONRPCProvider.swift
//
//
//  Created by mathwallet on 2022/7/13.
//


import Foundation
import PromiseKit
import AnyCodable

public struct JSONRPCHandlerErrorCause: Decodable {
    public let name: String
}

public struct JSONRPCHandlerError: Decodable {
    public let cause: JSONRPCHandlerErrorCause
    public let code: Int
    public let message: String
    public let data: AnyCodable
    
    public var description: String {
        data.description
    }
}

public enum Finality: String, Codable {
    case final
    case optimistic
}

public final class JSONRPCProvider {
    /// Keep ids unique across all connections
    private var _nextId = 123

    private let url: URL
    private var network: Network?
    
    public var session: URLSession = {() -> URLSession in
        let config = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: config)
        return urlSession
    }()

    public init(url: URL, network: Network? = nil) {
        self.url = url
        self.network = network
    }
}

extension JSONRPCProvider {
    private func getId() -> Int {
        _nextId += 1
        return _nextId
    }
    
    private func fetchJson<T: Decodable>(url: URL, parameters: [String: Any]?, queue: DispatchQueue = .main, session: URLSession) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        queue.async {
            do {
                //debugPrint("POST \(url)")
                var urlRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
                urlRequest.httpMethod = parameters.flatMap {_ in "POST"} ?? "GET"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                if let p = parameters {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: p)
                    //debugPrint(p)
                }
                task = session.dataTask(with: urlRequest){ (data, response, error) in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil else {
                        rp.resolver.reject(NearError.providerError("Received an error message from node"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        return rp.promise.ensure(on: queue) {
                task = nil
            }.map(on: queue){ (data: Data) throws -> T in
                //debugPrint(try JSONDecoder().decode(AnyDecodable.self, from: data).value)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                if let decoded = try? decoder.decode(T.self, from: data) {
                    return decoded
                }
                
                let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let json = result?["result"], let processData = try? JSONSerialization.data(withJSONObject: json) {
                    let decoded = try decoder.decode(T.self, from: processData)
                    return decoded
                }
                if let json = result?["error"], let processData = try? JSONSerialization.data(withJSONObject: json) {
                    let decoded = try decoder.decode(JSONRPCHandlerError.self, from: processData)
                    throw NearError.providerError("\(decoded.description)")
                }
                throw NearError.providerError("Node response is empty")
            }
    }

    private func sendJsonRpc<T: Decodable>(method: String, params: [Any?]) -> Promise<T> {
        let request: [String: Any] = ["method": method,
                                      "params": params,
                                      "id": getId(),
                                      "jsonrpc": "2.0"]
        return fetchJson(url: url, parameters: request, session: session)
    }
  
    private func sendJsonRpc<T: Decodable>(method: String, paramsDict: [String: Any]) -> Promise<T> {
        let request: [String: Any] = ["method": method,
                                      "params": paramsDict,
                                      "id": getId(),
                                      "jsonrpc": "2.0"]
        return fetchJson(url: url, parameters: request, session: session)
    }
}

extension JSONRPCProvider: Provider {
    public func getNetwork() -> Promise<Network> {
        if let n = network {
            return Promise { resolver in
                resolver.fulfill(n)
            }
        }
        return sendJsonRpc(method: "status", params: []).map { (status: NodeStatusResult) throws -> Network in
            return Network(name: "testnet", chainId: status.chainId)
        }
    }

    public func status() -> Promise<NodeStatusResult> {
        return sendJsonRpc(method: "status", params: [])
    }

    public func networkInfo() -> Promise<NetworkInfoResult> {
        return sendJsonRpc(method: "network_info", params: [])
    }

    public func sendTransaction(signedTransaction: SignedTransaction) -> Promise<FinalExecutionOutcome> {
        let data = try! BorshEncoder().encode(signedTransaction)
        let params = [data.base64EncodedString()]
        return sendJsonRpc(method: "broadcast_tx_commit", params: params)
    }

    public func sendTransactionAsync(signedTransaction: SignedTransaction) -> Promise<SimpleRPCResult> {
        let data = try! BorshEncoder().encode(signedTransaction)
        let params = [data.base64EncodedString()]
        return sendJsonRpc(method: "broadcast_tx_async", params: params)
    }

    public func txStatus(txHash: Data, accountId: String) -> Promise<FinalExecutionOutcome> {
        let params = [txHash.bytes.base58EncodedString, accountId]
        return sendJsonRpc(method: "tx", params: params)
    }

    public func experimentalTxStatusWithReceipts(txHash: Data, accountId: String) -> Promise<FinalExecutionOutcome> {
        let params = [txHash.bytes.base58EncodedString, accountId]
        return sendJsonRpc(method: "EXPERIMENTAL_tx_status", params: params)
    }

    public func query<T: Decodable>(params: [String: Any]) -> Promise<T> {
        return sendJsonRpc(method: "query", paramsDict: params)
    }

    public func block(blockQuery: BlockReference) -> Promise<BlockResult> {
        let params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        return sendJsonRpc(method: "block", paramsDict: params)
    }

    public func blockChanges(blockQuery: BlockReference) -> Promise<BlockChangeResult> {
        let params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        return sendJsonRpc(method: "EXPERIMENTAL_changes_in_block", paramsDict: params)
    }

    public func chunk(chunkId: ChunkId) -> Promise<ChunkResult> {
        var params: [String: Any] = [:]
        switch chunkId {
        case .chunkHash(let chunkHash):
          params["chunk_id"] = chunkHash
        case .blockShardId(let blockShardId):
          params["block_id"] = typeEraseBlockId(blockId: blockShardId.blockId)
          params["shard_id"] = blockShardId.shardId
        }
        return sendJsonRpc(method: "chunk", paramsDict: params)
    }

    public func gasPrice(blockId: NullableBlockId) -> Promise<GasPrice> {
        let params: Any? = typeEraseNullableBlockId(blockId: blockId)
        return sendJsonRpc(method: "gas_price", params: [params])
    }

    public func experimentalGenesisConfig() -> Promise<ExperimentalNearProtocolConfig> {
        return sendJsonRpc(method: "EXPERIMENTAL_genesis_config", params: [])
    }

    public func experimentalProtocolConfig(blockQuery: BlockReference) -> Promise<ExperimentalNearProtocolConfig> {
        let params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        return sendJsonRpc(method: "EXPERIMENTAL_protocol_config", paramsDict: params)
    }

    public func validators(blockId: NullableBlockId) -> Promise<EpochValidatorInfo> {
        let params: Any? = typeEraseNullableBlockId(blockId: blockId)
        return sendJsonRpc(method: "validators", params: [params])
    }

    public func accessKeyChanges(accountIdArray: [String], blockQuery: BlockReference) -> Promise<ChangeResult> {
        var params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        params["changes_type"] = "all_access_key_changes"
        params["account_ids"] = accountIdArray

        return sendJsonRpc(method: "EXPERIMENTAL_changes", paramsDict: params)
    }

    public func singleAccessKeyChanges(accessKeyArray: [AccessKeyWithPublicKey], blockQuery: BlockReference) -> Promise<ChangeResult> {
        var params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        params["changes_type"] = "single_access_key_changes"
        params["keys"] = accessKeyArray.map { value in
          return [
            "account_id": value.accountId,
            "public_key": value.publicKey
          ]
        }

        return sendJsonRpc(method: "EXPERIMENTAL_changes", paramsDict: params)
    }
    public func accountChanges(accountIdArray: [String], blockQuery: BlockReference) -> Promise<ChangeResult> {
        var params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        params["changes_type"] = "account_changes"
        params["account_ids"] = accountIdArray

        return sendJsonRpc(method: "EXPERIMENTAL_changes", paramsDict: params)
    }

    public func contractStateChanges(accountIdArray: [String], blockQuery: BlockReference, keyPrefix: String?) -> Promise<ChangeResult> {
        var params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        params["changes_type"] = "data_changes"
        params["account_ids"] = accountIdArray
        params["key_prefix_base64"] = keyPrefix ?? ""

        return sendJsonRpc(method: "EXPERIMENTAL_changes", paramsDict: params)
    }

    public func contractCodeChanges(accountIdArray: [String], blockQuery: BlockReference) -> Promise<ChangeResult> {
        var params: [String: Any] = typeEraseBlockReferenceParams(blockQuery: blockQuery)
        params["changes_type"] = "contract_code_changes"
        params["account_ids"] = accountIdArray

        return sendJsonRpc(method: "EXPERIMENTAL_changes", paramsDict: params)
    }
}
