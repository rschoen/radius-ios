//
//  VenueLoadingIndicator.swift
//  Radius
//
//  Created by Ryan Schoen on 7/24/24.
//

import SwiftUI

struct VenueLoadingIndicator: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            ProgressView("Downloading venue data...")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    VenueLoadingIndicator()
}
