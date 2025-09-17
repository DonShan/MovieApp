//
//  OfflineMoviesRepository.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine
import SwiftData

protocol OfflineMoviesRepositoryProtocol {
    func saveMovies(_ movies: [DiscoverMovieItem], page: Int) -> AnyPublisher<Void, Error>
    func getCachedMovies() -> AnyPublisher<[DiscoverMovieItem], Error>
    func getCachedMoviesForPage(_ page: Int) -> AnyPublisher<[DiscoverMovieItem], Error>
    func clearOldCache(olderThan days: Int) -> AnyPublisher<Void, Error>
    func hasCachedMovies() -> AnyPublisher<Bool, Error>
}

class OfflineMoviesRepository: OfflineMoviesRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
    }
    
    func saveMovies(_ movies: [DiscoverMovieItem], page: Int) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<OfflineMovie>(
                    predicate: #Predicate { $0.pageNumber == page }
                )
                let existingMovies = try self.modelContext.fetch(descriptor)
                for movie in existingMovies {
                    self.modelContext.delete(movie)
                }
                for movie in movies {
                    let offlineMovie = OfflineMovie(from: movie, pageNumber: page)
                    self.modelContext.insert(offlineMovie)
                }
                try self.modelContext.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCachedMovies() -> AnyPublisher<[DiscoverMovieItem], Error> {
        return Future<[DiscoverMovieItem], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<OfflineMovie>(
                    sortBy: [SortDescriptor(\.pageNumber), SortDescriptor(\.popularity, order: .reverse)]
                )
                let movies = try self.modelContext.fetch(descriptor)
                let discoverMovies = movies.map { $0.discoverMovieItem }
                promise(.success(discoverMovies))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCachedMoviesForPage(_ page: Int) -> AnyPublisher<[DiscoverMovieItem], Error> {
        return Future<[DiscoverMovieItem], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<OfflineMovie>(
                    predicate: #Predicate { $0.pageNumber == page },
                    sortBy: [SortDescriptor(\.popularity, order: .reverse)]
                )
                let movies = try self.modelContext.fetch(descriptor)
                let discoverMovies = movies.map { $0.discoverMovieItem }
                promise(.success(discoverMovies))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func clearOldCache(olderThan days: Int) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            do {
                let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                let descriptor = FetchDescriptor<OfflineMovie>(
                    predicate: #Predicate { $0.dateCached < cutoffDate }
                )
                let oldMovies = try self.modelContext.fetch(descriptor)
                
                for movie in oldMovies {
                    self.modelContext.delete(movie)
                }
                
                try self.modelContext.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func hasCachedMovies() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<OfflineMovie>()
                let count = try self.modelContext.fetchCount(descriptor)
                promise(.success(count > 0))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

enum OfflineError: Error, LocalizedError {
    case repositoryNotAvailable
    case noCachedData
    case cacheSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .repositoryNotAvailable:
            return "Offline repository is not available"
        case .noCachedData:
            return "No cached data available"
        case .cacheSaveFailed:
            return "Failed to save data to cache"
        }
    }
}
