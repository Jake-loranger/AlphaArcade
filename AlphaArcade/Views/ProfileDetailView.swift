//
//  ProfileDetailView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/19/25.
//

import SwiftUI

struct ProfileDetailView: View {
    let walletInput: String
    let walletAddress: String
    @StateObject var viewModel: ProfileDetailViewModel
    @State private var selectedTab = "Positions"
    
    init(walletInput: String) {
        self.walletInput = walletInput
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Picker("Select", selection: $selectedTab) {
                    Text("Positions").tag("Positions")
                    Text("Orders").tag("Orders")
                }
                .pickerStyle(.segmented)
                .padding([.top, .leading, .trailing])

                if selectedTab == "Orders" {
                    OpenOrdersView(viewModel: viewModel)
                        .padding()
                } else {
                    PositionsView(currentPositions: viewModel.currentPositions)
                        .padding()
                }
                Spacer()
            }
        }
        .navigationTitle("\(walletInput)")
    }
    
//    func fetchWalletDetails(walletInput: String) {
//        if walletInput.hasSuffix(".algo") {
//            resolveNFDToWallet(nfd: walletInput) { resolvedAddress in
//                if let resolvedAddress = resolvedAddress {
//                    self.walletAddress = resolvedAddress
//                    self.navigateToProfileDetails = true
//                } else {
////                    
//                }
//            }
//        } else {
//            self.walletAddress = walletInput
//        }
//    }
//
//    private func resolveNFDToWallet(nfd: String, completion: @escaping (String?) -> Void) {
//        let lowercaseNFD = nfd.lowercased()
//        let urlString = "https://api.nf.domains/nfd/\(lowercaseNFD)"
//        guard let url = URL(string: urlString) else { return }
//
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            guard let data = data, error == nil else {
//                DispatchQueue.main.async {
//                    self.alertMessage = "Failed to fetch NFD details."
//                    self.showAlert = true
//                }
//                return
//            }
//
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let depositAccount = json["depositAccount"] as? String {
//                    DispatchQueue.main.async {
//                        completion(depositAccount)
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        self.alertMessage = "Invalid NFD response."
//                        self.showAlert = true
//                    }
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.alertMessage = "Error parsing NFD response."
//                    self.showAlert = true
//                }
//            }
//        }.resume()
//    }
}


struct OpenOrdersView: View {
    @ObservedObject var viewModel: ProfileDetailViewModel

    var body: some View {
        ScrollView {
            if let openOrders = viewModel.openOrders {
                ForEach(openOrders, id: \.marketID) { order in
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            //                        AsyncImage(url: order.image) { phase in
                            //                            switch phase {
                            //                            case .empty:
                            //                                ProgressView()
                            //                                    .frame(width: 50, height: 50)
                            //                            case .success(let image):
                            //                                image.resizable()
                            //                                    .scaledToFit()
                            //                                    .frame(width: 50, height: 50)
                            //                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            //                            case .failure:
                            //                                Image(systemName: "photo")
                            //                                    .resizable()
                            //                                    .scaledToFit()
                            //                                    .frame(width: 50, height: 50)
                            //                                    .foregroundColor(.gray)
                            //                            @unknown default:
                            //                                EmptyView()
                            //                            }
                            //                        }
                            //                        .padding(.trailing)
                            
                            Text(order.marketID ?? "-")
                                .font(.headline)
                                .padding(.bottom)
                        }
                        .padding(.bottom)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(order.orderSide ?? "-")
                                        .font(.subheadline)
                                        .foregroundColor(order.orderSide?.lowercased() == "buy" ? .green : .red)
                                    Text("\u{2192}  \(order.orderPosition)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                .padding(.bottom, 4)
                                HStack {
                                    Text("Filled: ")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("\(String(format: "%.2f", order.orderQuantityFilled ?? 0))%")
                                        .font(.subheadline)
                                }
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Price: ")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("$\(String(format: "%.2f", order.orderPrice ?? 0))")
                                        .font(.subheadline)
                                }
                                .padding(.bottom, 4)
                                HStack {
                                    Text("Total: ")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("$\(String(format: "%.2f", (order.orderPrice ?? 0) * (order.orderQuantity ?? 0)))")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
}

struct PositionsView: View {
    let currentPositions: [Position] // Accepting currentPositions array from ViewModel

    var body: some View {
        ScrollView {
            ForEach(currentPositions, id: \.title) { position in
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        AsyncImage(url: position.image) { phase in
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
                        .padding(.trailing)

                        Text(position.title)
                            .font(.headline)
                            .padding(.bottom)
                    }
                    .padding(.bottom)

                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(position.position)")
                                    .font(.subheadline)
                                    .foregroundColor(position.position.lowercased() == "yes" ? .green : .red)
                                Text("\u{2192}  \(String(format: "%.2f", position.tokenBalance)) Shares")
                                    .font(.subheadline)
                            }
                            .padding(.bottom, 4)
                            HStack {
                                Text("Current: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("$\(String(format: "%.2f", position.current))")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Risked: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("$\(String(format: "%.2f", position.price))")
                                    .font(.subheadline)
                            }
                            .padding(.bottom, 4)
                            HStack {
                                Text("To Win: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("$\(String(format: "%.2f", position.tokenBalance))")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}
