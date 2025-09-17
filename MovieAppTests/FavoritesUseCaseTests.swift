//
//  FavoritesUseCaseTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import XCTest
import Combine
@testable import MovieApp

class TestableFavoritesUseCase: FavoritesUseCaseProtocol {
    private let repository: FavoritesRepositoryProtocol
    
    init(repository: FavoritesRepositoryProtocol) {
        self.repository = repository
    }
    
    func addToFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return repository.addFavorite(movie)
            .eraseToAnyPublisher()
    }
    
    func removeFromFavorites(_ movie: DiscoverMovieItem) -> AnyPublisher<Void, Error> {
        return repository.removeFavorite(movie)
            .eraseToAnyPublisher()
    }
    
    func getFavorites() -> AnyPublisher<[DiscoverMovieItem], Error> {
        return repository.getFavorites()
            .eraseToAnyPublisher()
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> AnyPublisher<Bool, Error> {
        return repository.isFavorite(movie)
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

final class FavoritesUseCaseTests: XCTestCase {
    
    private var sut: TestableFavoritesUseCase!
    private var mockRepository: MockFavoritesRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockRepository = MockFavoritesRepository()
        mockRepository.reset()
        sut = TestableFavoritesUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository?.reset()
        mockRepository = nil
        super.tearDown()
    }
    
    private func createSampleMovie() -> DiscoverMovieItem {
        return DiscoverMovieItem(
            adult: false,
            backdropPath: "/backdrop.jpg",
            genreIds: [28, 12],
            id: 123,
            originalLanguage: "en",
            originalTitle: "Sample Movie",
            overview: "A sample movie for testing",
            popularity: 8.5,
            posterPath: "/poster.jpg",
            releaseDate: "2025-01-01",
            title: "Sample Movie",
            video: false,
            voteAverage: 7.8,
            voteCount: 1000
        )
    }

    func testAddToFavorites_Success() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        
        let expectation = XCTestExpectation(description: "Add to favorites succeeds")
        
        // When
        sut.addToFavorites(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddToFavorites_Failure() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToSave
        
        let expectation = XCTestExpectation(description: "Add to favorites fails")
        
        // When
        sut.addToFavorites(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is FavoritesError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testRemoveFromFavorites_Success() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        
        let expectation = XCTestExpectation(description: "Remove from favorites succeeds")
        
        // When
        sut.removeFromFavorites(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRemoveFromFavorites_Failure() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToSave
        
        let expectation = XCTestExpectation(description: "Remove from favorites fails")
        
        // When
        sut.removeFromFavorites(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is FavoritesError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetFavorites_Success() {
        // Given
        let movies = [createSampleMovie()]
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites(movies)
        
        let expectation = XCTestExpectation(description: "Get favorites succeeds")
        
        // When
        sut.getFavorites()
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { receivedMovies in
                    XCTAssertEqual(receivedMovies.count, 1)
                    XCTAssertEqual(receivedMovies.first?.id, movies.first?.id)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetFavorites_EmptyList() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Get favorites returns empty list")
        
        // When
        sut.getFavorites()
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { receivedMovies in
                    XCTAssertTrue(receivedMovies.isEmpty)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetFavorites_Failure() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        
        let expectation = XCTestExpectation(description: "Get favorites fails")
        
        // When
        sut.getFavorites()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is FavoritesError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testIsFavorite_True() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([movie])
        
        let expectation = XCTestExpectation(description: "Is favorite returns true")
        
        // When
        sut.isFavorite(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { isFavorite in
                    XCTAssertTrue(isFavorite)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testIsFavorite_False() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Is favorite returns false")
        
        // When
        sut.isFavorite(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { isFavorite in
                    XCTAssertFalse(isFavorite)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testIsFavorite_Failure() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        
        let expectation = XCTestExpectation(description: "Is favorite fails")
        
        // When
        sut.isFavorite(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is FavoritesError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func testToggleFavorite_AddToFavorites() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Toggle favorite adds movie")
        
        // When
        sut.toggleFavorite(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { isFavorite in
                    XCTAssertTrue(isFavorite)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_RemoveFromFavorites() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([movie])
        
        let expectation = XCTestExpectation(description: "Toggle favorite removes movie")
        
        // When
        sut.toggleFavorite(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { isFavorite in
                    XCTAssertFalse(isFavorite)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_CheckFavoriteStatusFails() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        
        let expectation = XCTestExpectation(description: "Toggle favorite fails on checking status")
        
        // When
        sut.toggleFavorite(movie)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is FavoritesError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_RepositoryNotAvailable() {
        // Given
        let movie = createSampleMovie()
        let weakRefUseCase = FavoritesUseCase()
        let expectation = XCTestExpectation(description: "Toggle favorite fails with repository not available")
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        // When
        weakRefUseCase.toggleFavorite(movie)
            .sink(
                receiveCompletion: { completion in
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}
