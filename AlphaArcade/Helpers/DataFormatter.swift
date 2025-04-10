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

    // MARK: - Build the Series Data
    static func buildPriceSeries(matches: [Match], options: [Option]) -> [OptionPriceSeries] {
        // Group matches by marketId (which corresponds to the option id)
        let grouped = Dictionary(grouping: matches, by: { $0.marketId ?? "" })
        var seriesArray: [OptionPriceSeries] = []
        
        for (index, option) in options.enumerated() {
            let optionID = option.id
            let optionLabel = option.label
            
            // Determine the custom color for this option (e.g., based on array index)
            let optionColor = OptionColor.colors[index % OptionColor.colors.count].outline
            
            // Filter and sort matches that belong to this option by createdAt timestamp
            let optionMatches = (grouped[optionID] ?? []).sorted {
                ($0.createdAt ?? 0) < ($1.createdAt ?? 0)
            }
            
            // Map the matches' price data to the "Yes" probability value
            let values = optionMatches.compactMap { match -> Double? in
                guard let price = match.price else { return nil }
                return Double(price) / 10000.0
            }
            
            // Only add series if there's at least one value
            if !values.isEmpty {
                let series = OptionPriceSeries(id: optionID, label: optionLabel, values: values, displayColor: optionColor)
                seriesArray.append(series)
            }
        }
        
        return seriesArray
    }

    // MARK: - Padding Function
    static func padSeries(_ series: [OptionPriceSeries]) -> [OptionPriceSeries] {
        // Determine the maximum number of data points in any series
        guard let maxCount = series.map({ $0.values.count }).max() else {
            return series
        }
        
        // For each series that has less than maxCount values, pad it with its last known value
        let paddedSeries = series.map { series -> OptionPriceSeries in
            var paddedValues = series.values
            if let lastValue = paddedValues.last, paddedValues.count < maxCount {
                // Append the last value until the count reaches maxCount
                paddedValues.append(contentsOf: Array(repeating: lastValue, count: maxCount - paddedValues.count))
            }
            return OptionPriceSeries(id: series.id, label: series.label, values: paddedValues, displayColor: series.displayColor)
        }
        
        return paddedSeries
    }
}
