//
//  Provider.swift
//
//
//  Created by mathwallet on 2022/7/13.
//

import Foundation
import AnyCodable
import PromiseKit

public struct RPCError: Error, Decodable {
    public let blockHeight: Int
    public let blockHash: String
    public let logs: [String]
    public let error: String
}

public struct SyncInfo: Codable {
    public let latestBlockHash: String
    public let latestBlockHeight: Int
    public let latestBlockTime: String
    public let latestStateRoot: String
    public let syncing: Bool
}

public struct Validator: Codable {}

public struct NodeStatusResult: Codable {
    public let chainId: String
    public let rpcAddr: String
    public let syncInfo: SyncInfo
    public let validators: [Validator]
}

public struct NetworkInfoResult: Decodable {
    public let peerMaxCount: Int
}

public struct SimpleRPCResult: Decodable {
    public let id: Int
    public let jsonrpc: String
    public let result: String
}

public typealias BlockHeight = Int
public enum BlockId {
    case blockHash(String)
    case blockHeight(Int)
}
public enum NullableBlockId {
    case blockHash(String)
    case blockHeight(Int)
    case null
}

public func typeEraseNullableBlockId(blockId: NullableBlockId) -> Any? {
    switch blockId {
    case .blockHeight(let height):
        return height
    case .blockHash(let hash):
        return hash
    case .null:
        return nil
    }
}

public enum BlockReference {
    case blockId(BlockId)
    case finality(Finality)
}

public func typeEraseBlockId(blockId: BlockId) -> Any {
    switch blockId {
    case .blockHeight(let height):
        return height
    case .blockHash(let hash):
        return hash
  }
}

public func typeEraseBlockReferenceParams(blockQuery: BlockReference) -> [String: Any] {
    var params: [String: Any] = [:]
    switch blockQuery {
    case .blockId(let blockId):
        params["block_id"] = typeEraseBlockId(blockId: blockId)
    case .finality(let finality):
        params["finality"] = finality.rawValue
    }
  
    return params
}

public struct AccessKeyWithPublicKey: Codable {
    public let accountId: String
    public let publicKey: String
}

public enum ExecutionStatusBasic: String, Decodable {
    case unknown = "Unknown"
    case pending = "Pending"
    case failure = "Failure"
}

public enum ExecutionStatus: Decodable, Equatable {
    case successValue(String)
    case basic(ExecutionStatusBasic)
    case successReceiptId(String)
    case failure(ExecutionError)

    private enum CodingKeys: String, CodingKey {
        case successValue = "SuccessValue"
        case failure = "Failure"
        case successReceiptId = "SuccessReceiptId"
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), let status = try? container.decode(ExecutionStatusBasic.self) {
            self = .basic(status)
            return
        }
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container?.decode(String.self, forKey: .successValue) {
            self = .successValue(value)
            return
        }
        if let value = try? container?.decode(String.self, forKey: .successReceiptId) {
            self = .successReceiptId(value)
            return
        }
        if let value = try? container?.decode(ExecutionError.self, forKey: .failure) {
            self = .failure(value)
            return
        }
        throw NearError.notExpected
    }
}

public enum FinalExecutionStatusBasic: String, Codable {
    case notStarted = "NotStarted"
    case started = "Started"
    case failure = "Failure"
}

public struct ExecutionError: Codable, Equatable{
    let errorMessage: String?
    let errorType: String?

    init(errorMessage: String? = nil, errorType: String? = nil) {
        self.errorMessage = errorMessage
        self.errorType = errorType
    }
}

public enum FinalExecutionStatus: Decodable, Equatable {
    case successValue(String)
    case basic(ExecutionStatusBasic)
    case failure(ExecutionError)

    private enum CodingKeys: String, CodingKey {
        case successValue = "SuccessValue"
        case failure = "Failure"
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), let status = try? container.decode(ExecutionStatusBasic.self) {
            self = .basic(status)
            return
        }
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container?.decode(String.self, forKey: .successValue) {
            self = .successValue(value)
            return
        }
        if let value = try? container?.decode(ExecutionError.self, forKey: .failure) {
            self = .failure(value)
            return
        }
        throw NearError.notExpected
    }
}

public struct ExecutionOutcomeWithId: Decodable, Equatable {
    public let id: String
    public let outcome: ExecutionOutcome
}

public struct ExecutionOutcome: Decodable, Equatable {
    public let status: ExecutionStatus
    public let logs: [String]
    public let receiptIds: [String]
    public let gasBurnt: Int
}

public struct FinalExecutionOutcome: Decodable, Equatable {
    public let transaction: TransactionResult
    public let status: FinalExecutionStatus
    public let transactionOutcome: ExecutionOutcomeWithId
    public let receiptsOutcome: [ExecutionOutcomeWithId]
}

public struct TotalWeight: Codable {
    let num: Int
}

public struct BlockHeader: Codable {
    public let height: Int
    public let epochId: String
    public let nextEpochId: String
    public let hash: String
    public let prevHash: String
    public let prevStateRoot: String
    public let chunkReceiptsRoot: String
    public let chunkHeadersRoot: String
    public let chunkTxRoot: String
    public let outcomeRoot: String
    public let chunksIncluded: Int
    public let challengesRoot: String
    public let timestamp: Int
    public let timestampNanosec: String
    public let randomValue: String
    public let validatorProposals: [ValidatorProposal]
    public let chunkMask: [Bool]
    public let gasPrice: String
    public let rentPaid: String
    public let validatorReward: String
    public let totalSupply: String
    public let lastFinalBlock: String
    public let lastDsFinalBlock: String
    public let nextBpHash: String
    public let blockMerkleRoot: String
}

