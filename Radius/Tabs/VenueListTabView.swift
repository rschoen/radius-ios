//
//  VenueListTabView.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import SwiftUI

struct VenueListTabView: View {
    let venues: Array<Venue>
    let refreshCount: Int
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(venues) { venue in
                    @Bindable var venue = venue
                    VenueListItem(venue, visited: $venue.visited)
                }.id("refresh-\(refreshCount)")
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
}
