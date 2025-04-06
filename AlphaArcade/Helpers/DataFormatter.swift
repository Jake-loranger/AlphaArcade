//
//  DataFormatter.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 4/6/25.
//

import Foundation

struct DataFormatter {

    // General-purpose formatter for currency or decimal values
    static func formattedValue(_ value: Double?) -> String {
        guard let value = value else {
            return "N/A"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "N/A"
    }

    // Formats the win rate as a percentage with 2 decimal places
    static func formattedWinRate(winningTrades: Int, totalTrades: Int) -> String {
        let winRate = Double(winningTrades) / Double(totalTrades)
        return String(format: "%.2f%%", winRate * 100)
    }

    // Formats total volume as a currency with comma separation
    static func formattedTotalVolume(grossAmountSold: Double, grossAmountBought: Double) -> String {
        let totalVolume = grossAmountSold + grossAmountBought
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: totalVolume)) ?? "$0.00"
    }
}
