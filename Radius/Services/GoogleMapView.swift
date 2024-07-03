//
//  GoogleMapView.swift
//  Radius
//
//  Created by Ryan Schoen on 6/24/24.
//

import SwiftUI
import SwiftData
import GoogleMaps

struct GoogleMapView: UIViewControllerRepresentable {
    typealias UIViewControllerType = GoogleMap
    
    @Environment(\.modelContext) private var modelContext
    @Query private var venues: [Venue]
    
    func makeUIViewController(context: Context) -> GoogleMap {
        return GoogleMap()
    }
    
    func updateUIViewController(_ uiViewController: GoogleMap, context: Context) {
        for venue in venues {
            let marker = createMarker(title: venue.name, description: "Description goes here", lat: venue.lat, lng: venue.lng)
            marker.map = uiViewController.map
        }
    }
    
    func createMarker(title: String, description: String, lat: Double, lng: Double) -> GMSMarker
    {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        marker.title = title
        marker.snippet = description
        return marker
    }
}



#Preview {
    GoogleMapView()
}
