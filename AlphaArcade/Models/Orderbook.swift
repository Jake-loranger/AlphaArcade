//
//  Orderbook.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/12/25.
//

import Foundation

struct Order: Codable {
    let price: Int
    let quantity: Int
    let total: Int
}

struct MarketSide: Codable {
    let bids: [Order]
    let asks: [Order]
}

struct OrderBook: Codable {
    let yes: MarketSide
    let no: MarketSide
}
