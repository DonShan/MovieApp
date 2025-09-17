//
//  FavoritesUseCaseProtocol.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

protocol FavoritesUseCaseProtocol {
    func addToFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error>
    func removeFromFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error>
    func getFavorites() -> AnyPublisher<[DiscoverMovieItem], Error>
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error>
    func toggleFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error>
}
