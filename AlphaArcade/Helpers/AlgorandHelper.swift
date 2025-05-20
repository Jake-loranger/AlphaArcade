//
//  AlgorandHelper.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 5/11/25.
//

import Foundation
import swift_algorand_sdk
import CryptoSwift

private extension Data {
    /// Exact SHA‑512/256 (Algorand variant) via CryptoSwift
    func sha512_256() -> Data {
        // use the 512‑bit algorithm truncated to 256 bits
        let hash = try! SHA2(variant: .sha512t256).calculate(for: Array(self))
        return Data(hash)   // 32 bytes
    }
}


private enum Algorand {
    static let appIDPrefix = "appID".data(using: .ascii)!                    // b"appID"
    static let checkSumLenBytes = 4                                          // 4‑byte checksum
    static let addressLen = appIDPrefix.count + 8 + checkSumLenBytes         // prefix + 8‑byte appID + checksum
    static let base32Alphabet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
}

class AlgorandHelper {

    let MICRO_UNIT: Double = 1_000_000.0
    var algodClient: AlgodClient
    var indexerClient: IndexerClient
    


    init() {
        algodClient = AlgodClient(
            host: "https://mainnet-api.algonode.cloud",
            port: "",
            token: ""
        )

        indexerClient = IndexerClient(
            host: "https://mainnet-idx.algonode.cloud",
            port: "",
            token: ""
        )
    }
    
    
    
    // MARK: – Base32 Encoding (RFC 4648, no padding)

    private func base32Encode(_ data: Data) -> String {
        var result = ""
        var buffer: UInt = 0
        var bitsLeft = 0

        for byte in data {
            buffer = (buffer << 8) | UInt(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                bitsLeft -= 5
                let index = Int((buffer >> bitsLeft) & 0x1F)
                result.append(Algorand.base32Alphabet[index])
            }
        }
        if bitsLeft > 0 {
            // pad the remaining bits
            let index = Int((buffer << (5 - bitsLeft)) & 0x1F)
            result.append(Algorand.base32Alphabet[index])
        }
        return result  // no “=” padding ever added
    }

    /// Return the escrow address of an Algorand application (exact match to Python SDK).
    /// - Parameter appID: numeric application ID (must be >= 0)
    /// - Returns: Base32-encoded escrow address (58-character string)
    func getApplicationAddress(appID: UInt64) -> String {
        // 1) to 8-byte big-endian
        var be = appID.bigEndian
        let appIDBytes = withUnsafeBytes(of: &be) { Data($0) }
        
        // 2) prefix + appID
        var payload = Data()
        payload.append(Algorand.appIDPrefix)
        payload.append(appIDBytes)
        
        // 3) compute SHA512/256 checksum and take last 4 bytes
        let fullHash = payload.sha512_256()
        let check = fullHash.suffix(Algorand.checkSumLenBytes)
        
        // 4) full address bytes
        var addrBytes = Data()
        addrBytes.append(payload)
        addrBytes.append(check)
        
        // 5) Base32 encode, no padding
        let encoded = base32Encode(addrBytes)
        return encoded
    }


