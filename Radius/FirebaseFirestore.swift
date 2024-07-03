//
//  FirebaseFirestore.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseFirestore

struct DatabaseVenue: Codable {
    let venueId: String?
    let visited: Bool?
    let hidden: Bool?
    let lastUpdated: Int?
}


@ModelActor
actor FirebaseFirestore: Observable, ObservableObject {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Venue.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var ref: DatabaseReference!
}

extension FirebaseFirestore {
    //@Query private var venues: [Venue]
    
   
    
    
    func observeUserData(userId: String) {
        if ref == nil {
            ref = Database.database().reference()
        }
        
        if !userId.isEmpty {
            ref.child("users").child(userId).child("venues").observe(DataEventType.value) { snapshot in
                for venue in snapshot.children {
                    guard let snap = venue as? DataSnapshot else { return }
                    guard let value = snap.value as? [String: Any] else { return }
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                        let decoded = try JSONDecoder().decode(DatabaseVenue.self, from: jsonData)
                        self.updateVenue(decoded)
                    } catch {
                        print("ERROR HERE: \(error)")
                    }
                }
            }
        }
    }
    func updateVenue(_ databaseVenue: DatabaseVenue) {
        do {
            let venues = try modelContext.fetch(FetchDescriptor<Venue>())
            for venue in venues {
                if venue.id == databaseVenue.venueId {
                    if let lastUpdated = databaseVenue.lastUpdated, lastUpdated > venue.lastUpdated {
                        venue.visited = databaseVenue.visited ?? venue.visited
                        venue.hidden = databaseVenue.hidden ?? venue.hidden
                        venue.lastUpdated = lastUpdated
                    } else {
                        // TODO: reverse sync?
                    }
                    break
                }
            }
            try modelContext.save()
        }
        catch {
            print(error)
        }
    }
}
