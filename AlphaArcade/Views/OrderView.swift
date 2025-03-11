//
//  OrderView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/11/25.
//

import SwiftUI

struct OrderView: View {
    let option: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("You selected: \(option)")
                .font(.headline)

            Button(action: { dismiss() }) {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
