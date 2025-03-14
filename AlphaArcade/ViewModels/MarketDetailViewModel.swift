import Foundation

class MarketDetailViewModel: ObservableObject {
    @Published var marketDetails: MarketDetail?
    @Published var marketComments: [Comment]?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var marketOrderbook: OrderBook?
    
    func fetchMarketDetails(marketId: String) {
        isLoading = true
        
        // Set up the URL for the API request (replace with actual API URL)
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-market?marketId=\(marketId)"
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
                let marketDetail = try decoder.decode(MarketDetail.self, from: data)
                
                DispatchQueue.main.async {
                    self.marketDetails = marketDetail
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
    
    func fetchComments(marketId: String) {
        isLoading = true
        
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-comments?marketId=\(marketId)"
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
                let response = try decoder.decode(Comments.self, from: data)
                
                DispatchQueue.main.async {
                    self.marketComments = response.comments
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }
        
        task.resume()
    }
    
    func fetchOrderbook(marketId: String) {
            isLoading = true
            let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-full-orderbook?marketId=\(marketId)"

            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid URL"
                    self.isLoading = false
                }
                return
            }

            let task = URLSession.shared.dataTask(with: url) { data, _, error in
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
                
                if let jsonString = String(data: data, encoding: .utf8) {
                            print("Raw JSON data: \(jsonString)")
                        }

                do {
                    let decoder = JSONDecoder()
                    let decodedData = try decoder.decode([String: OrderBook].self, from: data)

                    if let firstOrderbook = decodedData.first?.value {
                         DispatchQueue.main.async {
                             self.marketOrderbook = firstOrderbook
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
}
