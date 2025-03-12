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
    let createdAt: Date?
    let rules: String?
}

struct Match: Codable {
    let quantity: Int?
    let createdAt: Double?
    let dataType: String?
    let price: Int?
    let marketId: String?
}

struct Comments: Codable {
    let comments: [Comment]
}

struct Comment: Codable {
    let text: String?
    let senderWallet: String?
    let updatedAt: Int?
}
