//
//  Orderbook.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/12/25.
//

import Foundation

struct OrderEntry: Codable {
    let price: Int
    let quantity: Int
    let total: Int
}

struct OrderBook: Codable {
    let bids: [OrderEntry]
    let asks: [OrderEntry]
}

struct MarketData: Codable {
    let yes: OrderBook
    let no: OrderBook
}

typealias MarketOrderBook = [String: MarketData]
