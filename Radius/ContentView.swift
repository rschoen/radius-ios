//
//  ContentView.swift
//  Radius
//
//  Created by Ryan Schoen on 6/20/24.
//

import SwiftUI
import SwiftData
import FirebaseAuth


@MainActor
struct ContentView: View {
    @State private var userLoggedIn = (Auth.auth().currentUser != nil)
    @State private var networkVenues = [NetworkVenue]()
    
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var firestore: FirebaseFirestore
    @Query private var venues: [Venue]
    @Query private var users: [User]
    @State var refreshCount = 0
    
    private var user: User {
        if let user = users.first {
            return user
        } else {
            let user = User()
            modelContext.insert(user)
            return user
        }
    }
    

    @State var tabViewSelection: Int = 1
    var body: some View {
        TabView(selection: $tabViewSelection) {
            GoogleMapsTabView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }.tag(0)
            
            VenueListTabView(venues: venues, refreshCount: refreshCount)
                .tabItem {
                    Label("Venues", systemImage: "checklist")
                }.tag(1)
            SettingsTabView(userLoggedIn: userLoggedIn)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(2)
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
                firestore.observeUserData(userId: user.firebaseId)
                
            }
            
            Task {
                if networkVenues.isEmpty {
                    await updateVenues()
                }
            }
        }
    }
    
    func updateVenues() async {
        if let downloadedVenues: Post = await WebService().downloadData(fromURL: "https://api.yelp.com/v3/businesses/search?sort_by=distance&location=2178+15th+st+san+francisco+ca&term=restaurant&limit=50&offset=0") {
            networkVenues = downloadedVenues.businesses
            //print(networkVenues)
            for networkVenue in networkVenues {
                var found = false
                for venue in venues {
                    if venue.id == networkVenue.id {
                        //print("updating a venue")
                        found = true
                        venue.name = networkVenue.name
                        venue.imageUrl = URL(string: networkVenue.image_url)
                        venue.reviews = networkVenue.review_count
                        venue.rating = networkVenue.rating
                        venue.lat = networkVenue.coordinates.latitude
                        venue.lng = networkVenue.coordinates.longitude
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
