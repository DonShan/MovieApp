//
//  OfflineMoviesUseCaseProtocol.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

protocol OfflineMoviesUseCaseProtocol {
    func saveMovies(_ movies: [DiscoverMovieItem], page: Int) -> AnyPublisher<Void, Error>
    func getCachedMovies() -> AnyPublisher<[DiscoverMovieItem], Error>
    func getCachedMoviesForPage(_ page: Int) -> AnyPublisher<[DiscoverMovieItem], Error>
    func clearOldCache(olderThan days: Int) -> AnyPublisher<Void, Error>
    func hasCachedMovies() -> AnyPublisher<Bool, Error>
}
