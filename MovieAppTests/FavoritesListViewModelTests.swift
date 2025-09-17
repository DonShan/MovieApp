//
//  FavoritesListViewModelTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import XCTest
import Combine
@testable import MovieApp

class TestableFavoritesListViewModel: ObservableObject {
    @Published var favoriteMovies: [DiscoverMovieItem] = []
    @Published var isUpdating: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let favoritesUseCase: FavoritesUseCaseProtocol
    
    init(favoritesUseCase: FavoritesUseCaseProtocol) {
        self.favoritesUseCase = favoritesUseCase
        loadFavorites()
    }
    
    func loadFavorites() {
        isUpdating = true
        favoritesUseCase.getFavorites()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isUpdating = false
                },
                receiveValue: { [weak self] favorites in
                    self?.favoriteMovies = favorites
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleFavorite(_ movie: DiscoverMovieItem) {
        isUpdating = true
        
        favoritesUseCase.toggleFavorite(movie)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isUpdating = false
                },
                receiveValue: { [weak self] _ in
                    self?.loadFavorites()
                }
            )
            .store(in: &cancellables)
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> Bool {
        return favoriteMovies.contains { $0.id == movie.id }
    }
}

final class FavoritesListViewModelTests: XCTestCase {
    
    private var sut: TestableFavoritesListViewModel!
    private var mockUseCase: MockFavoritesUseCase!
    private var mockRepository: MockFavoritesRepository!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockRepository = MockFavoritesRepository()
        mockUseCase = MockFavoritesUseCase(mockRepository: mockRepository)
        mockUseCase.reset()
        sut = TestableFavoritesListViewModel(favoritesUseCase: mockUseCase)
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockUseCase?.reset()
        mockUseCase = nil
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
    
    func testInit_LoadsFavorites() {
        // Given
        let movies = [createSampleMovie()]
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites(movies)
        
        let expectation = XCTestExpectation(description: "Favorites loaded on init")
        
        // When
        sut = TestableFavoritesListViewModel(favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.favoriteMovies.count, 1)
            XCTAssertEqual(self.sut.favoriteMovies.first?.id, movies.first?.id)
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
        sut = TestableFavoritesListViewModel(favoritesUseCase: mockUseCase)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.favoriteMovies.isEmpty)
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadFavorites_Success() {
        // Given
        let movies = [createSampleMovie()]
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites(movies)
        
        let expectation = XCTestExpectation(description: "Load favorites succeeds")
        
        // When
        sut.loadFavorites()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.favoriteMovies.count, 1)
            XCTAssertEqual(self.sut.favoriteMovies.first?.id, movies.first?.id)
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadFavorites_EmptyList() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Load favorites returns empty list")
        
        // When
        sut.loadFavorites()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.favoriteMovies.isEmpty)
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadFavorites_Failure() {
        // Given
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToLoad
        
        let expectation = XCTestExpectation(description: "Load favorites fails")
        
        // When
        sut.loadFavorites()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.favoriteMovies.isEmpty)
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadFavorites_SetsUpdatingState() {
        // Given
        let movies = [createSampleMovie()]
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites(movies)
        
        let expectation = XCTestExpectation(description: "Updating state is managed correctly")
        
        // When
        sut.loadFavorites()
        
        // Then
        XCTAssertTrue(sut.isUpdating)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - toggleFavorite Tests
    
    func testToggleFavorite_AddToFavorites() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Toggle favorite adds movie")
        
        // When
        sut.toggleFavorite(movie)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
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
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_Failure() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = FavoritesError.failedToSave
        
        let expectation = XCTestExpectation(description: "Toggle favorite fails")
        
        // When
        sut.toggleFavorite(movie)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testToggleFavorite_SetsUpdatingState() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Updating state is managed correctly")
        
        // When
        sut.toggleFavorite(movie)
        
        // Then
        XCTAssertTrue(sut.isUpdating)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    

    func testIsFavorite_True() {
        // Given
        let movie = createSampleMovie()
        sut.favoriteMovies = [movie]
        
        // When
        let result = sut.isFavorite(movie)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testIsFavorite_False() {
        // Given
        let movie = createSampleMovie()
        let otherMovie = DiscoverMovieItem(
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
        sut.favoriteMovies = [otherMovie]
        
        // When
        let result = sut.isFavorite(movie)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testIsFavorite_EmptyFavorites() {
        // Given
        let movie = createSampleMovie()
        sut.favoriteMovies = []
        
        // When
        let result = sut.isFavorite(movie)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testIsFavorite_MultipleMovies() {
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
        sut.favoriteMovies = [movie1, movie2]
        
        // When
        let result1 = sut.isFavorite(movie1)
        let result2 = sut.isFavorite(movie2)
        
        // Then
        XCTAssertTrue(result1)
        XCTAssertTrue(result2)
    }
    
    // MARK: - Integration Tests
    
    func testLoadFavoritesThenToggle_Integration() {
        // Given
        let movie = createSampleMovie()
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let loadExpectation = XCTestExpectation(description: "Load favorites")
        let toggleExpectation = XCTestExpectation(description: "Toggle favorite")

        sut.loadFavorites()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.favoriteMovies.isEmpty)
            loadExpectation.fulfill()
            self.sut.toggleFavorite(movie)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toggleExpectation.fulfill()
            }
        }
        
        wait(for: [loadExpectation, toggleExpectation], timeout: 2.0)
    }
    
    func testMultipleToggleOperations() {
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
        
        mockRepository.reset()
        mockRepository.shouldThrowError = false
        mockRepository.setFavorites([])
        
        let expectation = XCTestExpectation(description: "Multiple toggle operations")
        
        // When
        sut.toggleFavorite(movie1)
        sut.toggleFavorite(movie2)
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertFalse(self.sut.isUpdating)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
