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
            
            VenueListTabView(refreshCount: refreshCount)
                .tabItem {
                    Label("Venues", systemImage: "checklist")
                }.tag(1)
            SettingsTabView(userLoggedIn: userLoggedIn)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(2)
        }.sheet(isPresented: $showAddressPicker) {
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
                if networkVenues.isEmpty {
                    await updateVenues()
                }
            }
            
            if user.address.isEmpty {
                showAddressPicker = true
            }
        }
    }
    
    func updateVenues() async {
        let homeCoords = CLLocation(latitude: user.lat, longitude: user.lng)
        
        let networkVenues = await WebService().getVenuesAroundAddress(user.address)
        venues.forEach { $0.active = false }
        
        if let networkVenues {
            for networkVenue in networkVenues {
                var found = false
                for venue in venues {
                    if venue.id == networkVenue.id  {
                        if let lat = networkVenue.coordinates.latitude, let lng = networkVenue.coordinates.longitude {
                            //print("updating a venue")
                            found = true
                            venue.name = networkVenue.name
                            venue.imageUrl = URL(string: networkVenue.image_url)
                            venue.reviews = networkVenue.review_count
                            venue.rating = networkVenue.rating
                            venue.lat = lat
                            venue.lng = lng
                            
                            let coordinates = CLLocation(latitude: venue.lat, longitude: venue.lng)
                            let metersFromHome = homeCoords.distance(from: coordinates)
                            venue.milesFromHome = metersFromHome * 0.000621371
                            
                            venue.active = true
                        }
                        break
                    }
                }
                if !found && networkVenue.review_count >= 5 {
                    //print("inserting a venue")
                    let newVenue = Venue(name: networkVenue.name, id: networkVenue.id, rating: networkVenue.rating, reviews: networkVenue.review_count, imageUrl: URL(string: networkVenue.image_url))
                    modelContext.insert(newVenue)
                    try? modelContext.save()
                    refreshCount += 1
                }
            }
        }
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: [Venue.self, User.self], inMemory: true)
}
