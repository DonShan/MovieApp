//
//  FavoritesUseCase.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

class FavoritesUseCase: FavoritesUseCaseProtocol {
    @Inject(key: "FavoritesRepository")
    private var favoritesRepository: FavoritesRepositoryProtocol
    
    func addToFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return favoritesRepository.addFavorite(movie)
            .eraseToAnyPublisher()
    }
    
    func removeFromFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return favoritesRepository.removeFavorite(movie)
            .eraseToAnyPublisher()
    }
    
    func getFavorites() -> AnyPublisher<[DiscoverMovieItem], Error> {
        return favoritesRepository.getFavorites()
            .eraseToAnyPublisher()
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error> {
        return favoritesRepository.isFavorite(movie)
            .eraseToAnyPublisher()
    }
    
    func toggleFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error> {
        return isFavorite(movie)
            .flatMap { [weak self] isFavorite -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: FavoritesError.repositoryNotAvailable)
                        .eraseToAnyPublisher()
                }
                
                if isFavorite {
                    return self.removeFromFavorites(movie)
                        .map { false }
                        .eraseToAnyPublisher()
                } else {
                    return self.addToFavorites(movie)
                        .map { true }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
