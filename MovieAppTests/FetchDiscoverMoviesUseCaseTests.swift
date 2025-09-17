//
//  FetchDiscoverMoviesUseCaseTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import XCTest
import Combine
@testable import MovieApp

class TestableFetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCaseProtocol {
    private let repository: FetchDiscoverMoviesRepositoryProtocol
    
    init(repository: FetchDiscoverMoviesRepositoryProtocol) {
        self.repository = repository
    }
    
    func discoverMovies(
        includeAdult: Bool,
        includeVideo: Bool,
        language: String,
        page: Int,
        sortBy: String
    ) -> AnyPublisher<DiscoverMoviesResponse, APIErrorHandler> {
        repository.discoverMovies(
            includeAdult: includeAdult,
            includeVideo: includeVideo,
            language: language,
            page: page,
            sortBy: sortBy
        )
    }
}

final class FetchDiscoverMoviesUseCaseTests: XCTestCase {
    
    private var sut: TestableFetchDiscoverMoviesUseCase!
    private var mockRepository: MockFetchDiscoverMoviesRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockRepository = MockFetchDiscoverMoviesRepository()

        mockRepository.reset()
      
        sut = TestableFetchDiscoverMoviesUseCase(repository: mockRepository)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository?.reset()
        mockRepository = nil
        super.tearDown()
    }

    private func createSampleMovieResponse() -> DiscoverMoviesResponse {
        let movie = DiscoverMovieItem(
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
        
        return DiscoverMoviesResponse(
            page: 1,
            results: [movie],
            totalPages: 10,
            totalResults: 200
        )
    }
    
    private func createEmptyMovieResponse() -> DiscoverMoviesResponse {
        return DiscoverMoviesResponse(
            page: 1,
            results: [],
            totalPages: 0,
            totalResults: 0
        )
    }
    
    func testDiscoverMovies_Success() {
        // Given
        let expectedResponse = createSampleMovieResponse()
        mockRepository.reset()
        mockRepository.result = .success(expectedResponse)
        
        let expectation = XCTestExpectation(description: "Discover movies succeeds")
        
        // When
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { response in
                XCTAssertEqual(response.page, expectedResponse.page)
                XCTAssertEqual(response.results?.count, expectedResponse.results?.count)
                XCTAssertEqual(response.totalPages, expectedResponse.totalPages)
                XCTAssertEqual(response.totalResults, expectedResponse.totalResults)
                XCTAssertEqual(response.results?.first?.id, expectedResponse.results?.first?.id)
            }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_EmptyResults() {
        // Given
        let expectedResponse = createEmptyMovieResponse()
        mockRepository.reset()
        mockRepository.result = .success(expectedResponse)
        
        let expectation = XCTestExpectation(description: "Discover movies returns empty results")
        
        // When
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { response in
                XCTAssertEqual(response.page, 1)
                XCTAssertTrue(response.results?.isEmpty ?? true)
                XCTAssertEqual(response.totalPages, 0)
                XCTAssertEqual(response.totalResults, 0)
            }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_NetworkError() {
        // Given
        mockRepository.reset()
        mockRepository.result = .failure(APIErrorHandler.noInternetConnection)
        
        let expectation = XCTestExpectation(description: "Discover movies fails with network error")
        
        // When
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if case .noInternetConnection = error {
                        expectation.fulfill()
                    }
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_RequestFailed() {
        // Given
        mockRepository.reset()
        mockRepository.result = .failure(APIErrorHandler.requestFailed)
        
        let expectation = XCTestExpectation(description: "Discover movies fails with request failed")
        
        // When
        sut.discoverMovies(
            includeAdult: true,
            includeVideo: true,
            language: "es-ES",
            page: 2,
            sortBy: "release_date.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if case .requestFailed = error {
                        expectation.fulfill()
                    }
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_NoData() {
        // Given
        mockRepository.reset()
        mockRepository.result = .failure(APIErrorHandler.noData)
        
        let expectation = XCTestExpectation(description: "Discover movies fails with no data")
        
        // When
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "fr-FR",
            page: 5,
            sortBy: "vote_average.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if case .noData = error {
                        expectation.fulfill()
                    }
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_CustomApiError() {
        // Given
        let customError = ApiError(
            code: "400",
            message: "Bad Request",
            errorItems: ["field": "Invalid parameter"]
        )
        mockRepository.reset()
        mockRepository.result = .failure(APIErrorHandler.customApiError(customError))
        
        let expectation = XCTestExpectation(description: "Discover movies fails with custom API error")
        
        // When
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if case .customApiError(let apiError) = error {
                        XCTAssertEqual(apiError.code, "400")
                        XCTAssertEqual(apiError.message, "Bad Request")
                        expectation.fulfill()
                    }
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_OfflineMode() {
        // Given
        mockRepository.reset()
        mockRepository.result = .failure(APIErrorHandler.offlineMode)
        
        let expectation = XCTestExpectation(description: "Discover movies fails in offline mode")
        
        // When
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if case .offlineMode = error {
                        expectation.fulfill()
                    }
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_ParameterVariations() {
        // Given
        let expectedResponse = createSampleMovieResponse()
        mockRepository.reset()
        mockRepository.result = .success(expectedResponse)
        
        let expectation = XCTestExpectation(description: "Discover movies with different parameters")
        sut.discoverMovies(
            includeAdult: true,
            includeVideo: true,
            language: "ja-JP",
            page: 10,
            sortBy: "vote_count.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            },
            receiveValue: { response in
                XCTAssertNotNil(response)
            }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDiscoverMovies_MultiplePages() {
        // Given
        let page1Response = DiscoverMoviesResponse(page: 1, results: [createSampleMovieResponse().results!.first!], totalPages: 3, totalResults: 30)
        let page2Response = DiscoverMoviesResponse(page: 2, results: [createSampleMovieResponse().results!.first!], totalPages: 3, totalResults: 30)
        
        let expectation1 = XCTestExpectation(description: "Fetch page 1")
        let expectation2 = XCTestExpectation(description: "Fetch page 2")

        mockRepository.reset()
        mockRepository.result = .success(page1Response)
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 1,
            sortBy: "popularity.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation1.fulfill()
                }
            },
            receiveValue: { response in
                XCTAssertEqual(response.page, 1)
            }
        )
        .store(in: &cancellables)
        
        mockRepository.result = .success(page2Response)
        sut.discoverMovies(
            includeAdult: false,
            includeVideo: false,
            language: "en-US",
            page: 2,
            sortBy: "popularity.desc"
        )
        .sink(
            receiveCompletion: { completion in
                if case .finished = completion {
                    expectation2.fulfill()
                }
            },
            receiveValue: { response in
                XCTAssertEqual(response.page, 2)
            }
        )
        .store(in: &cancellables)
        
        // Then
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
}
