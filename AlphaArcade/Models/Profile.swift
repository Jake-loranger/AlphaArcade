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
    let marketID: Double?
    let orderSide: String?
    let orderPosition: Double?
    let orderPrice: Double?
    let orderQuantityFilled: Double?
    let orderQuantity: Double?
    let createdAt: Double?
}

struct Position: Codable {
    let title: String
    let image: URL
    let position: String
    let costBasis: Double // Position
    let totalInvested: Double // Risk
    let tokenBalance: Double // Shares/To win
    let price: Double // latest
    let current: Double
}
