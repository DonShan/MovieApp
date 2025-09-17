//
//  OfflineMoviesRepositoryFactory.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine
import SwiftData

class OfflineMoviesRepositoryFactory {
    static func createRepository() -> OfflineMoviesRepositoryProtocol {
        if let modelContainer = getModelContainer() {
            return OfflineMoviesRepository(modelContainer: modelContainer)
        } else {
            return MockOfflineMoviesRepository()
        }
    }
    
    private static func getModelContainer() -> ModelContainer? {
        return OfflineMoviesRepositoryFactory.sharedModelContainer
    }
    
    static var sharedModelContainer: ModelContainer?
}

class MockOfflineMoviesRepository: OfflineMoviesRepositoryProtocol {
    func saveMovies(_ movies: [DiscoverMovieItem], page: Int) -> AnyPublisher<Void, Error> {
        return Future { promise in
            promise(.failure(OfflineError.repositoryNotAvailable))
        }
        .eraseToAnyPublisher()
    }
    
    func getCachedMovies() -> AnyPublisher<[DiscoverMovieItem], Error> {
        return Future { promise in
            promise(.failure(OfflineError.noCachedData))
        }
        .eraseToAnyPublisher()
    }
    
    func getCachedMoviesForPage(_ page: Int) -> AnyPublisher<[DiscoverMovieItem], Error> {
        return Future { promise in
            promise(.failure(OfflineError.noCachedData))
        }
        .eraseToAnyPublisher()
    }
    
    func clearOldCache(olderThan days: Int) -> AnyPublisher<Void, Error> {
        return Future { promise in
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func hasCachedMovies() -> AnyPublisher<Bool, Error> {
        return Future { promise in
            promise(.success(false))
        }
        .eraseToAnyPublisher()
    }
}
