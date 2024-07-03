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
    
    init(name: String, id: String, rating: Double, reviews: Int, imageUrl: URL?) {
        self.name = name
        self.id = id
        self.rating = rating
        self.reviews = reviews
        self.imageUrl = imageUrl
    }
    
    var name: String
    let id: String
    var rating: Double
    var reviews: Int
    var lat: Double = 0.0
    var lng: Double = 0.0
    var imageUrl: URL?
    
    var visited: Bool = false
    var hidden: Bool = false
    var active: Bool = true
    
    var lastUpdated: Int = 0
    
    var description: String {
        return "Venue (id: \(id), name: \(name), rating: \(rating), reviews: \(reviews), imageUrl: \(imageUrl?.absoluteString ?? "nil")"
    }
}
