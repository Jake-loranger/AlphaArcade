//
//  Comments.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 3/15/25.
//

import Foundation

struct Comments: Codable {
    let comments: [Comment]
}

struct Comment: Codable {
    let text: String?
    let senderWallet: String?
    let updatedAt: Int?
}
