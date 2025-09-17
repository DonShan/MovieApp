//
//  FavoritesRepository.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

class FavoritesRepository: FavoritesRepositoryProtocol {
    @Inject(key: "UserDefaultsManager")
    private var userDefaultsManager: UserDefaultsManagerProtocol
    
    func addFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            do {
                var favorites = self.getFavoritesSync()
                if !favorites.contains(where: { $0.id == movie.id }) {
                    favorites.append(movie)
                    self.userDefaultsManager.save(favorites, forKey: UserDefaultsManager.favoritesKey)
                } else {
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
                var favorites = self.getFavoritesSync()
                favorites.removeAll { $0.id == movie.id }
                self.userDefaultsManager.save(favorites, forKey: UserDefaultsManager.favoritesKey)
                promise(.success(()))
            } catch {
                print("FavoritesRepository: Error removing favorite: \(error)")
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
            
            let favorites = self.getFavoritesSync()
            promise(.success(favorites))
        }
        .eraseToAnyPublisher()
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FavoritesError.repositoryNotAvailable))
                return
            }
            
            let favorites = self.getFavoritesSync()
            let isFavorite = favorites.contains { $0.id == movie.id }
            promise(.success(isFavorite))
        }
        .eraseToAnyPublisher()
    }
    
    private func getFavoritesSync() -> [DiscoverMovieItem] {
        return userDefaultsManager.load([DiscoverMovieItem].self, forKey: UserDefaultsManager.favoritesKey) ?? []
    }
}

enum FavoritesError: Error, LocalizedError {
    case repositoryNotAvailable
    case failedToSave
    case failedToLoad
    
    var errorDescription: String? {
        switch self {
        case .repositoryNotAvailable:
            return "Repository not available"
        case .failedToSave:
            return "Failed to save favorites"
        case .failedToLoad:
            return "Failed to load favorites"
        }
    }
}
