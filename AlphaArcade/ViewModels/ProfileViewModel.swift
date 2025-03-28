//
//  ProfileViewModel.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/19/25.
//

import Foundation

class ProfileViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var walletAddress: String?
    @Published var isLoading = true
    @Published var alertMessage: String?
    @Published var showAlert = false
    @Published var openOrders: [Order] = []
    @Published var currentPositions: [Position] = []
    @Published var formattedPositions: [FormattedPosition] = []
    
    func fetchWalletDetails(walletInput: String) {
        if walletInput.hasSuffix(".algo") {
            resolveNFDToWallet(nfd: walletInput) { resolvedAddress in
                DispatchQueue.main.async {
                    if let resolvedAddress = resolvedAddress {
                        self.walletAddress = resolvedAddress
                        self.fetchOpenOrders()
                        self.fetchParticipantData()
                    } else {
                        self.alertMessage = "Invalid NFD domain."
                        self.showAlert = true
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.walletAddress = walletInput
                self.fetchOpenOrders()
                self.fetchParticipantData()
            }
        }
    }
        
    private func resolveNFDToWallet(nfd: String, completion: @escaping (String?) -> Void) {
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

    
    func fetchOpenOrders() {
            guard let wallet = walletAddress else {
                errorMessage = "Wallet address not set"
                return
            }

            isLoading = true
            let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-wallet-orders?wallet=\(wallet)"
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL"
                isLoading = false
                return
            }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async { self.isLoading = false }

                if let error = error {
                    DispatchQueue.main.async { self.errorMessage = "Error fetching data: \(error.localizedDescription)" }
                    return
                }

                guard let data = data else {
                    DispatchQueue.main.async { self.errorMessage = "No data received" }
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let ordersResponse = try decoder.decode(OrdersResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.openOrders = ordersResponse.orders
                    }

                    // Fetch market details for each order
                    for order in ordersResponse.orders {
                        if let marketId = order.marketId {
                            self.fetchMarketDetails(marketId: marketId) { title, imageUrl, _ in
                                DispatchQueue.main.async {
                                    
                                    // Update the corresponding order in openOrders
                                    if let index = self.openOrders.firstIndex(where: { $0.marketId == marketId }) {
                                        self.openOrders[index].title = title
                                        self.openOrders[index].image = imageUrl
                                    }
                                }
                            }
                        }
                    }

                } catch {
                    DispatchQueue.main.async { self.errorMessage = "Failed to decode data: \(error.localizedDescription)" }
                }
            }
            
            task.resume()
        }
    
    func fetchParticipantData() {
        
        guard let wallet = walletAddress else {
            errorMessage = "Wallet address not set"
            return
        }
        isLoading = true
        
        // Set up the URL for the API request (replace with actual API URL)
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-wallet-participant-data?wallet=\(wallet)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error fetching data: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }
            
            do {
                // Decode the data into the MarketDetail struct
                let decoder = JSONDecoder()
                let positions = try decoder.decode(PositionResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.currentPositions = positions.participants
                }
                
                // Fetch market details for each order
                for position in positions.participants {
                    if let marketId = position.marketId {
                        self.fetchMarketDetails(marketId: marketId) { title, imageUrl, lastTradePrice in
                            DispatchQueue.main.async {
                                
                                // Update the corresponding order in currentPositions
                                if let index = self.currentPositions.firstIndex(where: { $0.marketId == marketId }) {
                                    self.currentPositions[index].title = title
                                    self.currentPositions[index].image = imageUrl
                                    self.currentPositions[index].lastTradePrice = lastTradePrice
                                    self.updateFormattedPositions()
                                }
                            }
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
    
    func fetchMarketDetails(marketId: String, completion: @escaping (String?, URL?, Double?) -> Void) {
            let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-market?marketId=\(marketId)"
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL"
                return
            }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async { self.errorMessage = "Error fetching market details: \(error.localizedDescription)" }
                    return
                }

                guard let data = data else {
                    DispatchQueue.main.async { self.errorMessage = "No market data received" }
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let marketDetail = try decoder.decode(MarketDetail.self, from: data)
                    
                    let title = marketDetail.market.topic
                    let imageUrl = marketDetail.market.image
                    let lastTradePrice = marketDetail.market.lastTradePrice
                    
                    completion(title, imageUrl, lastTradePrice)
                } catch {
                    DispatchQueue.main.async { self.errorMessage = "Failed to decode market data: \(error.localizedDescription)" }
                }
            }

            task.resume()
    }
    
    /// Converts all `currentPositions` into `FormattedPosition`
        private func updateFormattedPositions() {
            formattedPositions = currentPositions.flatMap { formatPositionData(position: $0) }
        }
        
    func formatPositionData(position: Position) -> [FormattedPosition] {
        var formattedPositions: [FormattedPosition] = []
        
//        If position title is  != nil and != "Will the USA win the NHL 4 Nations Face-Off?"
//         If there is no title, right now it means that it is a multiple opition market
        guard let title = position.title, title != "Will the USA win the NHL 4 Nations Face-Off?" else {
            return formattedPositions
        }

        if let yesBalance = position.yesTokenBalance, yesBalance > 0  {
            formattedPositions.append(FormattedPosition(
                title: position.title,
                image: position.image,
                position: "Yes",
                costBasis: position.yesCostBasis,
                totalInvested: position.totalInvested,
                tokenBalance: position.yesTokenBalance,
                price: position.lastTradePrice,
                current: (position.lastTradePrice ?? 0) * (position.yesCostBasis ?? 0)
            ))
        }

        if let noBalance = position.noTokenBalance, noBalance > 0 {
            formattedPositions.append(FormattedPosition(
                title: position.title,
                image: position.image,
                position: "No",
                costBasis: position.noCostBasis,
                totalInvested: position.totalInvested,
                tokenBalance: position.noTokenBalance,
                price: position.lastTradePrice,
                current: (position.lastTradePrice ?? 0) * (position.noCostBasis ?? 0)
            ))
        }

        return formattedPositions
    }

}
