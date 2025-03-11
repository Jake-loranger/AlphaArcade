//
//  MainView.swift
//  AlphaArcade
//
//  Created by Jacob Loranger on 3/6/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            MarketView()
                .tabItem {
                    Label("Markets", systemImage: "gamecontroller")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
    }
}


#Preview {
    MainView()
}
