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
import CryptoKit
import AuthenticationServices

struct SettingsTabView: View {
    let userLoggedIn: Bool
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var firestore: FirebaseFirestore
    @State var isAddressPickerPresented: Bool = false
    @State var isAccountDeletionConfirmationPresented: Bool = false
    @State var showAccountDeletionError: Bool = false
    @State var currentNonce: String?
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
                        DebugButtons()
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
    func DebugButtons() -> some View {
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
    }
    
    var signOutButton: some View {
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
    }
    
    var deleteAccountButton: some View {
        Button(role: .destructive) {
            Task {
                isAccountDeletionConfirmationPresented = true
            }
        } label: {
            Text("Delete account")
        }
    }
    
    var signInWithGoogleButton: some View {
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
            }.padding(6)
                .frame(maxWidth: .infinity)
        }.buttonStyle(.borderedProminent)
            .font(.system(size: 16))
            .fontWeight(.medium)
        
        .padding(5)
    }
    
    var signInWithAppleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
            if let currentNonce {
                request.nonce = sha256(currentNonce)
            }
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                if let userCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    handleAppleSignInSuccess(withCredential: userCredential)
                }
            case .failure(let error):
                print("Could not authenticate: \(error.localizedDescription)")
            }
        }.buttonStyle(.borderedProminent)
            .font(.system(size: 20))
            .padding(5)
        .onAppear {
            currentNonce = randomNonceString()
        }
    }
    
    func handleAppleSignInSuccess(withCredential appleCredential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
      guard let appleIDToken = appleCredential.identityToken else {
        print("Unable to fetch identity token")
        return
        }
              guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
              }
              // Initialize a Firebase credential, including the user's full name.
              let fbCredential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                                rawNonce: nonce,
                                                                fullName: appleCredential.fullName)
              // Sign in with Firebase.
              Auth.auth().signIn(with: fbCredential) { (authResult, error) in
                if let error {
                  // Error. If error.code == .MissingOrInvalidNonce, make sure
                  // you're sending the SHA256-hashed nonce as a hex string with
                  // your request to Apple.
                  print(error.localizedDescription)
                  return
                }
                print("SUCCESS")
              }
        
        
        print(appleCredential.user)
    
        if appleCredential.authorizedScopes.contains(.email) {
            print(appleCredential.email ?? "No email found")
        }
    }
    
    @ViewBuilder
    func SignInView() -> some View {
        Section {
            if userLoggedIn {
                let email = Auth.auth().currentUser!.email
                
                Text("Signed in as: \(email ?? "")")
                signOutButton
                deleteAccountButton
                
            }
            else {
                VStack(alignment: .center) {
                    signInWithGoogleButton
                    signInWithAppleButton
                    Text("Signing in will link your email address with the physical address you provided, and the venues near your address.")
                        .font(.system(size: 12))
                        .lineLimit(5)
                        .padding(5)
                }
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


