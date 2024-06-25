//
//  GoogleMapView.swift
//  Radius
//
//  Created by Ryan Schoen on 6/24/24.
//

import SwiftUI

struct GoogleMapView: UIViewControllerRepresentable {
    typealias UIViewControllerType = GoogleMap
    
    func makeUIViewController(context: Context) -> GoogleMap {
        return GoogleMap()
    }
    
    func updateUIViewController(_ uiViewController: GoogleMap, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
}



#Preview {
    GoogleMapView()
}
