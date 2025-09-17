//
//  MockOfflineMoviesRepository.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import Foundation
import Combine
@testable import MovieApp

class MockOfflineMoviesRepository: OfflineMoviesRepositoryProtocol {
    var shouldSucceed: Bool = true
    var errorToThrow: Error = OfflineError.repositoryNotAvailable
    var savedMovies: [DiscoverMovieItem] = []
    var moviesByPage: [Int: [DiscoverMovieItem]] = [:]
    var hasCachedMoviesResponse: Bool = false
    var saveMoviesCallCount = 0
    var getCachedMoviesCallCount = 0
    var getCachedMoviesForPageCallCount = 0
    var clearOldCacheCallCount = 0
    var hasCachedMoviesCallCount = 0
    var lastSavedMovies: [DiscoverMovieItem]?
    var lastSavedPage: Int?
    var lastRequestedPage: Int?
    var lastClearCacheDays: Int?
    
    func reset() {
        shouldSucceed = true
        errorToThrow = OfflineError.repositoryNotAvailable
        savedMovies = []
        moviesByPage = [:]
        hasCachedMoviesResponse = false
        
        saveMoviesCallCount = 0
        getCachedMoviesCallCount = 0
        getCachedMoviesForPageCallCount = 0
        clearOldCacheCallCount = 0
        hasCachedMoviesCallCount = 0
        
        lastSavedMovies = nil
        lastSavedPage = nil
        lastRequestedPage = nil
        lastClearCacheDays = nil
    }
    
    func saveMovies(_ movies: [DiscoverMovieItem], page: Int) -> AnyPublisher<Void, Error> {
        saveMoviesCallCount += 1
        lastSavedMovies = movies
        lastSavedPage = page
        
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            if self.shouldSucceed {
                self.moviesByPage[page] = movies
                self.savedMovies.append(contentsOf: movies)
                promise(.success(()))
            } else {
                promise(.failure(self.errorToThrow))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCachedMovies() -> AnyPublisher<[DiscoverMovieItem], Error> {
        getCachedMoviesCallCount += 1
        
        return Future<[DiscoverMovieItem], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            if self.shouldSucceed {
                promise(.success(self.savedMovies))
            } else {
                promise(.failure(self.errorToThrow))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCachedMoviesForPage(_ page: Int) -> AnyPublisher<[DiscoverMovieItem], Error> {
        getCachedMoviesForPageCallCount += 1
        lastRequestedPage = page
        
        return Future<[DiscoverMovieItem], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            if self.shouldSucceed {
                let moviesForPage = self.moviesByPage[page] ?? []
                promise(.success(moviesForPage))
            } else {
                promise(.failure(self.errorToThrow))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func clearOldCache(olderThan days: Int) -> AnyPublisher<Void, Error> {
        clearOldCacheCallCount += 1
        lastClearCacheDays = days
        
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            if self.shouldSucceed {
                self.savedMovies.removeAll()
                self.moviesByPage.removeAll()
                promise(.success(()))
            } else {
                promise(.failure(self.errorToThrow))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func hasCachedMovies() -> AnyPublisher<Bool, Error> {
        hasCachedMoviesCallCount += 1
        
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(OfflineError.repositoryNotAvailable))
                return
            }
            
            if self.shouldSucceed {
                promise(.success(self.hasCachedMoviesResponse))
            } else {
                promise(.failure(self.errorToThrow))
            }
        }
        .eraseToAnyPublisher()
    }
}
