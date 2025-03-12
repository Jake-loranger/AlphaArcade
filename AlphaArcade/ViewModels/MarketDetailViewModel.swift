import Foundation

class MarketDetailViewModel: ObservableObject {
    @Published var marketDetails: MarketDetail?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
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
}
