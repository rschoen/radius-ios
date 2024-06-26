//
//  RadiusApp.swift
//  Radius
//
//  Created by Ryan Schoen on 6/20/24.
//

import SwiftUI
import SwiftData
import GoogleMaps
import FirebaseCore
import FirebaseAuth
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
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    //Handle Google Oauth URL
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let filePath = Bundle.main.path(forResource: "Keys", ofType: "plist")!
        let plist = NSDictionary(contentsOfFile: filePath)
        let value = plist?.object(forKey: "Google Maps API key")
        GMSServices.provideAPIKey(value as! String)
        
        FirebaseApp.configure()
        
        return true
    }
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
}
