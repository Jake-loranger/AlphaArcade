//
//  MarketView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.activeMarkets.isEmpty {
                    Section(header: Text("Active Markets")) {
                        ForEach(viewModel.activeMarkets.sorted { ($0.featured ?? false) && !($1.featured ?? false) }) { market in
                            MarketItemView(market: market)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.fetchMarketData()
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
            await viewModel.fetchMarketData()
        }
    }
}


struct MarketItemView: View {
    let market: Market
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                AsyncImage(url: market.imageData ?? market.image) { phase in
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
                if let options = market.options, options.count > 1 {
                    
                    let colorOptions = OptionColor.colors
                    
                    ForEach(options.filter { $0.resolution == nil }.indices, id: \.self) { index in
                        let option = options[index]
                        
                        // Use modulo to cycle through colors based on the index
                        let colorOption: OptionColor = colorOptions[index % colorOptions.count]
                        
                        ProbabilityBarView(
                            label: option.label,
                            probability: (Double(option.yesProb ?? 0) / 10000),
                            color: colorOption.background
                        )
                    }
                } else {
                    // For cases with 1 or fewer options
                    ProbabilityBarView(label: "Yes", probability: market.yesProb ?? 0.0, color: OptionColor.optionOne.background)
                    ProbabilityBarView(label: "No", probability: market.noProb ?? 0.0, color: OptionColor.optionTwo.background)
                }
            }
            .padding(.vertical, 5)
            
            HStack {
                if let options = market.options, options.count > 1 {
                    // Calculate total volume from market options if there are more than 1 option
                    let totalVolume = DataFormatter.calculateTotalVolume(options: options)
                    
                    Text("$\(DataFormatter.formattedValue(totalVolume)) Vol.")
                        .font(.caption)
                } else {
                    // Display the volume from the market object for a single option
                    Text("$\(DataFormatter.formattedValue(market.volume ?? 0)) Vol.")
                        .font(.caption)
                }
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
                Text("\(Int(probability))% ∙ \(label)")
                    .padding(.leading, 8)
                    .bold()
                Spacer()
            }
            .frame(height: 30)
        }
        .frame(height: 30)
    }
}

