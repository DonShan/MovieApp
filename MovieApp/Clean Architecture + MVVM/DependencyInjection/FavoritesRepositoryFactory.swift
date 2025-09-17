//
//  FavoritesRepositoryFactory.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import SwiftData

class FavoritesRepositoryFactory {
    static func createRepository() -> FavoritesRepositoryProtocol {
        if let modelContainer = getModelContainer() {
            return SwiftDataFavoritesRepository(modelContainer: modelContainer)
        } else {
            return FavoritesRepository()
        }
    }
    
    private static func getModelContainer() -> ModelContainer? {
        return FavoritesRepositoryFactory.sharedModelContainer
    }
    
    static var sharedModelContainer: ModelContainer?
}
