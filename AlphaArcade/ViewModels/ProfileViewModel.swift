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
    
    @Published var currentPositions: [Position] = [
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
    
    
    func fetchWalletDetails(walletInput: String) {
        if walletInput.hasSuffix(".algo") {
            resolveNFDToWallet(nfd: walletInput) { resolvedAddress in
                DispatchQueue.main.async {
                    if let resolvedAddress = resolvedAddress {
                        self.walletAddress = resolvedAddress
                        self.fetchOpenOrders()
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
                    let decoder = JSONDecoder()
                    let ordersResponse = try decoder.decode(OrdersResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.openOrders = ordersResponse.orders
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                    }
                }
            }
            
            task.resume()
        }

    
    func fetchParticipantData() {
        isLoading = true
        
        // Set up the URL for the API request (replace with actual API URL)
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-wallet-participant-data?wallet=\(self.walletAddress)"
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
                let currentPositions = try decoder.decode([Position].self, from: data)
                
                DispatchQueue.main.async {
//                    self.currentPositions = currentPositions
                    print("good")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
}