    func getOrderBook(marketAppId: Int64, completion: @escaping (MarketOrderBook) -> Void) {
        // Step 1: Get market app info to retrieve its creator address
//        var test = indexerClient.lookUpApplicationLogsById(id: marketAppId).execute { response in
//            print(response)
//        }
//        
//        var test2 = indexerClient.searchForAccounts(applicationId: marketAppId).execute { response in
//            print(response)
//        }
//        
//        var test3 = indexerClient.lookUpApplicationsById(id: marketAppId).execute { response in
//            print(response)
//        }
//
        let test = getApplicationAddress(appID: 3004419219)

        
        indexerClient.lookUpApplicationsById(id: marketAppId).execute { appResponse in
            guard appResponse.isSuccessful,
                  let creator = appResponse.data?.application?.params?.creator else {
                print("❌ Failed to get creator for app ID \(marketAppId)")
                completion(self.emptyOrderbook())
                return
            }
            let app_info = self.decodeGlobalState(appResponse.data?.application?.params?.globalState)
            print(app_info)
            // Step 2: Get all applications created by this address (order contracts)
            self.indexerClient.lookUpAccountById(address: creator).execute { accountResponse in
                guard accountResponse.isSuccessful,
                      let createdApps = accountResponse.data?.account?.createdApps else {
                    print("❌ Failed to get created apps for address \(creator)")
                    completion(self.emptyOrderbook())
                    return
                }

                var decodedOrders: [[String: Any]] = []
//                let group = DispatchGroup()

                // Step 3: For each created app, fetch global state and decode
                // Each app here is a market
                for app in createdApps {
                    guard let appId = app.id else { continue }
//                    group.enter()
                    
                    if (appId == marketAppId) {
                        let decodedOrder = self.decodeGlobalState(app.params?.globalState)
                        decodedOrders.append(decodedOrder)
                    }
                    

//                    self.indexerClient.lookUpApplicationsById(id: appId).execute { orderAppResponse in
//                        defer { group.leave() }
//
//                        guard orderAppResponse.isSuccessful,
//                              let state = orderAppResponse.data?.application?.params?.globalState else {
//                            print("⚠️ Skipped app ID \(appId) — no global state")
//                            return
//                        }
//
//                        let decoded = self.decodeGlobalState(state)
//
//                    }
                }
                
                let marketData = self.aggregateOrderbook(decodedOrders)
                completion(["market": marketData])
                // Step 4: Aggregate once all async calls finish
//                group.notify(queue: .main) {
//                    let marketData = self.aggregateOrderbook(decodedOrders)
//                    completion(["market": marketData])
//                }
            }
        }
    }

    private func decodeGlobalState(_ raw: [TealKeyValue]?) -> [String: Any] {
        var decoded: [String: Any] = [:]
        guard let state = raw else { return decoded }

        for entry in state {
            let keyB64 = entry.key
            guard let keyData = Data(base64Encoded: keyB64),
                  let key = String(data: keyData, encoding: .utf8) else {
                continue
            }

            let value = entry.value

            switch value.type {
            case 1: // Bytes
                if let b64Bytes = value.bytes,
                   let rawBytes = Data(base64Encoded: b64Bytes) {
                    if key == "owner", rawBytes.count == 32 {
                        let address = try? Address(rawBytes.map { Int8(bitPattern: $0) }).description
                        decoded[key] = address ?? b64Bytes
                    } else {
                        decoded[key] = String(data: rawBytes, encoding: .utf8) ?? b64Bytes
                    }
                }
            case 2: // Uint
                if let uintVal = value.uint {
                    decoded[key] = uintVal
                }
            default:
                continue
            }
        }

        return decoded
    }


    private func filterOrders(_ orders: [[String: Any]], side: Int64, position: Int64) -> [[String: Any]] {
        return orders.filter {
            ($0["side"] as? Int64 == side) &&
            ($0["position"] as? Int64 == position) &&
            (($0["quantity"] as? Int64 ?? 0) > ($0["quantity_filled"] as? Int64 ?? 0)) &&
            ($0["slippage"] as? Int64 ?? 0) == 0
        }
    }

    private func aggregateOrders(_ orders: [[String: Any]]) -> [OrderEntry] {
        var priceMap: [Int64: Int64] = [:]

        for order in orders {
            let price = order["price"] as? Int64 ?? 0
            let quantity = order["quantity"] as? Int64 ?? 0
            let filled = order["quantity_filled"] as? Int64 ?? 0
            let remaining = quantity - filled

            if remaining > 0 && price > 0 {
                priceMap[price, default: 0] += remaining
            }
        }

        return priceMap.map { price, quantity in
            OrderEntry(
                price: Int(price),
                quantity: Int(quantity),
                total: Int((price * quantity) / Int64(MICRO_UNIT)) // total in microAlgos
            )
        }
    }

    private func aggregateOrderbook(_ orders: [[String: Any]]) -> MarketData {
        let yesBuy = filterOrders(orders, side: 1, position: 1)
        let yesSell = filterOrders(orders, side: 0, position: 1)
        let noBuy = filterOrders(orders, side: 1, position: 0)
        let noSell = filterOrders(orders, side: 0, position: 0)

        return MarketData(
            yes: OrderBook(bids: aggregateOrders(yesBuy), asks: aggregateOrders(yesSell)),
            no: OrderBook(bids: aggregateOrders(noBuy), asks: aggregateOrders(noSell))
        )
    }

    private func emptyOrderbook() -> MarketOrderBook {
        let empty = OrderBook(bids: [], asks: [])
        return ["market": MarketData(yes: empty, no: empty)]
    }
}
