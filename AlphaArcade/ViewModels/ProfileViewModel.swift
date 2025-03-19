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
    
    @Published var openOrders: [Order] = [
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
    
    func fetchWalletDetails(walletInput: String) {
            if walletInput.hasSuffix(".algo") {
                resolveNFDToWallet(nfd: walletInput) { resolvedAddress in
                    if let resolvedAddress = resolvedAddress {
                        self.walletAddress = resolvedAddress
                        self.fetchParticipantData(wallet: resolvedAddress)
                    } else {
                        self.alertMessage = "Invalid NFD domain."
                        self.showAlert = true
                    }
                }
            } else {
                self.walletAddress = walletInput
                self.fetchParticipantData(wallet: walletInput)
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

                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }.resume()
        }
    
    func fetchOpenOrders(walletAddress: String) {
        isLoading = true
        
        // Set up the URL for the API request (replace with actual API URL)
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-wallet-orders?wallet=\(walletAddress)"
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
                let openOrders = try decoder.decode([Order].self, from: data)
                
                DispatchQueue.main.async {
//                    self.openOrders = openOrders
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
    
    func fetchParticipantData(walletAddress: String) {
        isLoading = true
        
        // Set up the URL for the API request (replace with actual API URL)
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-wallet-participant-data?wallet=\(walletAddress)"
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
