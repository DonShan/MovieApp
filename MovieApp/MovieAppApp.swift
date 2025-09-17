//
//  MovieAppApp.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI
import SwiftData

@main
struct MovieAppApp: App {
    init() {
        dependencyRegister()
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Movie.self,
            OfflineMovie.self,
            CachedImage.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            FavoritesRepositoryFactory.sharedModelContainer = container
            OfflineMoviesRepositoryFactory.sharedModelContainer = container
            ImageCacheManager.sharedModelContainer = container
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
