//
//  ContentView.swift
//  Radius
//
//  Created by Ryan Schoen on 6/20/24.
//

import SwiftUI
import SwiftData



struct ContentView: View {
    
    
    @Environment(\.modelContext) private var modelContext
    //@Query private var venues: [Venue]
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
    
    
    @State var venues = [Venue(name: "Toronado", id: "1", rating: 4.0, reviews: 10, imageUrl: URL(string: "https://s3-media0.fl.yelpcdn.com/bphoto/h5j73EvBgbMVB5kFsH8rJg/l.jpg")),
                         Venue(name: "L'Ardoise Bistro", id: "2", rating: 4.5, reviews: 26, imageUrl: URL(string: "https://s3-media0.fl.yelpcdn.com/bphoto/75romlfKPuE_g8Gn1_gcMg/l.jpg")),
                         Venue(name: "Hi Tops", id: "3", rating: 3.5, reviews: 6, imageUrl: nil),]
    
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
                ForEach(venues.indices) { index in
                    VenueListItem(venues[index], index: index)
                }
            }
        }
    }
    var settingsView: some View {
        NavigationStack {
            List {
                NavigationLink(value: "homebase") {
                    Text("Set home base")
                }
                NavigationLink(value: "signin") {
                    Text("Sign in")
                }
                NavigationLink(value: "legalinfo") {
                    Text("Legal info")
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: String.self) { link in
                
            }
        }
    }
    
    func VenueListItem(_ venue: Venue, index: Int) -> some View {
        return ZStack(alignment: .leading) {
            venueBoundingBox
            HStack {
                VenueImage(withUrl: venue.imageUrl)
                VenueDetails(venue)
                Spacer()
                Toggle(isOn: $venues[index].visited) {}
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
    
    func VenueDetails(_ venue: Venue) -> some View {
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
}

#Preview {
    ContentView()
        .modelContainer(for: [Venue.self, User.self], inMemory: true)
}
