//
//  ContentView.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/6/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ArcadeView()
                .tabItem {
                    Label("Arcade", systemImage: "gamecontroller")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainView()
}
