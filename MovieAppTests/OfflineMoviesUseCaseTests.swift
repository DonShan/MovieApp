//
//  OfflineMoviesUseCaseTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import XCTest
import Combine
@testable import MovieApp

final class OfflineMoviesUseCaseTests: XCTestCase {
    
    private var sut: OfflineMoviesUseCase!
    private var mockRepository: MockOfflineMoviesRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockRepository = MockOfflineMoviesRepository()
        mockRepository.reset()
        sut = OfflineMoviesUseCase(offlineMoviesRepository: mockRepository)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository?.reset()
        mockRepository = nil
        super.tearDown()
    }
    
    private func createSampleMovies() -> [DiscoverMovieItem] {
        return [
            DiscoverMovieItem(
                adult: false,
                backdropPath: "/backdrop1.jpg",
                genreIds: [28, 12],
                id: 123,
                originalLanguage: "en",
                originalTitle: "Sample Movie 1",
                overview: "A sample movie for testing",
                popularity: 8.5,
                posterPath: "/poster1.jpg",
                releaseDate: "2025-01-01",
                title: "Sample Movie 1",
                video: false,
                voteAverage: 7.8,
                voteCount: 1000
            ),
            DiscoverMovieItem(
                adult: false,
                backdropPath: "/backdrop2.jpg",
                genreIds: [35, 18],
                id: 456,
                originalLanguage: "en",
                originalTitle: "Sample Movie 2",
                overview: "Another sample movie for testing",
                popularity: 7.2,
                posterPath: "/poster2.jpg",
                releaseDate: "2025-02-01",
                title: "Sample Movie 2",
                video: false,
                voteAverage: 6.9,
                voteCount: 800
            )
        ]
    }

    func testSaveMovies_Success() {
        // Given
        let movies = createSampleMovies()
        let page = 1
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Save movies succeeds")
        
        // When
        sut.saveMovies(movies, page: page)
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
        XCTAssertEqual(mockRepository.saveMoviesCallCount, 1)
        XCTAssertEqual(mockRepository.lastSavedPage, page)
        XCTAssertEqual(mockRepository.lastSavedMovies?.count, movies.count)
    }
    
    func testSaveMovies_Failure() {
        // Given
        let movies = createSampleMovies()
        let page = 1
        mockRepository.reset()
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = OfflineError.cacheSaveFailed
        
        let expectation = XCTestExpectation(description: "Save movies fails")
        
        // When
        sut.saveMovies(movies, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is OfflineError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.saveMoviesCallCount, 1)
    }
    
    func testSaveMovies_EmptyMoviesList() {
        // Given
        let movies: [DiscoverMovieItem] = []
        let page = 1
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Save empty movies list succeeds")
        
        // When
        sut.saveMovies(movies, page: page)
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
        XCTAssertEqual(mockRepository.saveMoviesCallCount, 1)
        XCTAssertEqual(mockRepository.lastSavedMovies?.count, 0)
    }

    func testGetCachedMovies_Success() {
        // Given
        let movies = createSampleMovies()
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        mockRepository.savedMovies = movies
        
        let expectation = XCTestExpectation(description: "Get cached movies succeeds")
        
        // When
        sut.getCachedMovies()
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { receivedMovies in
                    XCTAssertEqual(receivedMovies.count, movies.count)
                    XCTAssertEqual(receivedMovies.first?.id, movies.first?.id)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getCachedMoviesCallCount, 1)
    }
    
    func testGetCachedMovies_EmptyCache() {
        // Given
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        mockRepository.savedMovies = []
        
        let expectation = XCTestExpectation(description: "Get cached movies returns empty list")
        
        // When
        sut.getCachedMovies()
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
        XCTAssertEqual(mockRepository.getCachedMoviesCallCount, 1)
    }
    
    func testGetCachedMovies_Failure() {
        // Given
        mockRepository.reset()
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = OfflineError.noCachedData
        
        let expectation = XCTestExpectation(description: "Get cached movies fails")
        
        // When
        sut.getCachedMovies()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is OfflineError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getCachedMoviesCallCount, 1)
    }

    func testGetCachedMoviesForPage_Success() {
        // Given
        let movies = createSampleMovies()
        let page = 2
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        mockRepository.moviesByPage[page] = movies
        
        let expectation = XCTestExpectation(description: "Get cached movies for page succeeds")
        
        // When
        sut.getCachedMoviesForPage(page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { receivedMovies in
                    XCTAssertEqual(receivedMovies.count, movies.count)
                    XCTAssertEqual(receivedMovies.first?.id, movies.first?.id)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getCachedMoviesForPageCallCount, 1)
        XCTAssertEqual(mockRepository.lastRequestedPage, page)
    }
    
    func testGetCachedMoviesForPage_NoMoviesForPage() {
        // Given
        let page = 5
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        mockRepository.moviesByPage = [:]
        let expectation = XCTestExpectation(description: "Get cached movies for page returns empty list")
        
        // When
        sut.getCachedMoviesForPage(page)
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
        XCTAssertEqual(mockRepository.getCachedMoviesForPageCallCount, 1)
        XCTAssertEqual(mockRepository.lastRequestedPage, page)
    }
    
    func testGetCachedMoviesForPage_Failure() {
        // Given
        let page = 1
        mockRepository.reset()
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = OfflineError.repositoryNotAvailable
        
        let expectation = XCTestExpectation(description: "Get cached movies for page fails")
        
        // When
        sut.getCachedMoviesForPage(page)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is OfflineError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.getCachedMoviesForPageCallCount, 1)
    }

    func testClearOldCache_Success() {
        // Given
        let days = 7
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Clear old cache succeeds")
        
        // When
        sut.clearOldCache(olderThan: days)
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
        XCTAssertEqual(mockRepository.clearOldCacheCallCount, 1)
        XCTAssertEqual(mockRepository.lastClearCacheDays, days)
    }
    
    func testClearOldCache_ZeroDays() {
        // Given
        let days = 0
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        
        let expectation = XCTestExpectation(description: "Clear old cache with 0 days succeeds")
        
        // When
        sut.clearOldCache(olderThan: days)
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
        XCTAssertEqual(mockRepository.clearOldCacheCallCount, 1)
        XCTAssertEqual(mockRepository.lastClearCacheDays, days)
    }
    
    func testClearOldCache_Failure() {
        // Given
        let days = 30
        mockRepository.reset()
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = OfflineError.repositoryNotAvailable
        
        let expectation = XCTestExpectation(description: "Clear old cache fails")
        
        // When
        sut.clearOldCache(olderThan: days)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is OfflineError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.clearOldCacheCallCount, 1)
    }
    
    func testHasCachedMovies_True() {
        // Given
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        mockRepository.hasCachedMoviesResponse = true
        
        let expectation = XCTestExpectation(description: "Has cached movies returns true")
        
        // When
        sut.hasCachedMovies()
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { hasCachedMovies in
                    XCTAssertTrue(hasCachedMovies)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.hasCachedMoviesCallCount, 1)
    }
    
    func testHasCachedMovies_False() {
        // Given
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        mockRepository.hasCachedMoviesResponse = false
        
        let expectation = XCTestExpectation(description: "Has cached movies returns false")
        
        // When
        sut.hasCachedMovies()
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    }
                },
                receiveValue: { hasCachedMovies in
                    XCTAssertFalse(hasCachedMovies)
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.hasCachedMoviesCallCount, 1)
    }
    
    func testHasCachedMovies_Failure() {
        // Given
        mockRepository.reset()
        mockRepository.shouldSucceed = false
        mockRepository.errorToThrow = OfflineError.repositoryNotAvailable
        
        let expectation = XCTestExpectation(description: "Has cached movies fails")
        
        // When
        sut.hasCachedMovies()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is OfflineError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.hasCachedMoviesCallCount, 1)
    }
    
    // MARK: - Integration Tests
    
    func testSaveAndRetrieveMovies_Integration() {
        // Given
        let movies = createSampleMovies()
        let page = 1
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        
        let saveExpectation = XCTestExpectation(description: "Save movies")
        let retrieveExpectation = XCTestExpectation(description: "Retrieve movies")
        sut.saveMovies(movies, page: page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        saveExpectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        sut.getCachedMoviesForPage(page)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        retrieveExpectation.fulfill()
                    }
                },
                receiveValue: { retrievedMovies in
                    XCTAssertEqual(retrievedMovies.count, movies.count)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation, retrieveExpectation], timeout: 1.0)
    }
    
    func testMultiplePagesCaching() {
        let page1Movies = [createSampleMovies().first!]
        let page2Movies = [createSampleMovies().last!]
        mockRepository.reset()
        mockRepository.shouldSucceed = true
        let page1SaveExpectation = XCTestExpectation(description: "Save page 1")
        let page2SaveExpectation = XCTestExpectation(description: "Save page 2")
        let page1RetrieveExpectation = XCTestExpectation(description: "Retrieve page 1")
        let page2RetrieveExpectation = XCTestExpectation(description: "Retrieve page 2")

        sut.saveMovies(page1Movies, page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        page1SaveExpectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        sut.saveMovies(page2Movies, page: 2)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        page2SaveExpectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        sut.getCachedMoviesForPage(1)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        page1RetrieveExpectation.fulfill()
                    }
                },
                receiveValue: { retrievedMovies in
                    XCTAssertEqual(retrievedMovies.count, 1)
                }
            )
            .store(in: &cancellables)
        
        sut.getCachedMoviesForPage(2)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        page2RetrieveExpectation.fulfill()
                    }
                },
                receiveValue: { retrievedMovies in
                    XCTAssertEqual(retrievedMovies.count, 1)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [page1SaveExpectation, page2SaveExpectation, page1RetrieveExpectation, page2RetrieveExpectation], timeout: 1.0)
    }
}
