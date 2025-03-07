//
//  MainView.swift
//  AlphaArcade
//
//  Created by Jacob Loranger on 3/6/25.
//

import SwiftUI
import Foundation
import Charts

struct MainView: View {
    var body: some View {
        TabView {
            MarketView()
                .tabItem {
                    Label("Markets", systemImage: "gamecontroller")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}

struct MarketView: View {
    @State private var activeMarkets: [Market] = []
    @State private var resolvedMarkets: [Market] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                if !activeMarkets.isEmpty {
                    Section(header: Text("Active")) {
                        ForEach(activeMarkets) { market in
                            NavigationLink(destination: MarketDetailView(market: market)) {
                                CustomItemView(title: market.title ?? "N/A", imageUrl: market.image)
                            }
                        }
                    }
                }
                
                if !resolvedMarkets.isEmpty {
                    Section(header: Text("Resolved")) {
                        ForEach(resolvedMarkets) { market in
                            NavigationLink(destination: MarketDetailView(market: market)) {
                                CustomItemView(title: market.title ?? "N/A", imageUrl: market.image)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await fetchMarketData()
            }
            .navigationTitle("Markets")
        }
        .task {
            await fetchMarketData()
        }
    }

    /// Fetches market data from API
    func fetchMarketData() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let apiURL = URL(string: "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-markets")!

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let decodedResponse = try JSONDecoder().decode(MarketResponse.self, from: data)

            DispatchQueue.main.async {
                self.activeMarkets = decodedResponse.markets.filter { $0.resolution == nil && $0.title != nil }
                self.resolvedMarkets = decodedResponse.markets.filter { $0.resolution != nil && $0.title != nil }
            }
        } catch {
            print("Failed to fetch data:", error)
        }
    }
}


struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("View your Portfolio here")
            }
            .navigationTitle("Profile")
        }
    }
}

struct CustomItemView: View {
    let title: String
    let imageUrl: URL?

    var body: some View {
        HStack {
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .empty:
                    ProgressView() // Show a loading spinner
                        .frame(width: 50, height: 50)
                case .success(let image):
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "photo") // Fallback image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            
            Text(title)
                .font(.headline)
                .padding(.leading, 8) // Add spacing between image and text
        }
        .padding(.vertical, 5)
    }
}

struct MarketDetailView: View {
    let market: Market
    @State private var showOrderView = false
    @State private var selectedOption: String? = nil

    var body: some View {
        VStack() {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    MarketTitleView(title: market.title, image: market.image)
                    MarketInfoView()
                    MarketChartView()
                    MarketOrderBookView()
                    MarketRulesView()
                    MarketCommentsView()
                }
                .padding()
            }
            
            OrderButtonsView { option in
                selectedOption = option
                showOrderView = true
            }
        }
        .sheet(isPresented: $showOrderView) {
            if let option = selectedOption {
                OrderView(option: option)
                    .id(option)
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
    var body: some View {
        // Use LazyVGrid for better handling of content
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], alignment: .leading, spacing: 16) {
            InfoItem(title: "Volume", value: "$1000")
            InfoItem(title: "Market Volume", value: "$5000")
            InfoItem(title: "Fees", value: "$10")
            InfoItem(title: "Date", value: "2025-03-06")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MarketChartView: View {
    let yesData: [Double] = [10, 20, 15, 30, 25, 40, 35, 100]
    let noData: [Double] = [70, 80, 15, 70, 25, 70, 35, 0]
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
    @State private var selectedOption: String = "Yes" // Default selection
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Trade")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Text("Selected: \(selectedOption)")
                .font(.headline)
                .padding(.top, 10)
            
            Picker("Select an option", selection: $selectedOption) {
                Text("Yes").tag("Yes")
                Text("No").tag("No")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MarketRulesView: View {
    @State private var showFullText: Bool = false  // Controls text expansion

    private let fullText = """
    This market will resolve to "Yes" if any one-minute Binance candle for Algorand (ALGOUSDT) between March 2, 2025, at 11:55 AM EST and March 7, 2025, at 23:59 ET records a final "High" price of $0.32 or more. Otherwise, it will resolve to "No."
    
    The resolution source is Binance, specifically the ALGOUSDT "High" prices available at https://www.binance.com/en/trade/ALGO_USDT?type=spot, with the chart set to "1m" for one-minute candles. Only price data from Binance’s ALGOUSDT trading pair will be considered.
    
    Prices from other exchanges, different trading pairs, or spot markets will not affect this market’s resolution.
    """

    var body: some View {
        VStack(alignment: .leading) {
            // Title
            Text("Rules")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(1)

            // Expandable Text
            Text(fullText)
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
        HStack {
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


struct OrderView: View {
    let option: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("You selected: \(option)")
                .font(.headline)

            Button(action: {
                dismiss()
            }) {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .presentationDetents([.medium, .large]) // Allows sliding height control
    }
}



/// Decodes API response while filtering out invalid data
struct MarketResponse: Codable {
    let markets: [Market]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawMarkets = try container.decode([Market?].self, forKey: .markets)
        
        // Remove any markets that are nil (invalid data)
        self.markets = rawMarkets.compactMap { $0 }
    }
}

struct Market: Identifiable, Codable {
    let id: String?
    let title: String?
    let resolution: Int?
    let image: URL?
    
    var uniqueID: String {
        id ?? UUID().uuidString
    }
}

#Preview {
    MainView()
}
