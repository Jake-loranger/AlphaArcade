//
//  MarketView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI

struct MarketView: View {
    @State private var activeMarkets: [Market] = []
    @State private var resolvedMarkets: [Market] = []
    @State private var isLoading = false
    private let session = URLSession(configuration: .default)
    
    var body: some View {
        NavigationStack {
            List {
                   if !activeMarkets.isEmpty {
                       Section(header: Text("Active Markets")) {
                           ForEach(activeMarkets) { market in
                               MarketItemView(market: market)
                                   .task { try? await downloadImage(for: market) }
                           }
                       }
                   }
               }
            .refreshable {
                await fetchMarketData()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("HorizontalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 42)
                        .padding([.leading, .bottom], 8)
                }
            }
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
                self.activeMarkets = decodedResponse.markets.filter { $0.resolution == nil && $0.title != nil && $0.options?.count == 1}
                self.resolvedMarkets = decodedResponse.markets.filter { $0.resolution != nil && $0.title != nil }
            }
        } catch {
            print("Failed to fetch data:", error)
        }
    }
    
    func downloadImage(for market: Market) async throws {
        guard let index = self.activeMarkets.firstIndex(where: { $0.id == market.id }),
              self.activeMarkets[index].imageDataURL == nil,
              let imageURL = market.image
        else { return }

        let (data, _) = try await session.data(from: imageURL)
        let dataURL = URL(string: "data:image/png;base64," + data.base64EncodedString())
        self.activeMarkets[index].imageDataURL = dataURL
    }
}



struct MarketItemView: View {
    let market: Market
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                AsyncImage(url: market.imageDataURL ?? market.image) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image.resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Text(market.title ?? "Loading...")
                    .font(.headline)
                    .padding(.leading, 8)
            }
            .padding(.vertical, 5)
            
            VStack {
                ProbabilityBarView(label: "Yes", probability: market.yesProb ?? 0.0, color: OptionColor.optionOne.background)
                ProbabilityBarView(label: "No", probability: market.noProb ?? 0.0, color: OptionColor.optionTwo.background)
            }
            .padding(.vertical, 5)
            
            HStack {
                Text("$\(DataFormatter.formattedValue(market.volume ?? 0)) Vol.")
                    .font(.caption)
                Spacer()
                Image(systemName: "bubble.left")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(market.comments ?? 0) ")
                    .font(.caption)
            }
            .padding(.vertical, 5)

        }
        .background(
            NavigationLink(destination: MarketDetailView(marketId: nil, market: market)) {
                EmptyView() // Empty view ensures no visible chevron
            }
            .opacity(0) // Make the NavigationLink completely transparent
        )
    }
}

struct ProbabilityBarView: View {
    let label: String
    let probability: Double
    let color: Color
    
    
    let barWidth: CGFloat = 300
    

    var body: some View {
        ZStack(alignment: .leading) {
            // Background bar
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray4))
                .frame(height: 30)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: barWidth * CGFloat(probability / 100), height: 30)

            HStack {
                Text("\(label) ∙ \(Int(probability))%")
                    .padding(.leading, 8)
                    .bold()
                Spacer()
            }
            .frame(height: 30)
        }
        .frame(height: 30)
    }
}

