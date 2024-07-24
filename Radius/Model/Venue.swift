//
//  Venue.swift
//  Radius
//
//  Created by Ryan Schoen on 6/24/24.
//

import Foundation
import SwiftData

@Model
class Venue: Identifiable, CustomStringConvertible {
    
    init(name: String, id: String, rating: Double, reviews: Int, lat: Double, lng: Double, imageUrl: URL?, milesFromHome: Double) {
        self.name = name
        self.id = id
        self.rating = rating
        self.reviews = reviews
        self.imageUrl = imageUrl
        self.lat = lat
        self.lng = lng
        self.milesFromHome = milesFromHome
    }
    
    var name: String
    let id: String
    var rating: Double
    var reviews: Int
    var lat: Double
    var lng: Double
    var imageUrl: URL?
    var milesFromHome: Double = 0.0
    
    var visited: Bool = false
    var hidden: Bool = false
    var active: Bool = true
    
    var lastUpdated: Int = 0
    
    var description: String {
        return "Venue (id: \(id), name: \(name), rating: \(rating), reviews: \(reviews), imageUrl: \(imageUrl?.absoluteString ?? "nil")"
    }
    
    func setLastUpdated() {
        lastUpdated = Int(Date().timeIntervalSince1970)
        print("Time last updated now \(lastUpdated)")
    }
}
