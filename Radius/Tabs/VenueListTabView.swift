//
//  VenueListTabView.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import SwiftUI
import SwiftData

struct VenueListTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State var showVisited = true
    @State var showUnvisited = true
    @State var showHidden = false
    
    @Query private var venues: [Venue]
    let refreshCount: Int
    
    var body: some View {
        VStack {
            
            if venues.isEmpty {
                VenueLoadingIndicator()
            } else {
                    filterCheckboxes
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            VenuesList(showVisited: showVisited, showUnvisited: showUnvisited, showHidden: showHidden)
                                .id("refresh-\(refreshCount)")
                        }
                        
                    }
            }
            Spacer(minLength: 15)
        }
    }
    
    
    
    var filterCheckboxes: some View {

        return HStack(alignment: .center) {
            LabeledCheckbox(label: "Visited", isOn: $showVisited)
            LabeledCheckbox(label: "Unvisited", isOn: $showUnvisited)
            LabeledCheckbox(label: "Hidden", isOn: $showHidden)
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

struct VenuesList: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var firestore: FirebaseFirestore
    @Query var venues: [Venue]
    
    init(showVisited: Bool, showUnvisited: Bool, showHidden: Bool) {
        _venues = Query(filter: #Predicate<Venue> { $0.active && (!$0.visited || showVisited) && ($0.visited || showUnvisited) && (!$0.hidden || showHidden) },
                      sort: [SortDescriptor(\Venue.milesFromHome)])
        
    }
    var body: some View {
        ForEach(venues) { venue in
            @Bindable var venue = venue
            VenueListItem(venue)
        }
    }
    
    func VenueListItem(_ venue: Venue) -> some View {
        return ZStack(alignment: .leading) {
            venueBoundingBox
            HStack {
                HStack {
                    VenueImage(withUrl: venue.imageUrl)
                    VenueDetails(venue)
                    Spacer()
                }
                .background(venue.hidden ? Color.init(hue: 0, saturation: 0, brightness: 0.95) : .white)
                .onTapGesture {
                    if let url = URL(string: "https://www.google.com/maps/place/?q=place_id:\(venue.id)") {
                        openURL(url)
                    }
                }
                .onLongPressGesture {
                    venue.hidden.toggle()
                    venue.setLastUpdated()
                    updateVenueInDatabase(venue)
                }
                CheckboxButton(checked: venue.visited) {
                    venue.visited.toggle()
                    venue.setLastUpdated()
                    updateVenueInDatabase(venue)
                }
            }
        }.padding(10)
            .background(venue.hidden ? Color.init(hue: 0, saturation: 0, brightness: 0.95) : .white)
            
    }
        
        func updateVenueInDatabase(_ venue: Venue) {
            Task {
                await firestore.updateFirebaseVenue(id: venue.id, visited: venue.visited, hidden: venue.hidden, lastUpdated: venue.lastUpdated)
            }
            try? modelContext.save()
        }
    
    func StarsImage(withRating rating: Double) -> some View {
        let intRating = round(rating*rating / 5 * 2)
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
            Text("\(String(format: "%.2f", venue.milesFromHome)) mi away")
                .font(.system(size: 12.0))
                .foregroundStyle(.gray)
        }
    }
    
    var venueBoundingBox: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(minHeight: 60)
            .padding(0)
    }
    
    
    
}



#Preview {
    return VenueListTabView(refreshCount: 0)
}
