//
//  MarketDetailsView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI
import Charts

struct MarketDetailView: View {
    let market: Market
    @StateObject private var viewModel = MarketDetailViewModel()
    @State private var showOrderView = false
    @State private var selectedOption: String? = "yes"

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.marketDetails != nil && viewModel.marketComments != nil {
                ScrollView {
                    VStack(alignment: .leading) {
                        MarketTitleView(title: market.title, image: market.image)
                        MarketChartView()
                        MarketInfoView(volume: viewModel.marketDetails?.market.volume ?? 0, marketVolume: viewModel.marketDetails?.market.marketVolume ?? 0, fees: viewModel.marketDetails?.market.fees ?? 0, date: viewModel.marketDetails?.market.createdAtDate)
                        MarketOrderBookView(orderbook: viewModel.marketOrderbook)

                        MarketRulesView(market: market)
                        MarketCommentsView(marketComments: viewModel.marketComments ?? nil)
                    }
                    .padding()
                }
            } else if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
            
            OrderButtonsView { option in
                selectedOption = option
                DispatchQueue.main.async {
                    showOrderView = true
                }
            }
        }
        .onAppear {
            viewModel.fetchMarketDetails(marketId: market.id ?? "")
            viewModel.fetchComments(marketId: market.id ?? "")
            viewModel.fetchOrderbook(marketId: market.id ?? "")
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
        .background(Color.gray.opacity(0.1))
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
    let yesData: [Double] = [10, 20, 15, 30, 25, 40, 35, 91]
    let noData: [Double] = [90, 80, 85, 70, 75, 60, 65, 9]
    let yesColor: Color = Color.red
    let noColor: Color = Color.blue
    @State private var outcome: Bool = true  // Boolean for Yes/No selection
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(outcome ? "91% Chance" : "9% Chance")
                .font(.headline)
                .foregroundColor(outcome ? yesColor : noColor)
                .lineLimit(1)
                .padding(.bottom, 4)

            Chart {
                let data = outcome ? yesData : noData
                
                ForEach(data.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", data[index])
                    )
                    .foregroundStyle(outcome ? yesColor : noColor)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .padding(.bottom, 12)
            
            Picker("Select an option", selection: $outcome) {
                Text("Yes").tag(true)
                Text("No").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .frame(height: 300)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MarketOrderBookView: View {
    let orderbook: MarketOrderBook
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

                ForEach(orderbook.keys.sorted(), id: \.self) { marketId in
                    if let marketData = orderbook[marketId] {
                        OrderSectionView(
                            title: "Asks",
                            orders: selectedOption == "Yes" ? marketData.yes.asks : marketData.no.asks,
                            color: Color.red
                        )
                    }
                }
                
                Divider().padding(.vertical, 2)

                HStack {
                    Text("Last: ").foregroundColor(.gray)
                    Text("N/A").foregroundColor(.white) // Placeholder, update with real data
                    Spacer()
                    Text("Spread: ").foregroundColor(.gray)
                    Text("N/A").foregroundColor(.white) // Placeholder
                }
                .font(.system(size: 12))
                .padding(.vertical, 2)

                Divider().padding(.vertical, 2)
                
                ForEach(orderbook.keys.sorted(), id: \.self) { marketId in
                    if let marketData = orderbook[marketId] {
                        OrderSectionView(
                            title: "Bids",
                            orders: selectedOption == "Yes" ? marketData.yes.bids : marketData.no.bids,
                            color: Color.green
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
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


struct OrderSectionView: View {
    let title: String
    let orders: [OrderEntry]
    let color: Color

    let columns: [GridItem] = [
        GridItem(.fixed(50), alignment: .leading),
        GridItem(.flexible(), alignment: .trailing),
        GridItem(.flexible(), alignment: .trailing),
        GridItem(.flexible(), alignment: .trailing)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(color)
                .padding(.bottom, 1)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(orders, id: \.price) { order in
                    Text("") // Empty column for alignment
                    Text(String(format: "$%.2f", Double(order.price) / 1000000.0))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Text(String(format: "%.2f", Double(order.quantity) / 1000000.0))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Text(String(format: "$%.2f", Double(order.total) / 1000000000000.0))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
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
                .animation(.easeInOut, value: showFullText)

            // Show More / Show Less Button
            Button(action: { showFullText.toggle() }) {
                Text(showFullText ? "Show Less" : "Show More")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
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
                ForEach(marketComments!, id: \.senderWallet) { comment in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.senderWallet ?? "--")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.gray)

                        Text(comment.text ?? "--")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
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
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 18/255, green: 197/255, blue: 208/255))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Button(action: { onSelect("No") }) {
                Text("No")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 204/255, green: 17/255, blue: 207/255))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .shadow(radius: 3)
    }
}
