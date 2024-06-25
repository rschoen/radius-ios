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
    
    let email: String = ""
    let firebaseId: String = ""
    let address: String = ""
    let lat: Double = 0.0
    let lng: Double = 0.0
}
