//
//  OfflineMoviesUseCase.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

class OfflineMoviesUseCase: OfflineMoviesUseCaseProtocol {
    private let offlineMoviesRepository: OfflineMoviesRepositoryProtocol
    
    init(offlineMoviesRepository: OfflineMoviesRepositoryProtocol) {
        self.offlineMoviesRepository = offlineMoviesRepository
    }
    
    func saveMovies(_ movies: [DiscoverMovieItem], page: Int) -> AnyPublisher<Void, Error> {
        return offlineMoviesRepository.saveMovies(movies, page: page)
    }
    
    func getCachedMovies() -> AnyPublisher<[DiscoverMovieItem], Error> {
        return offlineMoviesRepository.getCachedMovies()
    }
    
    func getCachedMoviesForPage(_ page: Int) -> AnyPublisher<[DiscoverMovieItem], Error> {
        return offlineMoviesRepository.getCachedMoviesForPage(page)
    }
    
    func clearOldCache(olderThan days: Int) -> AnyPublisher<Void, Error> {
        return offlineMoviesRepository.clearOldCache(olderThan: days)
    }
    
    func hasCachedMovies() -> AnyPublisher<Bool, Error> {
        return offlineMoviesRepository.hasCachedMovies()
    }
}
