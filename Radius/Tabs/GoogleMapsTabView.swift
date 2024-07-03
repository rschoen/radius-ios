//
//  SwiftUIView.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import SwiftUI

struct GoogleMapsTabView: View {
    var body: some View {
        VStack {
            GoogleMapView()
                .clipped()
            Spacer(minLength: 15)
        }
    }
}

#Preview {
    GoogleMapsTabView()
}
