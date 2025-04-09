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
                            MarketChartView(matches: marketDetails.matches, market: marketDetails.market)
                            MarketInfoView(volume: marketDetails.market.volume, marketVolume: marketDetails.market.marketVolume, fees: marketDetails.market.fees, date: marketDetails.market.createdAtDate)
                            MarketOrderBookView(orderbook: viewModel.marketOrderbook, market: marketDetails.market)
                            MarketRulesView(market: marketDetails.market)
                            MarketCommentsView(marketComments: marketComments)
                        }
                        .padding(.bottom, 100) // Make room for sticky button
                        .padding(.horizontal)
                    }
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }

            // Sticky button view on top
            OrderButtonsView { option in
                selectedOption = option
                withAnimation {
                    showOrderView = true
                }
            }
            .padding(.bottom)
        }
        .onAppear {
            if let market = market {
                viewModel.fetchMarketDetails(marketId: market.id ?? "")
                viewModel.fetchComments(marketId: market.id ?? "")
                viewModel.fetchOrderbook(marketId: market.id ?? "")
            } else if let marketId = marketId {
                viewModel.fetchMarketDetails(marketId: marketId)
                viewModel.fetchComments(marketId: marketId)
                viewModel.fetchOrderbook(marketId: marketId)
            }
        }
        .refreshable {
            if let market = market {
                viewModel.fetchMarketDetails(marketId: market.id ?? "")
                viewModel.fetchComments(marketId: market.id ?? "")
                viewModel.fetchOrderbook(marketId: market.id ?? "")
            } else if let marketId = marketId {
                viewModel.fetchMarketDetails(marketId: marketId)
                viewModel.fetchComments(marketId: marketId)
                viewModel.fetchOrderbook(marketId: marketId)
            }
        }
        .sheet(isPresented: $showOrderView) {
            if let option = selectedOption {
                OrderView(option: option)
                    .presentationDetents([.medium, .large])
            }
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

struct MarketChartView: View {
    var matches: [Match]
    var market: Market

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
    
    // Combine Yes and No data into a structured format
    var data: [(type: String, values: [Double])] {
        [
            (type: "Yes", values: yesData),
            (type: "No", values: noData)
        ]
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("No")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                Text(market.noProb != nil ? "\(market.noProb! / 10000, specifier: "%.1f")%" : "-")
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .padding(.trailing, 6)
                Text("Yes")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                Text(market.yesProb != nil ? "\(market.yesProb! / 10000, specifier: "%.1f")%" : "-")
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
            }

            // Chart rendering
            Chart(data, id: \.type) { dataSeries in
                ForEach(dataSeries.values.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", dataSeries.values[index])
                    )
                }
                .foregroundStyle(by: .value("Type", dataSeries.type)) // Apply different colors for Yes and No
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .opacity(0.8)
            }
            .chartForegroundStyleScale([
                "Yes": OptionColor.optionOne.outline,
                "No": OptionColor.optionTwo.outline
            ])
            .chartYScale(domain: 0...100) // Y-axis domain for scaling
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel() // Show labels on Y axis
                }
            }
            .padding(.vertical, 6)
        }
        .padding()
        .frame(height: 300)
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

                                Text(comment.text ?? "--")
                                    .font(.system(size: 14))
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("None")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                            .italic()
                            .padding(.vertical, 8)
                    }
            }
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
                    .shadow(color: OptionColor.optionOne.outline.opacity(0.5), radius: 8)
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
                    .shadow(color: OptionColor.optionTwo.outline.opacity(0.5), radius: 8)
            }
        }
        .padding([.leading, .trailing])
        .shadow(color: Color.black, radius: 50, x: 0, y: 20)

    }
}
