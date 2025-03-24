//
//  ProfileDetailViewModel.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/19/25.
//

import Foundation

class ProfileDetailViewModel: ObservableObject {
    @Published var walletAddress: String
    @Published var errorMessage: String?
    @Published var isLoading = true
    @Published var openOrders: [Order]?
    
    init(walletAddress: String) {
        self.walletAddress = walletAddress
    }
    
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

    
    func fetchOpenOrders() {
        isLoading = true
        
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-wallet-orders?wallet=\(self.walletAddress)"
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
                let openOrders = try decoder.decode([Order].self, from: data)
                
                DispatchQueue.main.async {
                    self.openOrders = openOrders
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
