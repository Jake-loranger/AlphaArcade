//
//  Profile.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/17/25.
//

import Foundation

struct Profile: Codable {
    let openOrders: [Order]
    let currentpostions: [Position]
}

struct OrdersResponse: Codable {
    let orders: [Order]
}

struct Order: Codable {
    let marketId: String?
    var title: String?
    var image: URL?
    let orderSide: String?
    let orderPosition: Double?
    let orderPrice: Double?
    let orderQuantityFilled: Double?
    let orderQuantity: Double?
    let createdAt: Double?
}



struct PositionResponse: Codable {
    let participants: [Position]
}


struct Position: Codable {
    let marketId: String?
    var title: String?
    var image: URL?
    var lastTradePrice: Double?
    let yesTokenBalance: Double?
    let noTokenBalance: Double?
    let hasClaimed: Int?
    let noCostBasis: Double?
    let yesCostBasis: Double?
    let createdAt: Double?
    let totalInvested: Double?
    let totalReturned: Double?
}

struct FormattedPosition: Codable {
    let marketId: String?
    let title: String?
    let image: URL?
    let position: String?
    let costBasis: Double? // Position
    let totalInvested: Double? // Risk
    let tokenBalance: Double? // Shares/To win
    let price: Double? // latest
    let current: Double?
}

