//
//  Extensions.swift
//  Radius
//
//  Created by Ryan Schoen on 6/24/24.
//

import Foundation
import SwiftUI

struct iOSCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()

        }, label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                configuration.label
            }
        })
    }
}

struct CheckboxButton: View {
    var checked: Bool
    var perform: () -> Void
    
    var body: some View {
        Button(action: perform) {
            Image(systemName: checked ? "checkmark.square" : "square")
                .padding(10)
        }
    }
    
}

func convertGoogleMapsRatingToRadiusRating(_ rating: Double) -> Double {
    return round(rating*rating/5 * 100) / 100
}
