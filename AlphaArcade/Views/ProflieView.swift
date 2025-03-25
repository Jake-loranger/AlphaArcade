//
//  ProflieView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var walletAddress: String = ""
    @State private var navigateToProfileDetails = false

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Enter wallet or NFDomain", text: $walletAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled(true)
                    .padding()
                    .onSubmit {
                        navigateToProfileDetails = true
                    }

                Button("Submit") {
                    navigateToProfileDetails = true
                }
                .buttonStyle(.borderedProminent)
                .padding()

                Spacer()
            }
            .navigationTitle("Profile")
            .navigationDestination(isPresented: $navigateToProfileDetails) {
                ProfileDetailsView(walletInput: walletAddress, viewModel: viewModel)
            }
        }
    }
}

struct ProfileDetailsView: View {
    let walletInput: String
    @StateObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = "Positions"

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
        .onAppear {
            viewModel.fetchWalletDetails(walletInput: walletInput)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage ?? ""),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct OpenOrdersView: View {

    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ScrollView {
            ForEach(viewModel.openOrders, id: \.marketId) { order in
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        AsyncImage(url: order.image) { phase in
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
                        
                        Text(order.title ?? "--")
                            .font(.headline)
                            .padding(.bottom)
                    }
                    .padding(.bottom)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(order.orderSide ?? "--")
                                    .font(.subheadline)
                                    .foregroundColor(order.orderSide?.lowercased() == "buy" ? .green : .red)
                                Text(order.orderPosition == 1 ? "\u{2192} Yes" : "\u{2192} No")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 4)
                            HStack {
                                Text("Filled: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(String(format: "%.2f", (order.orderQuantityFilled ?? 0) / 10000))%")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Price: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("$\(String(format: "%.2f", (order.orderPrice ?? 0) / 1000000))")
                                    .font(.subheadline)
                            }
                            .padding(.bottom, 4)
                            HStack {
                                Text("Total: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("$\(String(format: "%.2f", (order.orderQuantity ?? 0) * (order.orderPrice ?? 0) / 1000000000000))")
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
