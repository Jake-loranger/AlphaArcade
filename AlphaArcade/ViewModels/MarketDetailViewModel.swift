import Foundation

class MarketDetailViewModel: ObservableObject {
    @Published var marketDetails: MarketDetail?
    @Published var marketComments: [Comment]?
    @Published var marketOrderbook: MarketOrderBook = [:]
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var options: [Option]?
    
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
    
    func fetchMarketOptions(marketId: String) {
        isLoading = true
        
        let urlString = "https://g08245wvl7.execute-api.us-east-1.amazonaws.com/api/get-markets"
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
                let decodedResponse = try JSONDecoder().decode(MarketResponse.self, from: data)
                
                // Find the market by ID
                if let market = decodedResponse.markets.first(where: { $0.id == marketId }) {
                    DispatchQueue.main.async {
                        self.options = market.options ?? []
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Market not found"
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

                do {
                    let decoder = JSONDecoder()
                    var decodedData = try decoder.decode(MarketOrderBook.self, from: data)

                    // Transform order book to add missing data points
                    let transformedData = self.transformOrderBook(decodedData)

                    DispatchQueue.main.async {
                        self.marketOrderbook = transformedData
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                    }
                }
            }

            task.resume()
        }

    private func transformOrderBook(_ orderBook: MarketOrderBook) -> MarketOrderBook {
        var newOrderBook: MarketOrderBook = [:]

        for (marketId, marketData) in orderBook {
            var newYesBids = marketData.yes.bids
            var newYesAsks = marketData.yes.asks
            var newNoBids = marketData.no.bids
            var newNoAsks = marketData.no.asks

            // 1. Add a NO ask for each YES bid
            for bid in marketData.yes.bids {
                let correspondingNoAskPrice = 1000000 - bid.price
                if !newNoAsks.contains(where: { $0.price == correspondingNoAskPrice }) {
                    let newAsk = OrderEntry(price: correspondingNoAskPrice, quantity: bid.quantity, total: bid.total)
                    newNoAsks.append(newAsk)
                }
            }

            // 2. Add a NO bid for each YES ask
            for ask in marketData.yes.asks {
                let correspondingNoBidPrice = 1000000 - ask.price
                if !newNoBids.contains(where: { $0.price == correspondingNoBidPrice }) {
                    let newBid = OrderEntry(price: correspondingNoBidPrice, quantity: ask.quantity, total: ask.total)
                    newNoBids.append(newBid)
                }
            }

            // 3. Add a YES ask for each NO bid
            for bid in marketData.no.bids {
                let correspondingYesAskPrice = 1000000 - bid.price
                if !newYesAsks.contains(where: { $0.price == correspondingYesAskPrice }) {
                    let newAsk = OrderEntry(price: correspondingYesAskPrice, quantity: bid.quantity, total: bid.total)
                    newYesAsks.append(newAsk)
                }
            }

            // 4. Add a YES bid for each NO ask
            for ask in marketData.no.asks {
                let correspondingYesBidPrice = 1000000 - ask.price
                if !newYesBids.contains(where: { $0.price == correspondingYesBidPrice }) {
                    let newBid = OrderEntry(price: correspondingYesBidPrice, quantity: ask.quantity, total: ask.total)
                    newYesBids.append(newBid)
                }
            }

            // Create new MarketData with updated values
            let updatedMarketData = MarketData(
                yes: OrderBook(bids: newYesBids, asks: newYesAsks),
                no: OrderBook(bids: newNoBids, asks: newNoAsks)
            )

            newOrderBook[marketId] = updatedMarketData
        }

        return newOrderBook
    }
}
