//
//  SettingsTabView.swift
//  Radius
//
//  Created by Ryan Schoen on 7/3/24.
//

import SwiftUI
import FirebaseAuth

struct SettingsTabView: View {
    let userLoggedIn: Bool
    
    var body: some View {
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
}
