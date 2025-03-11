//
//  Market.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/9/25.
//

import Foundation

struct Market: Identifiable, Codable {
    let id: String?
    let title: String?
    let resolution: Int?
    let image: URL?
    
    var uniqueID: String {
        id ?? UUID().uuidString
    }
}
