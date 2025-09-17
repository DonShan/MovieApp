//
//  MockFavoritesRepositoryTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import XCTest
import Combine
@testable import MovieApp

final class MockFavoritesRepositoryTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()
    private var mockRepository: MockFavoritesRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockFavoritesRepository()
    }

    override func tearDown() {
        cancellables.removeAll()
        mockRepository = nil
        super.tearDown()
    }

    func test_addFavorite_success() {
        // Given
        let movie = createTestMovie()
        let expectation = self.expectation(description: "Should add favorite successfully")

        // When
        mockRepository.addFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { _ in
                // Then
                XCTAssertEqual(self.mockRepository.addFavoriteCallCount, 1)
                XCTAssertEqual(self.mockRepository.lastAddedMovie?.id, movie.id)
                XCTAssertTrue(self.mockRepository.getCurrentFavorites().contains { $0.id == movie.id })
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_addFavorite_duplicate() {
        // Given
        let movie = createTestMovie()
        mockRepository.setFavorites([movie])
        let expectation = self.expectation(description: "Should handle duplicate favorite")

        // When
        mockRepository.addFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { _ in
                // Then
                XCTAssertEqual(self.mockRepository.addFavoriteCallCount, 1)
                XCTAssertEqual(self.mockRepository.getCurrentFavorites().count, 1)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_addFavorite_failure() {
        // Given
        let movie = createTestMovie()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToSave
        let expectation = self.expectation(description: "Should return error")

        // When
        mockRepository.addFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertEqual(self.mockRepository.addFavoriteCallCount, 1)
                    XCTAssertEqual(self.mockRepository.lastAddedMovie?.id, movie.id)
                    XCTAssertTrue(error is FavoritesError)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure, got success")
                }
            }, receiveValue: { _ in
                XCTFail("Expected no value on failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_removeFavorite_success() {
        // Given
        let movie = createTestMovie()
        mockRepository.setFavorites([movie])
        let expectation = self.expectation(description: "Should remove favorite successfully")

        // When
        mockRepository.removeFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { _ in
                // Then
                XCTAssertEqual(self.mockRepository.removeFavoriteCallCount, 1)
                XCTAssertEqual(self.mockRepository.lastRemovedMovie?.id, movie.id)
                XCTAssertFalse(self.mockRepository.getCurrentFavorites().contains { $0.id == movie.id })
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_removeFavorite_notFound() {
        // Given
        let movie = createTestMovie()
        let expectation = self.expectation(description: "Should handle non-existent favorite")

        // When
        mockRepository.removeFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { _ in
                // Then
                XCTAssertEqual(self.mockRepository.removeFavoriteCallCount, 1)
                XCTAssertEqual(self.mockRepository.lastRemovedMovie?.id, movie.id)
                XCTAssertEqual(self.mockRepository.getCurrentFavorites().count, 0)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_removeFavorite_failure() {
        // Given
        let movie = createTestMovie()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToSave
        let expectation = self.expectation(description: "Should return error")

        // When
        mockRepository.removeFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertEqual(self.mockRepository.removeFavoriteCallCount, 1)
                    XCTAssertEqual(self.mockRepository.lastRemovedMovie?.id, movie.id)
                    XCTAssertTrue(error is FavoritesError)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure, got success")
                }
            }, receiveValue: { _ in
                XCTFail("Expected no value on failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_getFavorites_success() {
        // Given
        let movies = [createTestMovie(id: 1), createTestMovie(id: 2)]
        mockRepository.setFavorites(movies)
        let expectation = self.expectation(description: "Should return favorites")

        // When
        mockRepository.getFavorites()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { favorites in
                // Then
                XCTAssertEqual(self.mockRepository.getFavoritesCallCount, 1)
                XCTAssertEqual(favorites.count, 2)
                XCTAssertEqual(favorites.first?.id, 1)
                XCTAssertEqual(favorites.last?.id, 2)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_getFavorites_empty() {
        // Given
        let expectation = self.expectation(description: "Should return empty favorites")

        // When
        mockRepository.getFavorites()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { favorites in
                // Then
                XCTAssertEqual(self.mockRepository.getFavoritesCallCount, 1)
                XCTAssertTrue(favorites.isEmpty)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_getFavorites_failure() {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        let expectation = self.expectation(description: "Should return error")

        // When
        mockRepository.getFavorites()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertEqual(self.mockRepository.getFavoritesCallCount, 1)
                    XCTAssertTrue(error is FavoritesError)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure, got success")
                }
            }, receiveValue: { _ in
                XCTFail("Expected no value on failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_isFavorite_true() {
        // Given
        let movie = createTestMovie()
        mockRepository.setFavorites([movie])
        let expectation = self.expectation(description: "Should return true for favorite")

        // When
        mockRepository.isFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { isFavorite in
                // Then
                XCTAssertEqual(self.mockRepository.isFavoriteCallCount, 1)
                XCTAssertEqual(self.mockRepository.lastCheckedMovie?.id, movie.id)
                XCTAssertTrue(isFavorite)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_isFavorite_false() {
        // Given
        let movie = createTestMovie()
        let expectation = self.expectation(description: "Should return false for non-favorite")

        // When
        mockRepository.isFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { isFavorite in
                // Then
                XCTAssertEqual(self.mockRepository.isFavoriteCallCount, 1)
                XCTAssertEqual(self.mockRepository.lastCheckedMovie?.id, movie.id)
                XCTAssertFalse(isFavorite)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_isFavorite_failure() {
        // Given
        let movie = createTestMovie()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        let expectation = self.expectation(description: "Should return error")

        // When
        mockRepository.isFavorite(movie)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertEqual(self.mockRepository.isFavoriteCallCount, 1)
                    XCTAssertEqual(self.mockRepository.lastCheckedMovie?.id, movie.id)
                    XCTAssertTrue(error is FavoritesError)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure, got success")
                }
            }, receiveValue: { _ in
                XCTFail("Expected no value on failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_reset() {
        // Given
        let movie = createTestMovie()
        mockRepository.setFavorites([movie])
        mockRepository.addFavorite(movie)
        mockRepository.removeFavorite(movie)
        mockRepository.getFavorites()
        mockRepository.isFavorite(movie)

        // When
        mockRepository.reset()

        // Then
        XCTAssertTrue(mockRepository.getCurrentFavorites().isEmpty)
        XCTAssertEqual(mockRepository.addFavoriteCallCount, 0)
        XCTAssertEqual(mockRepository.removeFavoriteCallCount, 0)
        XCTAssertEqual(mockRepository.getFavoritesCallCount, 0)
        XCTAssertEqual(mockRepository.isFavoriteCallCount, 0)
        XCTAssertNil(mockRepository.lastAddedMovie)
        XCTAssertNil(mockRepository.lastRemovedMovie)
        XCTAssertNil(mockRepository.lastCheckedMovie)
        XCTAssertFalse(mockRepository.shouldThrowError)
    }

    func test_setFavorites() {
        // Given
        let movies = [createTestMovie(id: 1), createTestMovie(id: 2)]

        // When
        mockRepository.setFavorites(movies)

        // Then
        let currentFavorites = mockRepository.getCurrentFavorites()
        XCTAssertEqual(currentFavorites.count, 2)
        XCTAssertEqual(currentFavorites.first?.id, 1)
        XCTAssertEqual(currentFavorites.last?.id, 2)
    }

    private func createTestMovie(id: Int = 123) -> DiscoverMovieItem {
        return DiscoverMovieItem(
            adult: false,
            backdropPath: "/backdrop.jpg",
            genreIds: [28, 12],
            id: id,
            originalLanguage: "en",
            originalTitle: "Test Movie \(id)",
            overview: "A test movie",
            popularity: 100.0,
            posterPath: "/poster.jpg",
            releaseDate: "2023-01-01",
            title: "Test Movie \(id)",
            video: false,
            voteAverage: 8.5,
            voteCount: 1000
        )
    }
}
