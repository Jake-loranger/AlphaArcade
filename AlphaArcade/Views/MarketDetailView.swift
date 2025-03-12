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
            } else if viewModel.marketDetails != nil {
                ScrollView {
                    VStack(alignment: .leading) {
                        MarketTitleView(title: market.title, image: market.image)
                        MarketChartView()
                        MarketInfoView(volume: viewModel.marketDetails?.market.volume ?? 0, marketVolume: viewModel.marketDetails?.market.marketVolume ?? 0, fees: viewModel.marketDetails?.market.fees ?? 0, date: viewModel.marketDetails?.market.createdAt)
                        MarketOrderBookView()
                        MarketRulesView(market: market)
                        MarketCommentsView()
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
            
            // Print the market details once the data is loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if let details = viewModel.marketDetails {
                                print("Market Details:", details)
                            } else if let error = viewModel.errorMessage {
                                print("Error Fetching Market Details:", error)
                            }
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
        // Use LazyVGrid for better handling of content
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], alignment: .leading, spacing: 16) {
            InfoItem(title: "Volume", value: "$\(volume ?? 0)")  // Corrected string interpolation
            InfoItem(title: "Market Volume", value: "$\(marketVolume ?? 0)")  // Corrected string interpolation
            InfoItem(title: "Fees", value: "$\(fees ?? 0)")  // Corrected string interpolation
            InfoItem(title: "Date", value: formattedDate(date))  // Formatted date
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // Helper function to format the date
    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
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
    @State private var selectedOption: String = "Yes" // Picker selection
    
    // Dummy data
    let yesAsk: [(price: Double, quantity: Double, total: Double)] = [
        (0.99, 100, 99),
        (0.75, 50, 87.5),
        (0.51, 30, 45.3)
    ]
    let yesBid: [(price: Double, quantity: Double, total: Double)] = [
        (0.44, 100, 44),
        (0.25, 50, 87.5),
        (0.51, 30, 45.3)
    ]
    let noAsk: [(price: Double, quantity: Double, total: Double)] = [
        (0.99, 100, 999),
        (0.75, 50, 87.5),
        (0.51, 30, 45.3)
    ]
    let noBid: [(price: Double, quantity: Double, total: Double)] = [
        (0.99, 100, 999),
        (0.75, 50, 87.5),
        (0.51, 30, 45.3)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header Row (Trade, Price, Shares, Total)
            HStack {
                Text("Trade")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: 50, alignment: .leading)
                Text("Price")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Shares")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Total")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.bottom, 4)
            
            // Asks Section
            HStack {
                Text("Asks")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
            ForEach(selectedOption == "Yes" ? yesAsk : noAsk, id: \.price) { ask in
                HStack {
                    Text("")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(width: 50, alignment: .leading)
                    Text(String(format: "$%.2f", ask.price))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(String(format: "%.0f", ask.quantity))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(String(format: "$%.2f", ask.total))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.bottom, 4)
            }
            
            Divider()
                .padding(.vertical, 2)
            
            // Last and Spread Section
            HStack {
                HStack {
                    Text("Last:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("39¢")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("Spread:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("1.0¢")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Divider()
                .padding(.vertical, 2)
            
            // Bids Section
            HStack {
                Text("Bids")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .lineLimit(1)
            }
            ForEach(selectedOption == "Yes" ? yesBid : noBid, id: \.price) { bid in
                HStack {
                    Text("")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .leading)
                    Text(String(format: "$%.2f", bid.price))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(String(format: "%.0f", bid.quantity))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(String(format: "$%.2f", bid.total))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.bottom, 4)
            }
            
            // Picker for selection between "Yes" and "No"
            Picker("Select an option", selection: $selectedOption) {
                Text("Yes").tag("Yes")
                Text("No").tag("No")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top, 12)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
    // Dummy data: list of (username, comment)
    let comments: [(username: String, comment: String)] = [
        ("CryptoTrader69.algo", "I think this market is undervaluing the chance of a breakout! 🚀"),
        ("AlgoFan23.algo", "Binance data is solid, but keep an eye on the order book.")
    ]

    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Comments")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(1)

            // Comments List
            VStack(alignment: .leading, spacing: 8) {
                ForEach(comments, id: \.username) { comment in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(comment.username)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.gray)

                        Text(comment.comment)
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
