//
//  FavoritesRepositoryProtocol.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

protocol FavoritesRepositoryProtocol {
    func addFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error>
    func removeFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error>
    func getFavorites() -> AnyPublisher<[DiscoverMovieItem], Error>
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error>
}
