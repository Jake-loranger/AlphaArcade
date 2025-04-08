//
//  Market.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/9/25.
//

import Foundation

/// Decodes API response while filtering out invalid data
struct MarketResponse: Codable {
    let markets: [Market]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawMarkets = try container.decode([Market?].self, forKey: .markets)
        
        // Remove any markets that are nil (invalid data)
        self.markets = rawMarkets.compactMap { $0 }
    }
}

// Model for the market details
struct MarketDetail: Codable {
    let market: Market
    let matches: [Match]
    
    enum CodingKeys: String, CodingKey {
        case market
        case matches
    }
}

struct Market: Identifiable, Codable {
    let id: String?
    let title: String?
    let topic: String?
    let resolution: Int?
    let image: URL?
    var imageData: URL?
    let volume: Double?
    let marketVolume: Double?
    let fees: Double?
    let createdAt: Int?
    let endTs: Int?
    let comments: Int?
    let rules: String?
    let currentSpread: Double?
    let lastTradePrice: Double?
    let noProb: Double?
    let yesProb: Double?
    let options: [Option]?
    let featured: Bool?
    
    var createdAtDate: Date? {
        guard let timestamp = createdAt else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
    }
}

struct Match: Codable {
    let quantity: Int?
    let createdAt: Double?
    let dataType: String?
    let price: Int?
    let marketId: String?
}

struct Option: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let image: URL?
    let volume: Double?
    let yesProb: Double?
    let noProb: Double?
    let comments: Int?
    let yesAssetId: Int?
    let noAssetId: Int?
    let resolution: Int?
}
