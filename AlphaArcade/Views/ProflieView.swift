//
//  ProflieView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI


struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @State private var currentWalletAddress: String = ""   // Active account selected from AccountSwitcherView
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
            // Update the view model when the active account changes
            .onChange(of: currentWalletAddress) { newAccount in
                viewModel.fetchWalletDetails(walletInput: newAccount)
            }
        }
    }
}

struct AccountSwitcherView: View {
    @Binding var currentWalletAddress: String
    
    @State private var availableAccounts: [String] = []
    @State private var newAccount: String = ""
    @State private var showingAddAccountSheet = false
    
    // Access the presentation mode so we can dismiss the view on selection.
    @Environment(\.presentationMode) private var presentationMode
    
    // UserDefaults key for storing accounts
    private let accountsKey = "StoredAccounts"
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Display each account loaded from local storage.
                    ForEach(availableAccounts, id: \.self) { account in
                        Button(action: {
                            currentWalletAddress = account
                            // Dismiss the AccountSwitcherView once an account is selected.
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(account)
                                Spacer()
                                if account == currentWalletAddress {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    // Enable deletion of accounts.
                    .onDelete(perform: deleteAccounts)
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
                        Text("Add New Account")
                            .font(.headline)
                        
                        TextField("Enter account", text: $newAccount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button("Save") {
                            guard !newAccount.isEmpty else { return }
                            // Append the new account, update the active account,
                            // save to UserDefaults, and then dismiss the add account sheet.
                            availableAccounts.append(newAccount)
                            currentWalletAddress = newAccount
                            saveAccounts()
                            newAccount = ""
                            showingAddAccountSheet = false
                            
                            // Optionally dismiss the entire AccountSwitcherView after saving.
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        
                        Spacer()
                    }
                    .padding()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .navigationBarTitle("Account Switcher", displayMode: .inline)
            .onAppear(perform: loadAccounts)
        }
    }
    
    // Loads accounts from UserDefaults or initializes with an empty array.
    private func loadAccounts() {
        if let storedAccounts = UserDefaults.standard.array(forKey: accountsKey) as? [String] {
            availableAccounts = storedAccounts
        } else {
            availableAccounts = []
            saveAccounts()
        }
    }
    
    // Saves the current account list to UserDefaults.
    private func saveAccounts() {
        UserDefaults.standard.set(availableAccounts, forKey: accountsKey)
    }
    
    // Deletes accounts from the list and updates UserDefaults.
    private func deleteAccounts(at offsets: IndexSet) {
        // Remove the accounts from the array.
        for index in offsets {
            let accountToDelete = availableAccounts[index]
            // If the deleted account is the active one, clear it or update it as needed.
            if accountToDelete == currentWalletAddress {
                currentWalletAddress = ""
            }
        }
        availableAccounts.remove(atOffsets: offsets)
        saveAccounts()
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
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ScrollView {
            ForEach(viewModel.formattedPositions.indices, id: \.self) { index in
                let position = viewModel.formattedPositions[index]
                NavigationLink(destination: MarketDetailView(market: position.marketId ?? "")) {
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
        }
    }
}
