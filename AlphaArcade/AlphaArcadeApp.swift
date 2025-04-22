//
//  AlphaArcadeApp.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/6/25.
//

import SwiftUI

@main
struct AlphaArcadeApp: App {
    init() {
        UIView.appearance().overrideUserInterfaceStyle = .dark
    }
    
    var body: some Scene {
        WindowGroup {
            MainView() 
        }
    }
}
