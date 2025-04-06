//
//  Colors.swift
//  AlphaArcade
//
//  Created by Jacob  Loranger on 4/6/25.
//

import SwiftUI

enum OptionColor {
    case optionOne  // Yes
    case optionTwo  // No

    var outline: Color {
        switch self {
        case .optionOne:
            return Color(red: 109/255, green: 239/255, blue: 252/255)
        case .optionTwo:
            return Color(red: 234/255, green: 63/255, blue: 247/255)
        }
    }

    var background: Color {
        switch self {
        case .optionOne:
            return Color(red: 51/255, green: 91/255, blue: 97/255)
        case .optionTwo:
            return Color(red: 89/255, green: 38/255, blue: 96/255)
        }
    }
}
