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
    @Query private var users: [User]
    
    private var user: User {
        if let user = users.first {
            return user
        } else {
            let user = User()
            modelContext.insert(user)
            return user
        }
    }
    
    func makeUIViewController(context: Context) -> GoogleMap {
        return GoogleMap()
    }
    
    func updateUIViewController(_ uiViewController: GoogleMap, context: Context) {
        if user.address.isEmpty {
            return
        }
        if let map = uiViewController.map {
            
            Task.detached {
                await map.clear()
                
                let homeLocation = CLLocation(latitude: user.lat, longitude: user.lng)
                
                var distances = Array<Double>()
                
                var maxVenueDistance = 0.0
                var minUnvisitedDistance = Double.infinity
                
                for venue in venues {
                    guard venue.hidden == false else { continue }
                    
                    let title = venue.name
                    let description = "\(convertGoogleMapsRatingToRadiusRating(venue.rating)) stars, \(venue.reviews) reviews"
                    let lat = venue.lat
                    let lng = venue.lng
                    let visited = venue.visited
                    Task.detached { @MainActor in
                        let marker = createMarker(title: title, description: description, lat: lat, lng: lng)
                        if visited {
                            marker.icon = GMSMarker.markerImage(with: .green)
                        }
                        marker.map = map
                    }
                    
                    let distance = homeLocation.distance(from: CLLocation(latitude: venue.lat, longitude: venue.lng))
                    
                    if distance > maxVenueDistance {
                        maxVenueDistance = distance
                    }
                    if !venue.visited && distance < minUnvisitedDistance {
                        minUnvisitedDistance = distance
                    }
                    
                    distances.append(distance)
                }
                
                distances.sort()
                var tenthDistance = 0.0
                if !distances.isEmpty {
                    tenthDistance = distances[min(distances.count,9)]
                }
                
                await map.moveCamera(GMSCameraUpdate.setCamera(GMSCameraPosition(latitude: user.lat, longitude: user.lng, zoom: distanceToZoom(tenthDistance))))
                
                
                Task.detached { @MainActor in
                    let homeMarker = createMarker(title: "Home Base", description: user.address, lat: user.lat, lng: user.lng)
                    homeMarker.icon = GMSMarker.markerImage(with: .blue)
                    homeMarker.map = map
                }
                
                
                await map.drawCircle(position: homeLocation, radius: maxVenueDistance, color: UIColor.gray)
                await map.drawCircle(position: homeLocation, radius: minUnvisitedDistance, color: UIColor.green)
                await Task.yield()
            }
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


func distanceToZoom(_ distance: Double) -> Float {
        return if (distance < 100) {
            18.0
        } else if (distance < 200) {
            17.0
        } else if (distance < 500) {
            16.0
        } else if (distance < 1000) {
            15.0
        } else if (distance < 2000) {
            14.0
        } else if (distance < 5000) {
            13.0
        } else if (distance < 10_000) {
            12.0
        } else if (distance < 20_000) {
            11.0
        } else {
            10.0
        }
    }


extension GMSMapView {
    func drawCircle(position: CLLocation, radius: Double, color: UIColor) {
        if radius > 0 {
            let circle = GMSCircle(position: position.coordinate, radius: radius)
            circle.strokeColor = color
            circle.map = self
        }
    }
}
