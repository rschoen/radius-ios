//
//  Venue.swift
//  Radius
//
//  Created by Ryan Schoen on 6/24/24.
//

import Foundation
import SwiftData

@Model
class Venue: Identifiable {
    
    init(name: String, id: String, rating: Double, reviews: Int, imageUrl: URL?) {
        self.name = name
        self.id = id
        self.rating = rating
        self.reviews = reviews
        self.imageUrl = imageUrl
    }
    
    let name: String
    let id: String
    let rating: Double
    let reviews: Int
    let lat: Double = 0.0
    let lng: Double = 0.0
    let imageUrl: URL?
    
    var visited: Bool = false
    let hidden: Bool = false
    let active: Bool = true
}
