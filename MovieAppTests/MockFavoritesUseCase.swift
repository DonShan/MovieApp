//
//  MockFavoritesUseCase.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import Foundation
import Combine
@testable import MovieApp

class MockFavoritesUseCase: FavoritesUseCaseProtocol {
    private let mockRepository: MockFavoritesRepository
    var shouldThrowError: Bool = false
    var errorToThrow: Error = FavoritesError.repositoryNotAvailable
    
    init(mockRepository: MockFavoritesRepository) {
        self.mockRepository = mockRepository
    }
    
    func addToFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return mockRepository.addFavorite(movie)
            .eraseToAnyPublisher()
    }
    
    func removeFromFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return mockRepository.removeFavorite(movie)
            .eraseToAnyPublisher()
    }
    
    func getFavorites() -> AnyPublisher<[DiscoverMovieItem], Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return mockRepository.getFavorites()
            .eraseToAnyPublisher()
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return mockRepository.isFavorite(movie)
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
    
    func setFavorites(_ movies: [DiscoverMovieItem]) {
        mockRepository.setFavorites(movies)
    }
    
    func reset() {
        shouldThrowError = false
        errorToThrow = FavoritesError.repositoryNotAvailable
        mockRepository.reset()
    }
}
