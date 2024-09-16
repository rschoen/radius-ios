//
//  ContentView.swift
//  Radius
//
//  Created by Ryan Schoen on 6/20/24.
//

import SwiftUI
import SwiftData
import FirebaseAuth
import GoogleMaps

let refreshSeconds: Double = 60 * 60 * 24

@MainActor
struct ContentView: View {
    @State private var userLoggedIn = (Auth.auth().currentUser != nil)
    @State private var networkVenues = [NetworkVenue]()
    
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var firestore: FirebaseFirestore
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
    
    @State var refreshCount = 0
    @State var showAddressPicker = false

    @State var tabViewSelection: Int = 1
    var body: some View {
        TabView(selection: $tabViewSelection) {
            GoogleMapsTabView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }.tag(0)
            
            VenueListTabView(refreshCount: refreshCount) {
                Task {
                    await updateVenues(forUser: user)
                }
            }
                .tabItem {
                    Label("Venues", systemImage: "checklist")
                }.tag(1)
            SettingsTabView(userLoggedIn: userLoggedIn)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(2)
        }
        .fullScreenCover(isPresented: $showAddressPicker) {
            VStack(alignment: .leading) {
                Text("Welcome to Radius!")
                    .font(.title)
                    .padding(.leading, 30)
                    .padding(.top, 30)
                AddressPicker(isPresented: $showAddressPicker)
            }
        }
        .onAppear{
            //Firebase state change listeneer
            Auth.auth().addStateDidChangeListener{ auth, newUser in
                if let newUser {
                    userLoggedIn = true
                    user.email = newUser.email ?? ""
                    user.firebaseId = newUser.uid
                    
                } else {
                    userLoggedIn = false
                    user.email = ""
                    user.firebaseId = ""
                }
                try? modelContext.save()
                Task {
                    await firestore.fullSync(userId: user.firebaseId)
                }
                
            }
            
            Task {
                await updateVenues(forUser: user)
            }
            
            if user.address.isEmpty {
                showAddressPicker = true
            }
        }
        .onChange(of: showAddressPicker, initial: false) { _, _ in
            Task {
                if networkVenues.isEmpty {
                    await updateVenues(forUser: user)
                    
                }
            }
        }
    }
    
    func updateVenues(forUser user: User) async -> Bool {
        if user.address.isEmpty {
            print("Address is empty")
            return false
        }
        
        let homeCoords = CLLocation(latitude: user.lat, longitude: user.lng)
        
        let networkVenues = await WebService().getVenuesAroundLatLng(user.lat, user.lng)
        venues.forEach {
            $0.active = false
            $0.name = ""
            $0.reviews = 0
            $0.rating = 0
            $0.lat = 0
            $0.lng = 0
            $0.milesFromHome = 0
            $0.imageUrl = nil
        }
        
        let apiKey = getSecret(withKey: "GOOGLE_PLACES_API_KEY")
        
        for networkVenue in networkVenues {
            var found = false
            for venue in venues {
                if venue.id == networkVenue.id  {
                    //if let lat = networkVenue.location.latitude, let lng = networkVenue.location.longitude {
                        //print("updating a venue")
                    found = true
                    venue.name = networkVenue.name
                    venue.imageUrl = insertApiKeyToImageUrl(networkVenue.imageUrl)
                    venue.reviews = networkVenue.reviews ?? 0
                    venue.rating = networkVenue.rating ?? 0
                    venue.lat = networkVenue.latitude
                    venue.lng = networkVenue.longitude
                        
                    let coordinates = CLLocation(latitude: venue.lat, longitude: venue.lng)
                    venue.milesFromHome = homeCoords.distanceInMiles(fromLat: venue.lat, fromLong: venue.lng)
                    
                    venue.active = true
                    //}
                    break
                }
            }
            if !found {
                if let userRatings = networkVenue.reviews, let rating = networkVenue.rating {
                    if userRatings > 5 {
                        //print("inserting a venue")
                       
                        let newVenue = Venue(
                            name: networkVenue.name,
                            id: networkVenue.id,
                            rating: rating,
                            reviews: userRatings,
                            lat: networkVenue.latitude,
                            lng: networkVenue.longitude,
                            imageUrl: insertApiKeyToImageUrl(networkVenue.imageUrl),
                            milesFromHome: homeCoords.distanceInMiles(fromLat: networkVenue.latitude, fromLong: networkVenue.longitude))
                        modelContext.insert(newVenue)
                        try? modelContext.save()
                        refreshCount += 1
                    }
                }
            }
            //await Task.yield()
            
        }
        return true
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: [Venue.self, User.self], inMemory: true)
}



extension CLLocation {
    func distanceInMiles(fromLat: Double, fromLong: Double) -> Double {
        let coordinates = CLLocation(latitude: fromLat, longitude: fromLong)
        let distanceInMeters = self.distance(from: coordinates)
        return distanceInMeters * 0.000621371
    }
}

func insertApiKeyToImageUrl(_ url: String?) -> URL? {
    let apiKey = getSecret(withKey: "GOOGLE_PLACES_API_KEY")
    if url == nil || url!.isEmpty {
        return nil
    }
    return URL(string: url!.replacingOccurrences(of: "API_KEY", with: apiKey))
}
