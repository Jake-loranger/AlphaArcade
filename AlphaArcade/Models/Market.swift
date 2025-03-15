//
//  Market.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/9/25.
//

import Foundation

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
    let resolution: Int?
    let image: URL?
    let volume: Double?
    let marketVolume: Double?
    let fees: Double?
    let createdAt: Int?
    let rules: String?
    let currentSpread: Double?
    let lastTradePrice: Double?
    let noProb: Double?
    let yesProb: Double?
    let options: [Option]?
    
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

struct Option: Codable {
    let label: String
}
