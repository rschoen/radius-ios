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
import FirebaseDatabase

struct DatabaseVenue: Codable, Sendable {
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

    private func fetchDatabaseVenues() async throws -> [String: DatabaseVenue] {
        try await withCheckedThrowingContinuation { continuation in
            let ref = getReference().child("users").child(userId).child("venues")
            ref.observeSingleEvent(of: DataEventType.value) { snapshot in
                var result: [String: DatabaseVenue] = [:]
                for child in snapshot.children {
                    guard let snap = child as? DataSnapshot else { continue }
                    guard let value = snap.value as? [String: Any] else { continue }
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
                        let decoded = try JSONDecoder().decode(DatabaseVenue.self, from: jsonData)
                        let resolvedId = decoded.venueId ?? snap.key
                        result[resolvedId] = decoded
                    } catch {
                        print("ERROR HERE: \(error)")
                    }
                }
                continuation.resume(returning: result)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func setValueAsync(_ ref: DatabaseReference, value: Any?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.setValue(value) { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func removeValueAsync(_ ref: DatabaseReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.removeValue { error, _ in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func fullSync(userId: String) async {
        if userId.isEmpty { return }
        self.userId = userId
        
        print("FULL SYNC TRIGGERED")
        
        guard let databaseVenues = try? await fetchDatabaseVenues() else { return }
        
        do {
            let venues = try modelContext.fetch(FetchDescriptor<Venue>())
            for venue in venues {
                if let databaseVenue = databaseVenues[venue.id] {
                    if let lastUpdated = databaseVenue.lastUpdated {
                        if lastUpdated > venue.lastUpdated {
                            venue.visited = databaseVenue.visited ?? venue.visited
                            venue.hidden = databaseVenue.hidden ?? venue.hidden
                            venue.lastUpdated = lastUpdated
                        } else if  lastUpdated < venue.lastUpdated {
                            try? await updateFirebaseVenue(id: venue.id, visited: venue.visited, hidden: venue.hidden, lastUpdated: venue.lastUpdated)
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
                    
    func updateFirebaseVenue(id: String, visited: Bool, hidden: Bool, lastUpdated: Int?) async throws {
        if userId.isEmpty { return }
        let venueNode = getReference().child("users/\(userId)/venues/\(id)")
        try await setValueAsync(venueNode.child("venueId"), value: id)
        try await setValueAsync(venueNode.child("visited"), value: visited)
        try await setValueAsync(venueNode.child("hidden"), value: hidden)
        if let lastUpdated {
            try await setValueAsync(venueNode.child("lastUpdated"), value: lastUpdated)
        }
    }
    
    func storeAddress(address: String, latitude: Double, longitude: Double) async throws {
        if userId.isEmpty { return }
        let addressNode = getReference().child("users/\(userId)/address")
        try await setValueAsync(addressNode.child("address"), value: address)
        try await setValueAsync(addressNode.child("latitude"), value: latitude)
        try await setValueAsync(addressNode.child("longitude"), value: longitude)
    }
    
    func deleteUser() async throws -> Bool {
        if userId.isEmpty { return false }
        try await removeValueAsync(getReference().child("users/\(userId)"))
        return true
    }
    
    
    /*func subscribeToChanges() -> AsyncStream<DataSnapshot> {
        AsyncStream { continuation in
            getReference().child("users").child(userId).child("venues").observe(DataEventType.value) { snapshot in
                continuation.yield(snapshot)
            }
        }
    }
    
    func observeUserData(userId: String) async {
        self.userId = userId
        
        if !userId.isEmpty {
            for await snapshot in subscribeToChanges() {
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
        let venueNode = getReference().child("users/\(userId)/venues/\(id)")
        
        venueNode.child("visited").setValue(visited)
        venueNode.child("hidden").setValue(hidden)
        if let lastUpdated {
            venueNode.child("lastUpdated").setValue(lastUpdated)
        }
    }*/
}

