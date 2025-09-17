//
//  EnvironmentFavoritesRepository.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine
import SwiftData
import SwiftUI

class EnvironmentFavoritesRepository: FavoritesRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            do {
                guard let movieId = movie.id else {
                    promise(.failure(FavoritesError.failedToSave))
                    return
                }
                let descriptor = FetchDescriptor<Movie>(
                    predicate: #Predicate { $0.id == movieId }
                )
                let existingMovies = try self.modelContext.fetch(descriptor)
                
                if existingMovies.isEmpty {
                    let swiftDataMovie = Movie(from: movie)
                    self.modelContext.insert(swiftDataMovie)
                    try self.modelContext.save()
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            do {
                guard let movieId = movie.id else {
                    promise(.success(()))
                    return
                }
                let descriptor = FetchDescriptor<Movie>(
                    predicate: #Predicate { $0.id == movieId }
                )
                let moviesToDelete = try self.modelContext.fetch(descriptor)
                
                for movie in moviesToDelete {
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
    
    func getFavorites() -> AnyPublisher<[DiscoverMovieItem], Error> {
        return Future<[DiscoverMovieItem], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            do {
                let descriptor = FetchDescriptor<Movie>()
                let movies = try self.modelContext.fetch(descriptor)
                let discoverMovies = movies.map { $0.discoverMovieItem }
                promise(.success(discoverMovies))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            do {
                guard let movieId = movie.id else {
                    promise(.success(false))
                    return
                }
                let descriptor = FetchDescriptor<Movie>(
                    predicate: #Predicate { $0.id == movieId }
                )
                let existingMovies = try self.modelContext.fetch(descriptor)
                promise(.success(!existingMovies.isEmpty))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}
