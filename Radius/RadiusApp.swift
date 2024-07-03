//
//  RadiusApp.swift
//  Radius
//
//  Created by Ryan Schoen on 6/20/24.
//

import SwiftUI
import SwiftData
import GoogleMaps
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseAnalytics
import FirebaseFirestore
import GoogleSignIn

@main
struct RadiusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Venue.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var firestore: FirebaseFirestore?
    
    init() {
        firestore = FirebaseFirestore(modelContainer: sharedModelContainer)
    }
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    //Handle Google Oauth URL
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
        .environment(firestore)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        GMSServices.provideAPIKey(getSecret(withKey: "GOOGLE_MAPS_API_KEY"))
        
        FirebaseApp.configure()
        
        return true
    }
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}

func getSecret(withKey key: String) -> String {
    let filePath = Bundle.main.path(forResource: "Keys", ofType: "plist")!
    let plist = NSDictionary(contentsOfFile: filePath)
    if let value = plist?.object(forKey: key) {
        return value as? String ?? ""
    }
    return ""
}

