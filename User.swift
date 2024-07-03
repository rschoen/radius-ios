//
//  User.swift
//  Radius
//
//  Created by Ryan Schoen on 6/24/24.
//

import Foundation
import SwiftData

@Model
class User {
    init() {
        
    }
    
    var email: String = ""
    var firebaseId: String = ""
    var address: String = ""
    var lat: Double = 0.0
    var lng: Double = 0.0
}
