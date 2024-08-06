//
//  SettingsTabView.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import SwiftUI
import FirebaseAuth
import SwiftData
import GoogleMaps

struct SettingsTabView: View {
    let userLoggedIn: Bool
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var firestore: FirebaseFirestore
    @State var isAddressPickerPresented: Bool = false
    @State var isAccountDeletionConfirmationPresented: Bool = false
    @State var showAccountDeletionError: Bool = false
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
        
        NavigationStack {
            VStack {
                List {
                    Section {
                        Button {
                            isAddressPickerPresented = true
                        } label: {
                            Text("Reset home base")
                        }
                        #if DEBUG
                        Button() {
                            Task {
                                await firestore.fullSync(userId: user.firebaseId)
                            }
                        } label: {
                            Text("Trigger manual sync")
                        }
                        Button() {
                            user.address = ""
                            user.lat = 0.0
                            user.lng = 0.0
                        } label: {
                            Text("Clear user address")
                        }
                        Button() {
                            try? modelContext.delete(model: Venue.self)
                        } label: {
                            Text("Clear venue data")
                        }
                        #endif
                        Link("Legal info", destination: URL(string: "https://ryanschoen.com/radius_ios_licenses.txt")!)
                        
                    }
                    
                    SignInView()
                }
                .navigationTitle("Settings")
                
            }
        }.sheet(isPresented: $isAddressPickerPresented) {
            VStack(alignment: .leading) {
                Text("Reset home base")
                    .font(.title)
                    .padding(.leading, 30)
                    .padding(.top, 30)
                AddressPicker(isPresented: $isAddressPickerPresented)
            }
        }
    }
        
    
    
    @ViewBuilder
    func SignInView() -> some View {
        Section {
            if userLoggedIn {
                let email = Auth.auth().currentUser!.email
                
                Text("Signed in as: \(email ?? "")")
                Button {
                    Task {
                        do {
                            try await Authentication().logout()
                        } catch let e {
                            print(e)
                        }
                    }
                } label: {
                    Text("Sign out")
                    
                }
                
                Button(role: .destructive) {
                    Task {
                        isAccountDeletionConfirmationPresented = true
                    }
                } label: {
                    Text("Delete account")
                }
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
                    .frame(maxWidth: .infinity)
                .padding(10)
            }
            
        }
        .confirmationDialog("Delete account", isPresented: $isAccountDeletionConfirmationPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if await deleteUser() == false {
                        showAccountDeletionError = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? Your data will continue to exist on this device unless you uninstall the app.")
        }
        .alert("Could not delete account", isPresented: $showAccountDeletionError) {
            Button("OK") {}
        } message: {
            Text("Please try logging out and logging back in, and then deleting your account.")
        }
    }

    
    func deleteUser() async -> Bool {
        do {
            if await firestore.deleteUser() == false {
                return false
            }
            let user = Auth.auth().currentUser
            try await user?.delete()
        } catch {
            return false
        }
        return true
    }
}
