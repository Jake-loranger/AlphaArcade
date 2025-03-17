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

struct Order: Codable {
    
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
