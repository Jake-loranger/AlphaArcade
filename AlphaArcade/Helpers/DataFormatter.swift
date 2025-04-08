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
    
    static func formatTimestampToDate(_ timestampMilliseconds: Int) -> String {
        // Convert the milliseconds to seconds
        let timestampSeconds = TimeInterval(timestampMilliseconds) / 1000
        
        // Create a Date object
        let date = Date(timeIntervalSince1970: timestampSeconds)
        
        // Create a DateFormatter to format the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"  // Desired format: "DD MMM YYYY"
        let formattedDate = dateFormatter.string(from: date)
        
        return formattedDate
    }
    
    static func calculateTotalVolume(options: [Option]) -> Double {
            // Sum up the volume of all options, handling nil values by treating them as 0
            let totalVolume = options.reduce(0) { (result, option) in
                result + (option.volume ?? 0)
            }
            return totalVolume
        }

}
