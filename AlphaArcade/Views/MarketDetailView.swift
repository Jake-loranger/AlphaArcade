//
//  MarketDetailsView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI
import Charts

struct MarketDetailView: View {
    let marketId: String?
    let market: Market?

    @StateObject private var viewModel = MarketDetailViewModel()
    @State private var showOrderView = false
    @State private var selectedOption: String? = "Yes"
    @State private var isDataLoaded = false
    
    
    var isMultiOptioned: Bool {
        guard let options = viewModel.options else {
            return false
        }
        return options.count >= 2
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if let marketDetails = viewModel.marketDetails,
                          let marketComments = viewModel.marketComments {
                    ScrollView {
                        VStack(alignment: .leading) {
                            MarketTitleView(title: marketDetails.market.topic, image: marketDetails.market.image)
                            if isMultiOptioned {
                                MultiMarketChartView(matches: marketDetails.matches, market: marketDetails.market, options: viewModel.options)
                            } else {
                                BinaryMarketChartView(matches: marketDetails.matches, market: marketDetails.market, options: viewModel.options)
                            }
                            MarketInfoView(volume: marketDetails.market.volume, marketVolume: marketDetails.market.marketVolume, fees: marketDetails.market.fees, date: marketDetails.market.createdAtDate)
                            MarketOrderBookView(orderbook: viewModel.marketOrderbook, market: marketDetails.market)
                            MarketRulesView(market: marketDetails.market)
                            MarketCommentsView(marketComments: marketComments)
                        }
                        .padding(.bottom, 100)
                        .padding(.horizontal)
                    }
                    .onAppear {
                        isDataLoaded = true
                    }
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }

            if isDataLoaded {
                OrderButtonsView { option in
                    selectedOption = option
                    withAnimation {
                        showOrderView = true
                    }
                }
                .padding(.bottom)
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
        .onAppear {
            fetchData()
        }
        .refreshable {
            fetchData()
        }
        .sheet(isPresented: $showOrderView) {
            if let option = selectedOption {
                OrderView(option: option)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func fetchData() {
        if let market = market {
            viewModel.fetchMarketOptions(marketId: market.id ?? "")
            viewModel.fetchMarketDetails(marketId: market.id ?? "")
            viewModel.fetchComments(marketId: market.id ?? "")
            viewModel.fetchOrderbook(marketId: market.id ?? "")
        } else if let marketId = marketId {
            viewModel.fetchMarketOptions(marketId: marketId)
            viewModel.fetchMarketDetails(marketId: marketId)
            viewModel.fetchComments(marketId: marketId)
            viewModel.fetchOrderbook(marketId: marketId)
        }
    }
}


struct MarketTitleView: View {
    let title: String?
    let image: URL?
    
    var body: some View {
        HStack(alignment: .top) {
            if let imageUrl = image {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure(_):
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            Text(title ?? "Unknown Market")
                .padding(.leading, 4)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MarketInfoView: View {
    let volume: Double?
    let marketVolume: Double?
    let fees: Double?
    let date: Date?
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], alignment: .leading, spacing: 16) {
            InfoItem(title: "Volume", value: formattedNumber(volume))
            InfoItem(title: "Market Volume", value: formattedNumber(marketVolume))
            InfoItem(title: "Fees", value: formattedNumber(fees))
            InfoItem(title: "Date", value: formattedDate(date))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // Helper function to format numbers
    func formattedNumber(_ value: Double?) -> String {
        guard let value = value else { return "N/A" }
        return String(format: "$%.2f", value / 1_000_000) // Formats as millions with 2 decimal places
    }
    
    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // Ensures output like "2025-07-01"
        return formatter.string(from: date)
    }
}

struct BinaryMarketChartView: View {
    var matches: [Match]
    var market: Market
    var options: [Option]?

    // Create the Yes and No price data arrays
    var yesData: [Double] {
        matches.compactMap { match in
            guard let price = match.price else { return nil }
            return Double(price) / 10000.0 // Yes Price
        } 
    }
    
    var noData: [Double] {
        matches.compactMap { match in
            guard let price = match.price else { return nil }
            return 100.0 - (Double(price) / 10000.0) // No Price
        }
    }
    
    var data: [(type: String, values: [Double])] {
        [
            (type: "Yes", values: yesData),
            (type: "No", values: noData)
        ]
    }

    var body: some View {
        VStack(alignment: .leading) {
            
            Chart(data, id: \.type) { dataSeries in
                ForEach(dataSeries.values.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", dataSeries.values[index])
                    )
                }
                .foregroundStyle(by: .value("Type", dataSeries.type))
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .opacity(0.8)
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale([
                "Yes": OptionColor.optionOne.outline,
                "No": OptionColor.optionTwo.outline
            ])
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .offset(x: 6)
                }
            }
            .padding(.vertical, 8)
            .frame(height: 200)
            
            HStack(spacing: 16) {
                HStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(OptionColor.optionTwo.outline)
                            .frame(width: 6, height: 6)
                            .padding(.top, 4)
                        Text("No")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(market.noProb != nil ? "\(market.noProb! / 10000, specifier: "%.1f")%" : "-")
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                    }
                    
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(OptionColor.optionOne.outline)
                            .frame(width: 6, height: 6)
                            .padding(.top, 4)
                        Text("Yes")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(market.yesProb != nil ? "\(market.yesProb! / 10000, specifier: "%.1f")%" : "-")
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.top, 6)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// Helper struct for chart series data
struct OptionPriceSeries: Identifiable {
    let id: String      // Option ID
    let label: String   // Option label (will be used as the series type)
    var values: [Double]    // Converted yes probability values (ordered by time)
    let displayColor: Color // Color for this series
}

// MARK: - Build the Series Data
func buildPriceSeries(matches: [Match], options: [Option]) -> [OptionPriceSeries] {
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
func padSeries(_ series: [OptionPriceSeries]) -> [OptionPriceSeries] {
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

// MARK: - MultiMarketChartView Implementation

struct MultiMarketChartView: View {
    var matches: [Match]
    var market: Market
    var options: [Option]?
    
    // Build and pad the series data
    var seriesData: [OptionPriceSeries] {
        guard let options = options else { return [] }
        let builtSeries = buildPriceSeries(matches: matches, options: options)
        return padSeries(builtSeries)
    }
    
    // Compute the overall minimum and maximum values from your seriesData
    var yMin: Double {
        let allValues = seriesData.flatMap { $0.values }
        guard let minVal = allValues.min() else { return 0 }
        return minVal - (minVal * 0.05) // 5% padding below min
    }

    var yMax: Double {
        let allValues = seriesData.flatMap { $0.values }
        guard let maxVal = allValues.max() else { return 100 }
        return maxVal + (maxVal * 0.05) // 5% padding above max
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // SwiftUI Chart with the same Y axis scale for all series.
            Chart {
                ForEach(seriesData) { series in
                    ForEach(series.values.indices, id: \.self) { index in
                        LineMark(
                            x: .value("Time Index", index),
                            y: .value("Yes Price", series.values[index])
                        )
                        .foregroundStyle(by: .value("Type", series.label))
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .opacity(0.8)
                    }
                }
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale(
                domain: seriesData.map { $0.label },
                range: seriesData.map { $0.displayColor }
            )
            .chartYScale(domain: yMin...yMax)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel().offset(x: 6)
                }
            }
            .padding(.vertical, 8)
            .frame(height: 200)
            
            // Example label grid below the chart to show each option's info
            HStack(spacing: 16) {
                let columns: [GridItem] = [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    if let options = options {
                        ForEach(Array(options.enumerated()), id: \.1.id) { index, option in
                            let optionColor = OptionColor.colors[index % OptionColor.colors.count].outline
                            HStack(alignment: .top, spacing: 6) {
                                Circle()
                                    .fill(optionColor)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 4)
                                Text(option.label)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                Text(option.yesProb != nil ?
                                     "\(option.yesProb! / 10000, specifier: "%.1f")%" : "-")
                                    .font(.system(size: 12, weight: .bold))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.top, 6)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MarketOrderBookView: View {
    @State var orderbook: MarketOrderBook
    @State var market: Market?
    @State private var selectedOption: String = "Yes"

    let columns: [GridItem] = [
        GridItem(.fixed(50), alignment: .leading),
        GridItem(.flexible(), alignment: .trailing),
        GridItem(.flexible(), alignment: .trailing),
        GridItem(.flexible(), alignment: .trailing)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            if orderbook != nil {
                LazyVGrid(columns: columns, spacing: 4) {
                    Text("Trade").font(.system(size: 14)).foregroundColor(.gray)
                    Text("Price").font(.system(size: 14)).foregroundColor(.gray)
                    Text("Shares").font(.system(size: 14)).foregroundColor(.gray)
                    Text("Total").font(.system(size: 14)).foregroundColor(.gray)
                }
                .padding(.bottom, 4)
                
                    Text("Asks")
                        .font(.system(size: 14))
                        .foregroundColor(Color.red)
                        .padding(.bottom, 1)

                ForEach(orderbook.keys.sorted(), id: \.self) { marketId in
                    if let marketData = orderbook[marketId] {
                        OrderSectionView(
                            orders: (selectedOption == "Yes" ? marketData.yes.asks : marketData.no.asks)
                                .sorted { $0.price > $1.price }
                        )
                    }
                }

                Divider().padding(.vertical, 2)
                
                HStack {
                    Text("Last: ").foregroundColor(.gray)
                    
                    Text(market?.lastTradePrice != nil ? String(format: "¢%.2f", (market?.lastTradePrice ?? 0.0) / 10000)  : "-")
                    
                    Spacer()
                    
                    Text("Spread: ").foregroundColor(.gray)
                    
                    Text(market?.currentSpread != nil ? String(format: "¢%.2f", (market?.currentSpread ?? 0.0) / 10000) : "-")
                        
                }
                .font(.system(size: 12))
                .padding(.vertical, 2)
                
                Divider().padding(.vertical, 2)

                Text("Bids")
                    .font(.system(size: 14))
                    .foregroundColor(Color.green)
                    .padding(.bottom, 1)

                ForEach(orderbook.keys.sorted(), id: \.self) { marketId in
                    if let marketData = orderbook[marketId] {
                        OrderSectionView(
                            orders: (selectedOption == "Yes" ? marketData.yes.bids : marketData.no.bids)
                                .sorted { $0.price > $1.price }
                        )
                    }
                }

                Picker("Select an option", selection: $selectedOption) {
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 12)
            } else {
                ProgressView("Loading Orderbook...")
                    .padding()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct OrderSectionView: View {
    let orders: [OrderEntry]

    let columns: [GridItem] = [
        GridItem(.fixed(50), alignment: .leading),
        GridItem(.flexible(), alignment: .trailing),
        GridItem(.flexible(), alignment: .trailing),
        GridItem(.flexible(), alignment: .trailing)
    ]

    var body: some View {
        VStack(alignment: .leading) {

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(orders, id: \.price) { order in
                    Text("")
                    Text(String(format: "$%.2f", Double(order.price) / 1000000.0))
                        .font(.system(size: 12))
                    Text(String(format: "%.2f", Double(order.quantity) / 1000000.0))
                        .font(.system(size: 12))
                    Text(String(format: "$%.2f", Double(order.total) / 1000000000000.0))
                        .font(.system(size: 12))
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct MarketRulesView: View {
    @State var market: Market
    @State private var showFullText: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Rules")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Expandable Text
            Text(market.rules ?? "Cannot recieve rules at this moment")
                .font(.system(size: 14)) // Paragraph font size
                .lineLimit(showFullText ? nil : 3) // Show 3 lines before truncation
                .padding(.top, 2)

            // Show More / Show Less Button
            Button(action: { showFullText.toggle() }) {
                Text(showFullText ? "Show Less" : "Show More")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct MarketCommentsView: View {
    @State var marketComments: [Comment]?

    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Comments")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(1)

            // Comments List
            VStack(alignment: .leading, spacing: 8) {
                if let comments = marketComments, !comments.isEmpty {
                        ForEach(comments, id: \.senderWallet) { comment in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(comment.senderWallet ?? "--")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.gray)
                                    .truncationMode(.middle)
                                    .lineLimit(1)

                                Text(comment.text ?? "--")
                                    .font(.system(size: 14))
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                            Text("No Comments")
                                .foregroundColor(.gray)
                                .font(.system(size: 10))
                                .italic()
                                .padding(.vertical, 8)
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct InfoItem: View {
    let title: String
    let value: String
    
    @ScaledMetric var titleFontSize: CGFloat = 14
    @ScaledMetric var valueFontSize: CGFloat = 16
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: titleFontSize))
                .foregroundColor(.gray)
                .lineLimit(1)
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold))
                .lineLimit(1)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OrderButtonsView: View {
    var onSelect: (String) -> Void
    
    var body: some View {
        HStack(spacing: 16) { // Add spacing between buttons
            Button(action: { onSelect("Yes") }) {
                Text("Yes")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(OptionColor.optionOne.background)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(OptionColor.optionOne.outline, lineWidth: 1)
                    )
                    .foregroundColor(Color.white)
                    .shadow(color: OptionColor.optionOne.outline.opacity(0.5), radius: 6)
            }

            Button(action: { onSelect("No") }) {
                Text("No")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(OptionColor.optionTwo.background)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(OptionColor.optionTwo.outline, lineWidth: 1)
                    )
                    .foregroundColor(Color.white)
                    .shadow(color: OptionColor.optionTwo.outline.opacity(0.5), radius: 6)
            }
        }
        .padding([.leading, .trailing])
        .shadow(color: Color.black, radius: 50, x: 0, y: 20)

    }
}
