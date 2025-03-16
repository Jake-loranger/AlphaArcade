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

    var body: some View {
        VStack {

            if isLoading {
                ProgressView()
            } else {
                Text("Wallet: \(walletAddress ?? "N/A")")
                    .padding()
                Text("Participant Data:")
                    .bold()
                Text(participantData)
                    .padding()
            }
        }
        .navigationTitle("Profile Details")
        .onAppear {
            fetchWalletDetails()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()  // Navigate back
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
