//
//  ProflieView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI

struct ProfileView: View {
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
                ProfileDetailsView(walletInput: walletAddress)
            }
        }
    }
}

struct ProfileDetailsView: View {
    let walletInput: String
    @State private var walletAddress: String?
    @State private var participantData: String = "Fetching data..."
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode  // For navigating back
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedTab = "Positions"

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                Picker("Select", selection: $selectedTab) {
                    Text("Positions").tag("Positions")
                    Text("Orders").tag("Orders")
                }
                .pickerStyle(.segmented)
                .padding([.top, .leading, .trailing])
                
                if selectedTab == "Orders" {
                    OpenOrdersView()
                        .padding()
                } else {
                    PositionsView()
                        .padding()
                }
                Spacer()
            }
        }
        .navigationTitle("\(walletInput)")
        .onAppear {
            fetchWalletDetails()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    /// Determine if input is an NFD, resolve it, and then fetch participant data
    private func fetchWalletDetails() {
        if walletInput.hasSuffix(".algo") {
            resolveNFDToWallet(nfd: walletInput) { resolvedAddress in
                guard let resolvedAddress = resolvedAddress else {
                    self.alertMessage = "Invalid NFD domain."
                    self.showAlert = true
                    return
                }
                self.walletAddress = resolvedAddress
                self.fetchParticipantData(wallet: resolvedAddress)
            }
        } else {
            self.walletAddress = walletInput
            self.fetchParticipantData(wallet: walletInput)
        }
    }

    /// API call to resolve NFD to an Algorand wallet address
    private func resolveNFDToWallet(nfd: String, completion: @escaping (String?) -> Void) {
        // Convert NFD to lowercase
        let lowercaseNFD = nfd.lowercased()
        
        let urlString = "https://api.nf.domains/nfd/\(lowercaseNFD)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to fetch NFD details."
                    self.showAlert = true
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let depositAccount = json["depositAccount"] as? String {
                    DispatchQueue.main.async {
                        completion(depositAccount)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertMessage = "Invalid NFD response."
                        self.showAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Error parsing NFD response."
                    self.showAlert = true
                }
            }
        }.resume()
    }


    /// API call to fetch participant data
    private func fetchParticipantData(wallet: String) {
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-wallet-participant-data?wallet=\(wallet)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.alertMessage = "Invalid wallet address."
                    self.showAlert = true
                }
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.participantData = responseString
                    self.isLoading = false
                }
            }
        }.resume()
    }
}


struct OpenOrdersView: View {
    
    let sampleOrders: [Order] = [
        Order(
            title: "NBA Champion - Boston Celtics",
            image: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSRkjjLr3j0FpmlTy6ye6IQUFQcOYxpypxFpg&s")!,
            side: "Buy",
            outcome: "Yes",
            price: 150.75,
            filled: 5.0,
            total: 753.75
        ),
        Order(
            title: "Super Bowl Winner - Kansas City Chiefs",
            image: URL(string: "https://licensing.auburn.edu/wp-content/uploads/2020/02/Standard1.jpg")!,
            side: "Sell",
            outcome: "No",
            price: 120.50,
            filled: 3.0,
            total: 361.50
        ),
        Order(
            title: "US Presidential Election - 2024",
            image: URL(string: "https://spiritofamerica.org/wp-content/uploads/2022/02/iStock-1358369065-1.jpg")!,
            side: "Buy",
            outcome: "Yes",
            price: 90.25,
            filled: 10.0,
            total: 902.50
        ),
        Order(
            title: "Bitcoin Price Above 100K by 2025",
            image: URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Bitcoin.svg/800px-Bitcoin.svg.png")!,
            side: "Sell",
            outcome: "No",
            price: 80.00,
            filled: 2.5,
            total: 200.00
        )
    ]


    var body: some View {
        ScrollView {
            ForEach(sampleOrders, id: \.title) { order in
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

                        Text(order.title)
                            .font(.headline)
                            .padding(.bottom)
                    }
                    .padding(.bottom)

                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(order.side)
                                    .font(.subheadline)
                                    .foregroundColor(order.side.lowercased() == "buy" ? .green : .red)
                                Text("\u{2192}  \(order.outcome)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 4)
                            HStack {
                                Text("Filled: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(String(format: "%.2f", order.filled))%")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Price: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("$\(String(format: "%.2f", order.price))")
                                    .font(.subheadline)
                            }
                            .padding(.bottom, 4)
                            HStack {
                                Text("Total: ")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("$\(String(format: "%.2f", order.total))")
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
    let positions: [Position] = [
        Position(
            title: "NBA Champion - Boston Celtics",
            image: URL(string: "https://spiritofamerica.org/wp-content/uploads/2022/02/iStock-1358369065-1.jpg")!,
            position: "Yes",
            costBasis: 150.00,
            totalInvested: 9.53,
            tokenBalance: 10,
            price: 155.00,
            current: 54.00
        ),
        Position(
            title: "Bitcoin Price Above 100K by 2025",
            image: URL(string: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSRkjjLr3j0FpmlTy6ye6IQUFQcOYxpypxFpg&s")!,
            position: "No",
            costBasis: 150.00,
            totalInvested: 9.53,
            tokenBalance: 10,
            price: 400.00,
            current: 1060.00
        ),
        Position(
            title: "US Presidential Election - 2024",
            image: URL(string: "https://spiritofamerica.org/wp-content/uploads/2022/02/iStock-1358369065-1.jpg")!,
            position: "Yes",
            costBasis: 150.00,
            totalInvested: 9.53,
            tokenBalance: 10,
            price: 15.00,
            current: 16.00
        )
    ]
    
    var body: some View {
        ScrollView {
            ForEach(positions, id: \.title) { position in
                VStack(alignment: .leading) {
                    HStack(alignment: .top) {
                        AsyncImage(url: position.image) { phase in
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
                            HStack{
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
