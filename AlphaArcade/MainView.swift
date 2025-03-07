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
    let noData: [Double] = [100, 80, 15, 70, 25, 70, 35, 0]
    let yesColor: Color = Color.red
    let noColor: Color = Color.blue
    @State private var outcome: Bool = true
    
    
    var body: some View {
        VStack {
            HStack() {
                HStack {
                    // VStack aligned to leading
                    VStack(alignment: .leading) {
                        Text(outcome ? "Yes" : "No")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(outcome ? "91% Chance" : "9% Chance")
                            .font(.headline)
                            .foregroundColor(outcome ? yesColor : noColor)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // Align the VStack to leading edge
                    
                    // HStack aligned to trailing
                    HStack {
                        Button(action: { self.outcome = true }) {
                            Text("Yes")
                                .bold()
                                .foregroundColor(Color(red: 18/255, green: 197/255, blue: 208/255))
                        }
                        Button(action: { self.outcome = false }) {
                            Text("No")
                                .bold()
                                .foregroundColor(Color(red: 18/255, green: 197/255, blue: 208/255))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                }
                .padding(.bottom, 8)
            }
            
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
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color(red: 18/255, green: 197/255, blue: 208/255))
                }
            }
        }
        .padding()
        .frame(height: 300)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MarketOrderBookView: View {
    var body: some View {
        Text("Order Book View")
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding()
    }
}

struct MarketRulesView: View {
    var body: some View {
        Text("Rules View")
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MarketCommentsView: View {
    var body: some View {
        Text("Comments View")
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
