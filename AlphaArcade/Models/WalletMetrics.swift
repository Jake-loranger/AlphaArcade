//
//  WalletMetric.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 4/2/25.
//

import Foundation

struct DailyMetric: Codable {
    let date: String
    let trades: Int
    let profit: Double
    let loss: Double
    let buyVolume: Double
    let sellVolume: Double
}

struct CategoryMetric: Codable {
    let trades: Int
    let grossProfit: Double
    let grossLoss: Double
    let netProfit: Double
}

struct WalletMetrics: Codable {
    let grossProfit: Double
    let grossLoss: Double
    let netProfit: Double
    let tradingPL: Double
    let claimPnL: Double
    let claimLosses: Double
    let totalClaimed: Double
    let winningTrades: Int
    let losingTrades: Int
    let totalTrades: Int
    let averageReturnPerTrade: Double
    let grossAmountBought: Double
    let grossAmountSold: Double
    let currentPortfolioValue: Double
    let dailyMetrics: [DailyMetric]
    let categoryMetrics: [String: CategoryMetric]
}
