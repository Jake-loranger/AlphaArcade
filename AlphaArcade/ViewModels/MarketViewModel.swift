//
//  MarketViewModel.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 4/7/25.
//

import Foundation
import SwiftUI

@MainActor
class MarketViewModel: ObservableObject {
    @Published var activeMarkets: [Market] = []
    @Published var resolvedMarkets: [Market] = []
    @Published var isLoading: Bool = false

    private let session = URLSession(configuration: .default)

    func fetchMarketData() async {
            guard !isLoading else { return }
            isLoading = true
            defer { isLoading = false }

            let apiURL = URL(string: "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-markets")!

            do {
                let (data, _) = try await URLSession.shared.data(from: apiURL)
                
                let decodedResponse = try JSONDecoder().decode(MarketResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.activeMarkets = decodedResponse.markets.filter { $0.resolution == nil && $0.title != nil}
                    self.resolvedMarkets = decodedResponse.markets.filter { $0.resolution != nil && $0.title != nil }
                }
                
                for market in decodedResponse.markets {
                            // Only download image if needed (optional)
                            if market.imageData == nil, let imageURL = market.image {
                                try? await downloadImage(for: market)
                            }
                        }
            } catch {
                print("Failed to fetch data:", error)
            }
        }

    func downloadImage(for market: Market) async throws {
        guard let index = self.activeMarkets.firstIndex(where: { $0.id == market.id }),
              self.activeMarkets[index].imageData == nil,
              let imageURL = market.image
        else { return }

        let (data, _) = try await session.data(from: imageURL)
        let dataURL = URL(string: "data:image/png;base64," + data.base64EncodedString())
        self.activeMarkets[index].imageData = dataURL
    }
}
