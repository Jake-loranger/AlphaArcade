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
    case optionThree
    case optionFour
    case optionFive
    
    // Static array to hold all color options
    static let colors: [OptionColor] = [.optionOne, .optionTwo, .optionThree, .optionFour, .optionFive]

    var outline: Color {
        switch self {
        case .optionOne:
            return Color(red: 109/255, green: 239/255, blue: 252/255)
        case .optionTwo:
            return Color(red: 234/255, green: 63/255, blue: 247/255)
        case .optionThree:
            return Color(red: 255/255, green: 114/255, blue: 75/255)
        case .optionFour:
            return Color(red: 75/255, green: 81/255, blue: 255/255)
        case .optionFive:
            return Color(red: 255/255, green: 55/255, blue: 55/255)
        }
    }

    var background: Color {
        switch self {
        case .optionOne:
            return Color(red: 51/255, green: 91/255, blue: 97/255)
        case .optionTwo:
            return Color(red: 89/255, green: 38/255, blue: 96/255)
        case .optionThree:
            return Color(red: 142/255, green: 74/255, blue: 55/255)
        case .optionFour:
            return Color(red: 55/255, green: 58/255, blue: 142/255)
        case .optionFive:
            return Color(red: 142/255, green: 55/255, blue: 55/255)
        }
    }
}
