//
//  VenueListTabView.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import SwiftUI
import SwiftData

@MainActor
struct VenueListTabView: View {
    @Environment(\.modelContext) private var modelContext
    
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
    
    let refreshCount: Int
    var callOnRefresh: () -> Void
    
    var body: some View {
        VStack {
            
            if venues.isEmpty {
                VenueLoadingIndicator()
            } else {
                filterCheckboxes
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        VenuesList(venues: venues, showVisited: user.showVisited, showUnvisited: user.showUnvisited, showHidden: user.showHidden)
                            .id("refresh-\(refreshCount)")
                    }
                    
                }
                .refreshable {
                    callOnRefresh()
                }
            }
            Spacer(minLength: 15)
        }
    }
    
    
    
    var filterCheckboxes: some View {
        
        return HStack(alignment: .center) {
            @Bindable var user = user
            LabeledCheckbox(label: "Visited", isOn: $user.showVisited)
            LabeledCheckbox(label: "Unvisited", isOn: $user.showUnvisited)
            LabeledCheckbox(label: "Hidden", isOn: $user.showHidden)
        }
        .frame(maxWidth: .infinity)
    }
    
    func LabeledCheckbox(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Toggle(isOn: isOn) {} .toggleStyle(iOSCheckboxToggleStyle())
            Text(label)
            
        }.padding(10)
    }
    
    
    
    
}

@MainActor
struct VenuesList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var firestore: FirebaseFirestore

    let venues: [Venue]
    let showVisited: Bool
    let showUnvisited: Bool
    let showHidden: Bool

    private var filteredVenues: [Venue] {
        venues
            .filter { $0.active && (!$0.visited || showVisited) && ($0.visited || showUnvisited) && (!$0.hidden || showHidden) }
            .sorted { $0.milesFromHome < $1.milesFromHome }
    }
    
    var body: some View {
        ForEach(filteredVenues, id: \.id) { venue in
            @Bindable var venue = venue
            VenueListItem(venue)
                .onAppear {
                    if (filteredVenues.last?.id == venue.id) {
                        print("Asking for more venues")
                    }
                }
                .transition(.move(edge: .top))
        }
        //.animation(Animation.easeInOut(duration: 0.2))
    }
    
    @MainActor func VenueListItem(_ venue: Venue) -> some View {
        return ZStack(alignment: .leading) {
            venueBoundingBox
            HStack {
                HStack {
                    VenueImage(withUrl: venue.imageUrl)
                    VenueDetails(venue)
                    Spacer()
                }
                .background(venue.hidden ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
                .onTapGesture {
                    if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=123%20main%20st&query_place_id=\(venue.id)") {
                        openURL(url)
                    }
                }
                .onLongPressGesture {
                    withAnimation(.easeIn(duration: 0.5)) {
                        venue.hidden.toggle()
                        venue.setLastUpdated()
                        updateVenueInDatabase(venue)
                    }
                }
                CheckboxButton(checked: venue.visited) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        venue.visited.toggle()
                        venue.setLastUpdated()
                        updateVenueInDatabase(venue)
                    }
                }
            }
        }.padding(10)
            .background(venue.hidden ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground))
        
    }
    
    @MainActor func updateVenueInDatabase(_ venue: Venue) {
        let id = venue.id
        let visited = venue.visited
        let hidden = venue.hidden
        let lastUpdated = venue.lastUpdated
        Task {
            try await firestore.updateFirebaseVenue(id: id, visited: visited, hidden: hidden, lastUpdated: lastUpdated)
        }
        try? modelContext.save()
    }
    
    @MainActor
    @ViewBuilder
    func StarsImage(withRating rating: Double) -> some View {
        let intRating = round(convertGoogleMapsRatingToRadiusRating(rating) * 2)
        let stars = ratingToStarList(Int(intRating))
        HStack(spacing: 1) {
            ForEach(stars.indices, id: \.self) { index in
                Image(stars[index])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
            }
        }
    }
    
    @MainActor func ratingToStarList(_ rating: Int) -> [String] {
        var stars: [String] = []
        var ratingLeft = rating
        for _ in 1...5 {
            if ratingLeft >= 2 {
                stars += ["star_full"]
                ratingLeft -= 2
            } else if ratingLeft == 1 {
                stars += ["star_half"]
                ratingLeft -= 1
            } else {
                stars += ["star_empty"]
            }
        }
        return stars
    }
    
    @MainActor func StarsAndReviews(rating: Double, reviews: Int) -> some View {
        HStack {
            StarsImage(withRating: rating)
                .frame(maxHeight: 18)
            Text("\(reviews) reviews")
                .font(.system(size: 14.0))
                .foregroundStyle(.gray)
        }
    }
    
    @MainActor func VenueImage(withUrl url: URL?) -> some View {
        ZStack {
            Rectangle()
                .stroke(.gray)
            AsyncCachedImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
        }
        .frame(width: 70, height:70)
        .clipped()
    }
    
    @MainActor func VenueDetails(@Bindable _ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(venue.name)
                .fontWeight(.medium)
            StarsAndReviews(rating: venue.rating, reviews: venue.reviews)
            Text("\(String(format: "%.2f", venue.milesFromHome)) mi away")
                .font(.system(size: 12.0))
                .foregroundStyle(.gray)
        }
    }
    
    @MainActor var venueBoundingBox: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(minHeight: 60)
            .padding(0)
    }
    
    
    
}



#Preview {
    return VenueListTabView(refreshCount: 0) {}
}

