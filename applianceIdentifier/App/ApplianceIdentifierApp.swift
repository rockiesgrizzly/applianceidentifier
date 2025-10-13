//
//  ApplianceIdentifierApp.swift
//  applianceIdentifier
//
//  Created by Josh MacDonald on 10/13/25.
//

import SwiftUI
import SwiftData

/// Main application entry point for Appliance Identifier.
/// Configures SwiftData persistence and dependency injection.
@main
struct ApplianceIdentifierApp: App {
    /// SwiftData model container for persisting appliances.
    /// Configured with non-volatile storage for the Appliance entity.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Appliance.self,
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
                .environment(AppDependencyContainer(modelContainer: sharedModelContainer))
        }
        .modelContainer(sharedModelContainer)
    }
}
