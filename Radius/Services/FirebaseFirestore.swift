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
    
    private var userId = ""
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
    
    private var ref: DatabaseReference?
}

extension FirebaseFirestore {
    func getReference() -> DatabaseReference {
        if ref == nil {
            ref = Database.database().reference()
        }
        return ref!
    }
    
    
    func fetchVenuesSnapshot() async -> DataSnapshot {
        await withCheckedContinuation { continuation in
            getReference().child("users").child(userId).child("venues").observeSingleEvent(of: DataEventType.value) { snapshot in
                continuation.resume(returning: snapshot)
            }
        }
    }
    
    func fullSync(userId: String) async {
        if userId.isEmpty { return }
        self.userId = userId
        
        print("FULL SYNC TRIGGERED")
        
        let snapshot = await fetchVenuesSnapshot()
        var databaseVenues = Dictionary<String, DatabaseVenue>()
        for venue in snapshot.children {
            guard let snap = venue as? DataSnapshot else { return }
            guard let value = snap.value as? [String: Any] else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                let decoded = try JSONDecoder().decode(DatabaseVenue.self, from: jsonData)
                if let venueId = decoded.venueId {
                    databaseVenues[venueId] = decoded
                }
            } catch {
                print("ERROR HERE: \(error)")
            }
        }
        
        do {
            let venues = try modelContext.fetch(FetchDescriptor<Venue>())
            for venue in venues {
                if let databaseVenue = databaseVenues[venue.id] {
                    if let lastUpdated = databaseVenue.lastUpdated {
                        if lastUpdated > venue.lastUpdated {
                            print("Updating local data for \(venue.name)")
                            venue.visited = databaseVenue.visited ?? venue.visited
                            venue.hidden = databaseVenue.hidden ?? venue.hidden
                            venue.lastUpdated = lastUpdated
                        } else if  lastUpdated < venue.lastUpdated {
                            updateFirebaseVenue(id: venue.id, visited: venue.visited, hidden: venue.hidden, lastUpdated: venue.lastUpdated)
                        }
                    }
                    await Task.yield()
                }
            }
            try modelContext.save()
        }
        catch {
            print(error)
        }
        
    }
                    
    func updateFirebaseVenue(id: String, visited: Bool, hidden: Bool, lastUpdated: Int?) {
        if userId.isEmpty { return }
        print("Updating remote data for venue \(id)")
        let venueNode = getReference().child("users/\(userId)/venues/\(id)")
        
        venueNode.child("visited").setValue(visited)
        venueNode.child("hidden").setValue(hidden)
        if let lastUpdated {
            venueNode.child("lastUpdated").setValue(lastUpdated)
        }
    }
    
    func storeAddress(address: String, latitude: Double, longitude: Double) {
        if userId.isEmpty { return } 
        
        let addressNode = getReference().child("users/\(userId)/address")
        
        addressNode.setValue("address")
        addressNode.child("address").setValue(address)
        addressNode.child("latitude").setValue(latitude)
        addressNode.child("longitude").setValue(longitude)
    }
    
    
    /*func subscribeToOnlyChanges() async -> DataSnapshot {
        await withCheckedContinuation { continuation in
            ref.child("users").child(userId).child("venues").observe(DataEventType.value) { snapshot in
                continuation.resume(returning: snapshot)
            }
        }
    }
    
    func observeUserData(userId: String) async {
        self.userId = userId
        
        if ref == nil {
            ref = Database.database().reference()
        }
        
        if !userId.isEmpty {
            let snapshot = await fetchVenuesSnapshot()
            for venue in snapshot.children {
                guard let snap = venue as? DataSnapshot else { return }
                guard let value = snap.value as? [String: Any] else { return }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                    let decoded = try JSONDecoder().decode(DatabaseVenue.self, from: jsonData)
                    await self.updateVenue(decoded)
                } catch {
                    print("ERROR HERE: \(error)")
                }
            }
        }
    }
    func updateVenue(_ databaseVenue: DatabaseVenue) async {
        do {
            let venues = try modelContext.fetch(FetchDescriptor<Venue>())
            for venue in venues {
                if venue.id == databaseVenue.venueId {
                    if let lastUpdated = databaseVenue.lastUpdated, lastUpdated >= venue.lastUpdated {
                        //print("Updating \(venue.name) venue from the RTDB because \(lastUpdated) >= \(venue.lastUpdated)")
                        venue.visited = databaseVenue.visited ?? venue.visited
                        venue.hidden = databaseVenue.hidden ?? venue.hidden
                        venue.lastUpdated = lastUpdated
                    } else {
                        // TODO: reverse sync?
                    }
                    await Task.yield()
                    break
                }
            }
            try modelContext.save()
        }
        catch {
            print(error)
        }
    }
    
    func setVenueStatus(id: String, visited: Bool, hidden: Bool, lastUpdated: Int?) {
        let venueNode = self.ref.child("users/\(userId)/venues/\(id)")
        
        venueNode.child("visited").setValue(visited)
        venueNode.child("hidden").setValue(hidden)
        if let lastUpdated {
            venueNode.child("lastUpdated").setValue(lastUpdated)
        }
    }*/
}
