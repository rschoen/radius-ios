//
//  AddressPicker.swift
//  Radius
//
//  Created by Ryan Schoen on 7/10/24.
//

import SwiftUI
import SwiftData

struct AddressPicker: View {
    @State var pickerIsShown = false
    @Binding var isPresented: Bool
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var firestore: FirebaseFirestore
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
    
    var body: some View {
        ZStack {
            
            if(pickerIsShown) {
                MyPlacePicker(isPresented: $pickerIsShown, completionHandler: self.saveAddress)
            }
            ScrollView {
                VStack(alignment: .leading) {
                    Image("welcome_banner")
                        .resizable()
                        .scaledToFit()
                    Text("Radius shows all the bars and restaurants around you, and helps you keep track of which ones you've tried.")
                        .font(.system(size: 16))
                        .padding(.vertical, 5)
                    Text("Try out all the spots in your neighborhood to push your Radius larger!")
                        .font(.system(size: 16))
                        .padding(.vertical, 5)
                    Text("Enter the address of your home base to get started:")
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                    HStack {
                        Spacer()
                        Button() {
                            pickerIsShown = true
                        } label: {
                            Image(systemName: "house.fill")
                            Text("Set home base")
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.system(size: 20))
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    
                }
                .padding(30)
            }
            
        }
        
    }
    
    func saveAddress(_ address: String, latitude: Double, longitude: Double) async {
        user.address = address
        user.lat = latitude
        user.lng = longitude
        try? modelContext.save()
        isPresented = false
        await firestore.storeAddress(address: address, latitude: latitude, longitude: longitude)
    }
}

/*#Preview {
    AddressPicker()
}
*/
