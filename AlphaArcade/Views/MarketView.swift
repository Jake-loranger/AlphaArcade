//
//  MarketView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI


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
            
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw Response JSON:", jsonString)
//            }
//            
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
