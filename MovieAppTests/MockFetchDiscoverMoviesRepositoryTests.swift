//
//  MockFetchDiscoverMoviesRepositoryTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import XCTest
import Combine
@testable import MovieApp

final class MockFetchDiscoverMoviesRepositoryTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()
    private var mockRepository: MockFetchDiscoverMoviesRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockFetchDiscoverMoviesRepository()
    }

    override func tearDown() {
        cancellables.removeAll()
        mockRepository = nil
        super.tearDown()
    }

    func test_discoverMovies_success() {
        // Given
        let expectedMovie = DiscoverMovieItem(
            adult: false,
            backdropPath: "/backdrop.jpg",
            genreIds: [28, 12],
            id: 123,
            originalLanguage: "en",
            originalTitle: "Test Movie",
            overview: "A test movie",
            popularity: 100.0,
            posterPath: "/poster.jpg",
            releaseDate: "2023-01-01",
            title: "Test Movie",
            video: false,
            voteAverage: 8.5,
            voteCount: 1000
        )
        
        let response = DiscoverMoviesResponse(
            page: 1,
            results: [expectedMovie],
            totalPages: 1,
            totalResults: 1
        )

        mockRepository.result = .success(response)
        let expectation = self.expectation(description: "Should return discover movies data")

        // When
        mockRepository.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                XCTFail("Unexpected failure: \(error)")
            }
        }, receiveValue: { result in
            // Then
            XCTAssertEqual(result.results?.first?.id, expectedMovie.id)
            XCTAssertEqual(result.results?.first?.title, expectedMovie.title)
            expectation.fulfill()
        })
        .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_discoverMovies_failure() {
        // Given
        let expectedError = APIErrorHandler.tokenExpired
        mockRepository.result = .failure(expectedError)
        let expectation = self.expectation(description: "Should return an error")

        // When
        mockRepository.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                // Then
                XCTAssertEqual(error.errorDescription, expectedError.errorDescription)
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

    func test_discoverMovies_noResultSet() {
        // Given
        mockRepository.result = nil
        let expectation = self.expectation(description: "Should fail due to missing result")

        // When
        mockRepository.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                // Then
                XCTAssertEqual(error.errorDescription, APIErrorHandler.requestFailed.errorDescription)
                expectation.fulfill()
            } else {
                XCTFail("Expected failure due to missing mock result")
            }
        }, receiveValue: { _ in
            XCTFail("Expected no value when result is nil")
        })
        .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }
}
