//
//  ProflieView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI


struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @State private var currentWalletAddress: String = UserDefaults.standard.string(forKey: "ActiveAccount") ?? ""
    @State private var showAccountSwitcher: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                ProfileDetailsView(walletInput: currentWalletAddress, viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(currentWalletAddress.isEmpty ? "No Account" : currentWalletAddress)
                        .font(.largeTitle)
                        .bold()
                        .truncationMode(.middle) 
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAccountSwitcher.toggle()
                    }) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showAccountSwitcher) {
                        AccountSwitcherView(currentWalletAddress: $currentWalletAddress)
                    }
                }
            }
            
            .onAppear {
                // Load the active account when the view appears
                currentWalletAddress = UserDefaults.standard.string(forKey: "ActiveAccount") ?? ""
                viewModel.fetchWalletDetails(walletInput: currentWalletAddress)
            }
            .onChange(of: currentWalletAddress) { newAccount in
                // Save the new active account to UserDefaults
                UserDefaults.standard.set(newAccount, forKey: "ActiveAccount")
                viewModel.fetchWalletDetails(walletInput: newAccount)
                print(UserDefaults.standard.dictionaryRepresentation())
            }
        }
        .refreshable {
            viewModel.fetchOpenOrders()
            viewModel.fetchParticipantData()
        }
    }
}

struct AccountSwitcherView: View {
    @Binding var currentWalletAddress: String
    
    @State private var availableAccounts: [String] = []
    @State private var newAccount: String = ""
    @State private var showingAddAccountSheet = false
    
    // Access the presentation mode to dismiss the view
    @Environment(\.presentationMode) private var presentationMode
    
    // UserDefaults key for storing accounts
    private let accountsKey = "StoredAccounts"
    private let activeAccountKey = "ActiveAccount"

    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Display each account loaded from local storage.
                    ForEach(availableAccounts, id: \.self) { account in
                        Button(action: {
                            setActiveAccount(account)
                        }) {
                            HStack {
                                Text(account)
                                    .lineLimit(1) 
                                    .truncationMode(.middle)
                                Spacer()
                                if account == currentWalletAddress {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let accountToDelete = availableAccounts[index]
                            deleteAccount(accountToDelete) // Call the delete function
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                Button(action: {
                    showingAddAccountSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add new item")
                    }
                }
                .padding()
                .sheet(isPresented: $showingAddAccountSheet) {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Text("Add an Account")
                            .font(.headline)
                        
                        TextField("Enter Address or NFD", text: $newAccount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button("Save") {
                            guard !newAccount.isEmpty else { return }
                            saveAccount(newAccount)
                            setActiveAccount(newAccount)
                            newAccount = ""
                            showingAddAccountSheet = false
                        }
                        .padding()
                        
                        Spacer()
                    }
                    .padding()
                    .presentationDetents([.fraction(0.3)])  // Adjust height to 30% of screen
                    .presentationDragIndicator(.visible)
                }
            }
            .navigationBarTitle("Switch Accounts", displayMode: .inline)
            .onAppear(perform: loadAccounts)
        }
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.visible)
    }
    
    // Load accounts from UserDefaults
    private func loadAccounts() {
        if let storedAccounts = UserDefaults.standard.array(forKey: accountsKey) as? [String] {
            availableAccounts = storedAccounts
        } else {
            availableAccounts = []
        }
    }
    
    private func saveAccount(_ account: String) {
        // Load the existing accounts from UserDefaults
        var storedAccounts = UserDefaults.standard.array(forKey: accountsKey) as? [String] ?? []
        
        // Append the new account if it’s not already in the list
        if !storedAccounts.contains(account) {
            storedAccounts.append(account)
        }
        
        // Save the updated list back to UserDefaults
        UserDefaults.standard.set(storedAccounts, forKey: accountsKey)
        
        // Update the local availableAccounts variable
        availableAccounts = storedAccounts
        
        
        print(UserDefaults.standard.dictionaryRepresentation())
    }
    
    private func deleteAccount(_ account: String) {
        // Load the existing accounts from UserDefaults
        var storedAccounts = UserDefaults.standard.array(forKey: accountsKey) as? [String] ?? []
        
        // Remove the specified account
        storedAccounts.removeAll { $0 == account }
        
        // Save the updated list back to UserDefaults
        UserDefaults.standard.set(storedAccounts, forKey: accountsKey)
        
        // Update the local availableAccounts variable
        availableAccounts = storedAccounts
        
        // If the deleted account was the active one, clear it
        if currentWalletAddress == account {
            currentWalletAddress = ""
            UserDefaults.standard.removeObject(forKey: "ActiveAccount")
        }
    }

    // Set and persist the active account
    private func setActiveAccount(_ account: String) {
        currentWalletAddress = account
        UserDefaults.standard.set(account, forKey: activeAccountKey)
        presentationMode.wrappedValue.dismiss()
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
                    PositionsView(viewModel: viewModel)
                        .padding()
                }
                Spacer()
            }
        }
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
                NavigationLink(destination: MarketDetailView(marketId: order.marketId ?? "", market: nil)) {
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
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}



struct PositionsView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ScrollView {
            ForEach(viewModel.formattedPositions.indices, id: \.self) { index in
                let position = viewModel.formattedPositions[index]
                
                NavigationLink(destination: MarketDetailView(marketId: position.marketId ?? "", market: nil)) {
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
                            
                            Text(position.title ?? "-")
                                .font(.headline)
                                .padding(.bottom)
                        }
                        .padding(.bottom)
                        
                        HStack {
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(position.position ?? "-") ¢\(String(format: "%.0f", (position.costBasis ?? 0)))")
                                        .font(.subheadline)
                                        .foregroundColor(position.position?.lowercased() == "yes" ? .green : .red)
                                    Text("\u{2192}  \(String(format: "%.2f", (position.tokenBalance ?? 0) / 1000000)) Shares")
                                        .font(.subheadline)
                                }
                                .padding(.bottom, 4)
                                HStack {
                                    Text("Current: ")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("$\(String(format: "%.2f", (position.current ?? 0) / 1000000))")
                                        .font(.subheadline)
                                }
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Risked: ")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("$\(String(format: "%.2f", (position.totalInvested ?? 0) / 1000000))")
                                        .font(.subheadline)
                                }
                                .padding(.bottom, 4)
                                HStack {
                                    Text("To Win: ")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("$\(String(format: "%.2f", (position.tokenBalance ?? 0) / 1000000))")
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
            .buttonStyle(PlainButtonStyle())
        }
    }
}