public typealias ChunkHash = String
public typealias ShardId = Int
public struct BlockShardId {
    public let blockId: BlockId
    public let shardId: ShardId
}

public enum ChunkId {
    case chunkHash(ChunkHash)
    case blockShardId(BlockShardId)
}

public struct ValidatorProposal: Codable {}

public struct ChunkHeader: Codable {
    public let chunkHash: ChunkHash
    public let prevBlockHash: String
    public let outcomeRoot: String
    public let prevStateRoot: String
    public let encodedMerkleRoot: String
    public let encodedLength: Int
    public let heightCreated: Int
    public let heightIncluded: Int
    public let shardId: ShardId
    public let gasUsed: Int
    public let gasLimit: Int
    public let rentPaid: String
    public let validatorReward: String
    public let balanceBurnt: String
    public let outgoingReceiptsRoot: String
    public let txRoot: String
    public let validatorProposals: [ValidatorProposal]
    public let signature: String
}

public struct Receipt: Codable {}

public struct ChunkResult: Codable {
    public let header: ChunkHeader
    public let receipts: [Receipt]
    public let transactions: [TransactionResult]
}

public struct TransactionResult: Codable, Equatable {
    public let hash: String
    public let publicKey: String
    public let signature: String
}

public struct BlockResult: Codable {
    public let header: BlockHeader
    public let transactions: [TransactionResult]?
}

public struct BlockChange: Codable {
    public let type: String
    public let accountId: String
}

public struct BlockChangeResult: Codable {
    public let blockHash: String
    public let changes: [BlockChange]
}

public struct ChangeResult: Decodable {
    public let blockHash: String
    public let changes: [AnyDecodable]
}

public struct ExperimentalNearProtocolConfig: Decodable {
    public let chainId: String
    public let genesisHeight: Int
    public let runtimeConfig: ExperimentalNearProtocolRuntimeConfig?
}

public struct ExperimentalNearProtocolRuntimeConfig: Decodable {
    public let storageAmountPerByte: String
}

public struct GasPrice: Codable {
    public let gasPrice: String
}

public struct EpochValidatorInfo: Decodable {
    // Validators for the current epoch.
    public let nextValidators: [NextEpochValidatorInfo]
    // Validators for the next epoch.
    public let currentValidators: [CurrentEpochValidatorInfo]
    // Fishermen for the current epoch.
    public let nextFishermen: [ValidatorStakeView]
    // Fishermen for the next epoch.
    public let currentFishermen: [ValidatorStakeView]
    // Proposals in the current epoch.
    public let currentProposals: [ValidatorStakeView]
    // Kickout in the previous epoch.
    public let prevEpochKickout: [ValidatorStakeView]
    // Epoch start height.
    public let epochStartHeight: Int
}

public struct CurrentEpochValidatorInfo: Decodable {
    public let accountId: String
    public let publicKey: String
    public let isSlashed: Bool
    public let stake: String
    public let shards: [Int]
    public let numProducedBlocks: Int
    public let numExpectedBlocks: Int
}

public struct NextEpochValidatorInfo: Decodable {
    public let accountId: String
    public let publicKey: String
    public let stake: String
    public let shards: [Int]
}

public struct ValidatorStakeView: Decodable {
    public let accountId: String
    public let publicKey: String
    public let stake: String
}

public enum ProviderType {
    case jsonRPC(URL)
}

public protocol Provider {
    func getNetwork() -> Promise<Network>
    func status() -> Promise<NodeStatusResult>
    func networkInfo() -> Promise<NetworkInfoResult>
    func sendTransaction(signedTransaction: SignedTransaction) -> Promise<FinalExecutionOutcome>
    func sendTransactionAsync(signedTransaction: SignedTransaction) -> Promise<SimpleRPCResult>
    func txStatus(txHash: Data, accountId: String) -> Promise<FinalExecutionOutcome>
    func experimentalTxStatusWithReceipts(txHash: Data, accountId: String) -> Promise<FinalExecutionOutcome>
    func query<T: Decodable>(params: [String: Any]) -> Promise<T>
    func block(blockQuery: BlockReference) -> Promise<BlockResult>
    func blockChanges(blockQuery: BlockReference) -> Promise<BlockChangeResult>
    func chunk(chunkId: ChunkId) -> Promise<ChunkResult>
    func gasPrice(blockId: NullableBlockId) -> Promise<GasPrice>
    func experimentalGenesisConfig() -> Promise<ExperimentalNearProtocolConfig>
    func experimentalProtocolConfig(blockQuery: BlockReference) -> Promise<ExperimentalNearProtocolConfig>
    func validators(blockId: NullableBlockId) -> Promise<EpochValidatorInfo>
    func accessKeyChanges(accountIdArray: [String], blockQuery: BlockReference) -> Promise<ChangeResult>
    func singleAccessKeyChanges(accessKeyArray: [AccessKeyWithPublicKey], blockQuery: BlockReference) -> Promise<ChangeResult>
    func accountChanges(accountIdArray: [String], blockQuery: BlockReference) -> Promise<ChangeResult>
    func contractStateChanges(accountIdArray: [String], blockQuery: BlockReference, keyPrefix: String?) -> Promise<ChangeResult>
    func contractCodeChanges(accountIdArray: [String], blockQuery: BlockReference) -> Promise<ChangeResult>
}
