//
//  trackCO2App.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import SwiftUI
import SwiftData
import TipKit
import UserNotifications

@main
struct trackCO2App: App {
    @State private var store = Store()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Activity.self,
            FavoritePlace.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        // To enable iCloud sync, replace the line above with:
        //   ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        // and add the iCloud + CloudKit entitlements in Xcode → Signing & Capabilities.

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        do {
            try Tips.configure([
                .datastoreLocation(.applicationDefault),
                .displayFrequency(.immediate)
            ])
        } catch {
            print("Error initializing TipKit \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task { await NotificationManager.shared.checkAuthorization() }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
