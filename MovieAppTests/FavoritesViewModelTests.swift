//
//  FavoritesViewModelTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import XCTest
import Combine
@testable import MovieApp

class TestableFavoritesViewModel: ObservableObject {
    @Published var isFavorite: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let movie: DiscoverMovieItem
    private var cancellables = Set<AnyCancellable>()
    private let favoritesUseCase: FavoritesUseCaseProtocol
    
    init(movie: DiscoverMovieItem, favoritesUseCase: FavoritesUseCaseProtocol) {
        self.movie = movie
        self.favoritesUseCase = favoritesUseCase
        checkFavoriteStatus()
    }
    
    func toggleFavorite() {
        isLoading = true
        error = nil
        
        favoritesUseCase.toggleFavorite(movie)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] isFavorite in
                    self?.isFavorite = isFavorite
                }
            )
            .store(in: &cancellables)
    }
    
    private func checkFavoriteStatus() {
        favoritesUseCase.isFavorite(movie)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] isFavorite in
                    self?.isFavorite = isFavorite
                }
            )
            .store(in: &cancellables)
    }
}

final class FavoritesViewModelTests: XCTestCase {
    
    private var sut: TestableFavoritesViewModel!
    private var mockUseCase: MockFavoritesUseCase!
    private var mockRepository: MockFavoritesRepository!
    private var cancellables: Set<AnyCancellable>!
    private var testMovie: DiscoverMovieItem!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        testMovie = createSampleMovie()
        mockRepository = MockFavoritesRepository()
        mockUseCase = MockFavoritesUseCase(mockRepository: mockRepository)
        mockUseCase.reset()
        sut = TestableFavoritesViewModel(movie: testMovie, favoritesUseCase: mockUseCase)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase?.reset()
        mockUseCase = nil
        mockRepository?.reset()
        mockRepository = nil
        testMovie = nil
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

    func testInit_ChecksFavoriteStatus() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([testMovie])
        let expectation = XCTestExpectation(description: "Favorite status checked on init")
        
        // When
        sut = TestableFavoritesViewModel(movie: testMovie, favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.isFavorite)
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInit_MovieNotFavorite() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Movie not favorite on init")
        
        // When
        sut = TestableFavoritesViewModel(movie: testMovie, favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isFavorite)
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInit_HandlesError() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        
        let expectation = XCTestExpectation(description: "Error handled on init")
        
        // When
        sut = TestableFavoritesViewModel(movie: testMovie, favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isFavorite)
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNotNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_AddToFavorites() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        let expectation = XCTestExpectation(description: "Toggle favorite adds movie")
        
        // When
        sut.toggleFavorite()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.isFavorite)
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_RemoveFromFavorites() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([testMovie])
        let expectation = XCTestExpectation(description: "Toggle favorite removes movie")
        
        // When
        sut.toggleFavorite()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isFavorite)
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_Failure() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToSave
        
        let expectation = XCTestExpectation(description: "Toggle favorite fails")
        
        // When
        sut.toggleFavorite()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNotNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_SetsLoadingState() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        let expectation = XCTestExpectation(description: "Loading state is managed correctly")
        
        // When
        sut.toggleFavorite()
        
        // Then
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isLoading)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_ClearsError() {
        // Given
        sut.error = FavoritesError.failedToLoad
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Error is cleared on toggle")
        
        // When
        sut.toggleFavorite()
        
        // Then
        XCTAssertNil(sut.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCheckFavoriteStatus_ThroughInit() {
        // Given
        let movie1 = createSampleMovie()
        let movie2 = DiscoverMovieItem(
            adult: false,
            backdropPath: "/backdrop2.jpg",
            genreIds: [35, 18],
            id: 456,
            originalLanguage: "en",
            originalTitle: "Other Movie",
            overview: "Another movie",
            popularity: 7.2,
            posterPath: "/poster2.jpg",
            releaseDate: "2025-02-01",
            title: "Other Movie",
            video: false,
            voteAverage: 6.9,
            voteCount: 800
        )
        
        mockUseCase.reset()
        mockUseCase.shouldThrowError = false
        mockUseCase.setFavorites([movie1])
        
        let expectation1 = XCTestExpectation(description: "Movie1 is favorite")
        let expectation2 = XCTestExpectation(description: "Movie2 is not favorite")
        
        // When
        let viewModel1 = TestableFavoritesViewModel(movie: movie1, favoritesUseCase: mockUseCase)
        let viewModel2 = TestableFavoritesViewModel(movie: movie2, favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(viewModel1.isFavorite)
            XCTAssertFalse(viewModel2.isFavorite)
            expectation1.fulfill()
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
    
    // MARK: - State Management Tests
    
    func testInitialState() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Initial state is correct")
        
        // When
        sut = TestableFavoritesViewModel(movie: testMovie, favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isFavorite)
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNil(self.sut.error)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorState() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        
        let expectation = XCTestExpectation(description: "Error state is correct")
        
        // When
        sut = TestableFavoritesViewModel(movie: testMovie, favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isFavorite)
            XCTAssertFalse(self.sut.isLoading)
            XCTAssertNotNil(self.sut.error)
            XCTAssertTrue(self.sut.error is FavoritesError)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
 
    func testToggleFavoriteMultipleTimes() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation1 = XCTestExpectation(description: "First toggle")
        let expectation2 = XCTestExpectation(description: "Second toggle")
        sut.toggleFavorite()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.isFavorite)
            expectation1.fulfill()
            self.sut.toggleFavorite()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(self.sut.isFavorite)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }
    
    func testToggleFavoriteWithErrorThenSuccess() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToSave
        
        let expectation1 = XCTestExpectation(description: "Toggle fails")
        let expectation2 = XCTestExpectation(description: "Toggle succeeds")

        sut.toggleFavorite()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(self.sut.error)
            expectation1.fulfill()
            self.mockUseCase.reset()
            self.mockUseCase.shouldThrowError = false
            self.mockUseCase.setFavorites([])
            
            self.sut.toggleFavorite()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertNil(self.sut.error)
                XCTAssertTrue(self.sut.isFavorite)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }
    
    func testDifferentMovies() {
        // Given
        let movie1 = createSampleMovie()
        let movie2 = DiscoverMovieItem(
            adult: false,
            backdropPath: "/backdrop2.jpg",
            genreIds: [35, 18],
            id: 456,
            originalLanguage: "en",
            originalTitle: "Other Movie",
            overview: "Another movie",
            popularity: 7.2,
            posterPath: "/poster2.jpg",
            releaseDate: "2025-02-01",
            title: "Other Movie",
            video: false,
            voteAverage: 6.9,
            voteCount: 800
        )
        
        mockUseCase.reset()
        mockUseCase.shouldThrowError = false
        mockUseCase.setFavorites([movie1]) 
        
        let expectation1 = XCTestExpectation(description: "Movie1 viewmodel")
        let expectation2 = XCTestExpectation(description: "Movie2 viewmodel")
        
        // When
        let viewModel1 = TestableFavoritesViewModel(movie: movie1, favoritesUseCase: mockUseCase)
        let viewModel2 = TestableFavoritesViewModel(movie: movie2, favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(viewModel1.isFavorite)
            XCTAssertFalse(viewModel2.isFavorite)
            expectation1.fulfill()
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
}
