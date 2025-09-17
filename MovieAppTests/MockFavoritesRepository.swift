//
//  MockFavoritesRepository.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

class MockFavoritesRepository: FavoritesRepositoryProtocol {
    private var favorites: [DiscoverMovieItem] = []
    var shouldThrowError = false
    var errorToThrow: Error = FavoritesError.failedToSave
    var addFavoriteCallCount = 0
    var removeFavoriteCallCount = 0
    var getFavoritesCallCount = 0
    var isFavoriteCallCount = 0
    
    var lastAddedMovie: DiscoverMovieItem?
    var lastRemovedMovie: DiscoverMovieItem?
    var lastCheckedMovie: DiscoverMovieItem?
    
    func addFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            self.addFavoriteCallCount += 1
            self.lastAddedMovie = movie
            
            if self.shouldThrowError {
                promise(.failure(self.errorToThrow))
                return
            }
            
            if !self.favorites.contains(where: { $0.id == movie.id }) {
                self.favorites.append(movie)
            }
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func removeFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            self.removeFavoriteCallCount += 1
            self.lastRemovedMovie = movie
            
            if self.shouldThrowError {
                promise(.failure(self.errorToThrow))
                return
            }
            
            self.favorites.removeAll { $0.id == movie.id }
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func getFavorites() -> AnyPublisher<[DiscoverMovieItem], Error> {
        return Future<[DiscoverMovieItem], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            self.getFavoritesCallCount += 1
            
            if self.shouldThrowError {
                promise(.failure(self.errorToThrow))
                return
            }
            
            promise(.success(self.favorites))
        }
        .eraseToAnyPublisher()
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            self.isFavoriteCallCount += 1
            self.lastCheckedMovie = movie
            
            if self.shouldThrowError {
                promise(.failure(self.errorToThrow))
                return
            }
            
            let isFavorite = self.favorites.contains { $0.id == movie.id }
            promise(.success(isFavorite))
        }
        .eraseToAnyPublisher()
    }

    func reset() {
        favorites.removeAll()
        addFavoriteCallCount = 0
        removeFavoriteCallCount = 0
        getFavoritesCallCount = 0
        isFavoriteCallCount = 0
        lastAddedMovie = nil
        lastRemovedMovie = nil
        lastCheckedMovie = nil
        shouldThrowError = false
    }
    
    func setFavorites(_ movies: [DiscoverMovieItem]) {
        favorites = movies
    }
    
    func getCurrentFavorites() -> [DiscoverMovieItem] {
        return favorites
    }
}
