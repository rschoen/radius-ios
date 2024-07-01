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
    
    
    /*@State var venues = [Venue(name: "Toronado", id: "1", rating: 4.0, reviews: 10, imageUrl: URL(string: "https://s3-media0.fl.yelpcdn.com/bphoto/h5j73EvBgbMVB5kFsH8rJg/l.jpg")),
                         Venue(name: "L'Ardoise Bistro", id: "2", rating: 4.5, reviews: 26, imageUrl: URL(string: "https://s3-media0.fl.yelpcdn.com/bphoto/75romlfKPuE_g8Gn1_gcMg/l.jpg")),
                         Venue(name: "Hi Tops", id: "3", rating: 3.5, reviews: 6, imageUrl: nil),]*/
    
    @State var tabViewSelection: Int = 1
    var body: some View {
        TabView(selection: $tabViewSelection) {
            mapView
                .tabItem {
                    Label("Map", systemImage: "map")
                }.tag(0)
            
            venueListView
                .tabItem {
                    Label("Venues", systemImage: "checklist")
                }.tag(1)
            settingsView
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(2)
        }
        .onAppear{
            //Firebase state change listeneer
            Auth.auth().addStateDidChangeListener{ auth, user in
                if (user != nil) {
                    userLoggedIn = true
                } else {
                    userLoggedIn = false
                }
            }
            
            Task {
                if networkVenues.isEmpty {
                    await updateVenues()
                }
            }
        }
    }
    
    var mapView: some View {
        VStack {
            GoogleMapView()
                .clipped()
            Spacer(minLength: 15)
        }
    }
    var venueListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(venues) { venue in
                    @Bindable var venue = venue
                    VenueListItem(venue, visited: $venue.visited)
                }.id("refresh-\(refreshCount)")
            }
        }
    }
    
    @MainActor
    var settingsView: some View {
        NavigationStack {
            VStack {
            List {
                NavigationLink(value: "homebase") {
                    Text("Set home base")
                }
                NavigationLink(value: "legalinfo") {
                    Text("Legal info")
                }
                
                SignInView()
                    .padding(10)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: String.self) { link in
                
            }
            
        }
        }
    }
    
    func VenueListItem(_ venue: Venue, visited: Binding<Bool>) -> some View {
        return ZStack(alignment: .leading) {
            venueBoundingBox
            HStack {
                VenueImage(withUrl: venue.imageUrl)
                VenueDetails(venue)
                Spacer()
                Toggle(isOn: visited) {}
                .toggleStyle(iOSCheckboxToggleStyle())
            }
        }.padding(10)
            
    }
    
    func StarsImage(withRating rating: Double) -> some View {
        let intRating = round(rating * 2)
        let image = switch(intRating) {
        case 0:
            "stars_regular_0"
        case 1:
            "stars_regular_0_half"
        case 2:
            "stars_regular_1"
        case 3:
            "stars_regular_1_half"
        case 4:
            "stars_regular_2"
        case 5:
            "stars_regular_2_half"
        case 6:
            "stars_regular_3"
        case 7:
            "stars_regular_3_half"
        case 8:
            "stars_regular_4"
        case 9:
            "stars_regular_4_half"
        case 10:
            "stars_regular_5"
        default:
            "stars_regular_0"
        }
        
        return Image(image)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    func StarsAndReviews(rating: Double, reviews: Int) -> some View {
        HStack {
            StarsImage(withRating: rating)
                .frame(maxHeight: 18)
            Text("\(reviews) reviews")
                .font(.system(size: 14.0))
                .foregroundStyle(.gray)
        }
    }
    
    func VenueImage(withUrl url: URL?) -> some View {
        ZStack {
            Rectangle()
                .stroke(.gray)
            AsyncImage(url: url) { result in
                result.image?
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 70, height:70)
        .clipped()
    }
    
    func VenueDetails(@Bindable _ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(venue.name)
                .fontWeight(.medium)
            StarsAndReviews(rating: venue.rating, reviews: venue.reviews)
            Text("0.05 mi away")
                .font(.system(size: 12.0))
                .foregroundStyle(.gray)
        }
    }
    
    var venueBoundingBox: some View {
        Rectangle()
            .fill(Color.white)
            .frame(minHeight: 60)
            .padding(0)
    }
    
    @ViewBuilder
    func SignInView() -> some View {
        VStack(alignment: .center) {
        if userLoggedIn {
            let email = Auth.auth().currentUser!.email
            
                Button {
                    Task {
                        do {
                            try await Authentication().logout()
                        } catch let e {
                            print(e)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("Sign out")
                    }.padding(8)
                }.buttonStyle(.borderedProminent)
                Text(email ?? "")
            }
            else {
                Button{
                    Task {
                        do {
                            try await Authentication().googleOauth()
                        } catch let e {
                            print(e)
                        }
                    }
                }label: {
                    HStack(alignment: .center) {
                        Image(systemName: "person.badge.key.fill")
                        Text("Sign in with Google")
                    }.padding(8)
                }.buttonStyle(.borderedProminent)
            }
            
        }
        .frame(maxWidth: .infinity)
            
        
    }
    
    func updateVenues() async {
        if let downloadedVenues: Post = await WebService().downloadData(fromURL: "https://api.yelp.com/v3/businesses/search?sort_by=distance&location=2178+15th+st+san+francisco+ca&term=restaurant&limit=50&offset=0") {
            networkVenues = downloadedVenues.businesses
            print(networkVenues)
            for networkVenue in networkVenues {
                var found = false
                for venue in venues {
                    if venue.id == networkVenue.id {
                        print("updating a venue")
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
                    print("inserting a venue")
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
