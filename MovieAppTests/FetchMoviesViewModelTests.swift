//
//  FetchMoviesViewModelTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-16.
//

import XCTest
import Combine
@testable import MovieApp

class MockReachabilityUseCase: ReachabilityUseCaseProtocol {
    var isConnected: Bool = true
    var connectionType: ConnectionType = .wifi
    var isConnectedPublisher: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> = Just(.wifi).eraseToAnyPublisher()
    var reconnectedPublisher: AnyPublisher<Void, Never> = Just(()).eraseToAnyPublisher()
    var isConnectedResponse: Bool = true
    var isConnectedPublisherResponse: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
    var shouldSimulateDisconnection: Bool = false
    
    func execute() -> Bool {
        return isConnected
    }
    
    func startMonitoring() {

    }
    
    func stopMonitoring() {

    }
    
    func reset() {
        isConnected = true
        connectionType = .wifi
        shouldSimulateDisconnection = false
        isConnectedResponse = true
        isConnectedPublisher = Just(true).eraseToAnyPublisher()
        isConnectedPublisherResponse = Just(true).eraseToAnyPublisher()
        connectionTypePublisher = Just(.wifi).eraseToAnyPublisher()
        reconnectedPublisher = Just(()).eraseToAnyPublisher()
    }
}

class MockFetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCaseProtocol {
    private let mockRepository: MockFetchDiscoverMoviesRepository
    var shouldThrowError: Bool = false
    var errorToThrow: Error = APIErrorHandler.noInternetConnection
    
    init(mockRepository: MockFetchDiscoverMoviesRepository) {
        self.mockRepository = mockRepository
    }
    
    func discoverMovies(
        includeAdult: Bool,
        includeVideo: Bool,
        language: String,
        page: Int,
        sortBy: String
    ) -> AnyPublisher<DiscoverMoviesResponse, APIErrorHandler> {
        if shouldThrowError {
            return Fail(error: errorToThrow as! APIErrorHandler)
                .eraseToAnyPublisher()
        }
        return mockRepository.discoverMovies(
            includeAdult: includeAdult,
            includeVideo: includeVideo,
            language: language,
            page: page,
            sortBy: sortBy
        )
    }
    
    func reset() {
        shouldThrowError = false
        errorToThrow = APIErrorHandler.noInternetConnection
        mockRepository.reset()
    }
}

class MockOfflineMoviesUseCase: OfflineMoviesUseCaseProtocol {
    private let mockRepository: MockOfflineMoviesRepository
    var shouldThrowError: Bool = false
    var shouldSucceed: Bool = true
    var errorToThrow: Error = OfflineError.noCachedData
    var hasCachedMoviesResponse: Bool = false
    var savedMovies: [DiscoverMovieItem] = []
    
    init(mockRepository: MockOfflineMoviesRepository) {
        self.mockRepository = mockRepository
    }
    
    func saveMovies(_ movies: [DiscoverMovieItem], page: Int) -> AnyPublisher<Void, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        savedMovies.append(contentsOf: movies)
        return mockRepository.saveMovies(movies, page: page)
    }
    
    func getCachedMovies() -> AnyPublisher<[DiscoverMovieItem], Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return mockRepository.getCachedMovies()
    }
    
    func getCachedMoviesForPage(_ page: Int) -> AnyPublisher<[DiscoverMovieItem], Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return mockRepository.getCachedMoviesForPage(page)
    }
    
    func clearOldCache(olderThan days: Int) -> AnyPublisher<Void, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return mockRepository.clearOldCache(olderThan: days)
    }
    
    func hasCachedMovies() -> AnyPublisher<Bool, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return Just(hasCachedMoviesResponse)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func reset() {
        shouldThrowError = false
        shouldSucceed = true
        errorToThrow = OfflineError.noCachedData
        hasCachedMoviesResponse = false
        savedMovies = []
        mockRepository.reset()
    }
}

class TestableFetchMoviesViewModel: ObservableObject {
    @Published var moviesResponse: DiscoverMoviesResponse?
    @Published var error: APIErrorHandler?
    @Published var searchText: String = ""
    @Published var filteredMovies: [DiscoverMovieItem] = []
    @Published var isLoadingMore: Bool = false
    @Published var hasMorePages: Bool = true
    @Published var isOffline: Bool = false
    @Published var isRefreshingOnReconnect: Bool = false
    @Published var showReconnectionToast: Bool = false
    @Published var connectionStatus: OfflineIndicator.ConnectionStatus = .connected
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var isOfflineMode: Bool = false
    @Published var hasCachedData: Bool = false
    
    var allMovies: [DiscoverMovieItem] = [] // Made internal for testing
    private var cancellables = Set<AnyCancellable>()
    private var cachedMovieIds: Set<Int> = []
    private var lastAppUsageTime: Date = Date()
    
    private let fetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCaseProtocol
    private let reachabilityUseCase: ReachabilityUseCaseProtocol
    private let offlineMoviesUseCase: OfflineMoviesUseCaseProtocol
    
    init(
        fetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCaseProtocol,
        reachabilityUseCase: ReachabilityUseCaseProtocol,
        offlineMoviesUseCase: OfflineMoviesUseCaseProtocol
    ) {
        self.fetchDiscoverMoviesUseCase = fetchDiscoverMoviesUseCase
        self.reachabilityUseCase = reachabilityUseCase
        self.offlineMoviesUseCase = offlineMoviesUseCase
        
        setupSearchSubscription()
        setupConnectivityMonitoring()
        checkForCachedData()
    }
    
    func getMovies(
        includeAdult: Bool = false,
        includeVideo: Bool = false,
        language: String = "en-US",
        page: Int = 1,
        sortBy: String = "popularity.desc"
    ) {
        if page == 1 {
            currentPage = 1
            allMovies = []
            hasMorePages = true
        }
        
        fetchDiscoverMoviesUseCase
            .discoverMovies(
                includeAdult: includeAdult,
                includeVideo: includeVideo,
                language: language,
                page: page,
                sortBy: sortBy
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                
                if case let .failure(err) = completion {
                    self.error = err
                    self.isLoadingMore = false
                    self.isRefreshingOnReconnect = false
                    
                    if case .noInternetConnection = err {
                        self.isOffline = true
                        self.connectionStatus = .disconnected
                        self.showReconnectionToast = true
                    }
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                self.isOffline = false
                self.isOfflineMode = false
                self.error = nil
                self.moviesResponse = response
                self.handleMoviesResponse(response)
                self.isLoadingMore = false
            }
            .store(in: &cancellables)
    }
    
    private func setupSearchSubscription() {
        $searchText
            .sink { [weak self] searchText in
                self?.filterMovies(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func filterMovies(searchText: String = "") {
        let searchQuery = searchText.isEmpty ? self.searchText : searchText
        
        guard !searchQuery.isEmpty else {
            filteredMovies = allMovies
            return
        }
        filteredMovies = allMovies.filter { movie in
            guard let title = movie.title else { return false }
            let normalizedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedTitle = title.lowercased()
            return normalizedTitle.hasPrefix(normalizedQuery)
        }
    }
    
    private func setupConnectivityMonitoring() {
        reachabilityUseCase.isConnectedPublisher
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self else { return }
                let wasOffline = self.isOffline
                
                if isConnected {
                    if wasOffline {
                        self.connectionStatus = .reconnecting
                        self.showReconnectionToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.refreshDataOnReconnection()
                        }
                    } else {
                        self.connectionStatus = .connected
                    }
                } else {
                    self.connectionStatus = .disconnected
                    self.showReconnectionToast = true
                    if self.hasCachedData {
                        self.loadCachedMovies()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshDataOnReconnection() {
        isOffline = false
        isRefreshingOnReconnect = true
        connectionStatus = .reconnecting
        error = nil
        getMovies(page: currentPage + 1)
    }
    
    func loadMoreMovies() {
        guard canLoadMore else {
            return
        }
        isLoadingMore = true
        currentPage += 1
        getMovies(page: currentPage)
    }
    
    func refreshMovies() {
        currentPage = 1
        allMovies = []
        hasMorePages = true
        getMovies(page: 1)
    }
    
    func retryAfterError() {
        error = nil
        isOffline = false
        getMovies(page: currentPage)
    }
    
    func performSearch() {
        filterMovies()
    }
    
    func clearSearch() {
        searchText = ""
        filteredMovies = allMovies
    }
    
    func searchMovies(with query: String) {
        searchText = query
        filterMovies()
    }
    
    var canLoadMore: Bool {
        let isNetworkAvailable = reachabilityUseCase.execute()
        let canLoad = !isLoadingMore && hasMorePages && searchText.isEmpty && !isOffline && isNetworkAvailable
        return canLoad
    }
    
    private func handleMoviesResponse(_ response: DiscoverMoviesResponse) {
        totalPages = response.totalPages ?? 1
        let newMovies = response.results ?? []
        allMovies.append(contentsOf: newMovies)
        if searchText.isEmpty {
            filteredMovies = allMovies
        } else {
            filterMovies()
        }
    }
    
    private func checkForCachedData() {
        offlineMoviesUseCase.hasCachedMovies()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to check cached data: \(error)")
                }
            } receiveValue: { [weak self] hasCached in
                self?.hasCachedData = hasCached
                if hasCached && self?.reachabilityUseCase.execute() == false {
                    self?.loadCachedMovies()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadCachedMovies() {
        isOfflineMode = true
        offlineMoviesUseCase.getCachedMovies()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isOfflineMode = false
                }
            } receiveValue: { [weak self] movies in
                guard let self else { return }
                self.allMovies = movies
                self.isOfflineMode = true
                
                if self.searchText.isEmpty {
                    self.filteredMovies = movies
                } else {
                    self.filterMovies()
                }
            }
            .store(in: &cancellables)
    }
}

final class FetchMoviesViewModelTests: XCTestCase {
    
    private var sut: TestableFetchMoviesViewModel!
    private var mockFetchUseCase: MockFetchDiscoverMoviesUseCase!
    private var mockReachabilityUseCase: MockReachabilityUseCase!
    private var mockOfflineUseCase: MockOfflineMoviesUseCase!
    private var cancellables: Set<AnyCancellable>!
    private var mockFetchRepository: MockFetchDiscoverMoviesRepository!
    private var mockOfflineRepository: MockOfflineMoviesRepository!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockFetchRepository = MockFetchDiscoverMoviesRepository()
        mockOfflineRepository = MockOfflineMoviesRepository()
        mockFetchUseCase = MockFetchDiscoverMoviesUseCase(mockRepository: mockFetchRepository)
        mockReachabilityUseCase = MockReachabilityUseCase()
        mockOfflineUseCase = MockOfflineMoviesUseCase(mockRepository: mockOfflineRepository)
        mockFetchUseCase.reset()
        mockOfflineUseCase.reset()
        
        sut = TestableFetchMoviesViewModel(
            fetchDiscoverMoviesUseCase: mockFetchUseCase,
            reachabilityUseCase: mockReachabilityUseCase,
            offlineMoviesUseCase: mockOfflineUseCase
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockFetchUseCase?.reset()
        mockFetchUseCase = nil
        mockReachabilityUseCase = nil
        mockOfflineUseCase?.reset()
        mockOfflineUseCase = nil
        mockFetchRepository = nil
        mockOfflineRepository = nil
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
    
    func testInit_SetsUpCorrectly() {
        // Then
        XCTAssertNil(sut.moviesResponse)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.searchText, "")
        XCTAssertTrue(sut.filteredMovies.isEmpty)
        XCTAssertFalse(sut.isLoadingMore)
        XCTAssertTrue(sut.hasMorePages)
        XCTAssertFalse(sut.isOffline)
        XCTAssertFalse(sut.isRefreshingOnReconnect)
        XCTAssertFalse(sut.showReconnectionToast)
        XCTAssertEqual(sut.connectionStatus, .connected)
        XCTAssertEqual(sut.currentPage, 1)
        XCTAssertEqual(sut.totalPages, 1)
        XCTAssertFalse(sut.isOfflineMode)
        XCTAssertFalse(sut.hasCachedData)
    }

    func testGetMovies_Success() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Get movies succeeds")
        
        // When
        sut.getMovies()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.moviesResponse?.page, response.page)
            XCTAssertEqual(self.sut.moviesResponse?.results?.count, response.results?.count)
            XCTAssertEqual(self.sut.totalPages, response.totalPages)
            XCTAssertNil(self.sut.error)
            XCTAssertFalse(self.sut.isOffline)
            XCTAssertFalse(self.sut.isOfflineMode)
            XCTAssertFalse(self.sut.isLoadingMore)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetMovies_EmptyResults() {
        // Given
        let response = createEmptyMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Get movies returns empty results")
        
        // When
        sut.getMovies()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.moviesResponse?.page, 1)
            XCTAssertTrue(self.sut.moviesResponse?.results?.isEmpty ?? true)
            XCTAssertEqual(self.sut.totalPages, 0)
            XCTAssertTrue(self.sut.filteredMovies.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetMovies_NetworkError() {
        // Given
        mockFetchUseCase.reset()
        mockFetchRepository.result = .failure(APIErrorHandler.noInternetConnection)
        
        let expectation = XCTestExpectation(description: "Get movies fails with network error")
        
        // When
        sut.getMovies()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(self.sut.error)
            XCTAssertTrue(self.sut.isOffline)
            XCTAssertEqual(self.sut.connectionStatus, .disconnected)
            XCTAssertTrue(self.sut.showReconnectionToast)
            XCTAssertFalse(self.sut.isLoadingMore)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetMovies_RequestFailed() {
        // Given
        mockFetchUseCase.reset()
        mockFetchRepository.result = .failure(APIErrorHandler.requestFailed)
        
        let expectation = XCTestExpectation(description: "Get movies fails with request failed")
        
        // When
        sut.getMovies()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(self.sut.error)
            XCTAssertFalse(self.sut.isOffline)
            XCTAssertFalse(self.sut.isLoadingMore)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetMovies_WithParameters() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Get movies with parameters")
        
        // When
        sut.getMovies(
            includeAdult: true,
            includeVideo: true,
            language: "es-ES",
            page: 2,
            sortBy: "release_date.desc"
        )
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(self.sut.moviesResponse)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchMovies_WithQuery() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Search movies with query")
        
        // When
        sut.getMovies()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sut.searchMovies(with: "Sample")
            
            // Then
            XCTAssertEqual(self.sut.searchText, "Sample")
            XCTAssertFalse(self.sut.filteredMovies.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchMovies_EmptyQuery() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Search movies with empty query")
        
        // When
        sut.getMovies()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sut.searchMovies(with: "")
            
            // Then
            XCTAssertEqual(self.sut.searchText, "")
            XCTAssertEqual(self.sut.filteredMovies.count, self.sut.allMovies.count)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testClearSearch() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Clear search")
        
        // When
        sut.getMovies()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sut.searchMovies(with: "Sample")
            self.sut.clearSearch()
            
            // Then
            XCTAssertEqual(self.sut.searchText, "")
            XCTAssertEqual(self.sut.filteredMovies.count, self.sut.allMovies.count)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testPerformSearch() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Perform search")
        
        // When
        sut.getMovies()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sut.searchText = "Sample"
            self.sut.performSearch()
            
            // Then
            XCTAssertFalse(self.sut.filteredMovies.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testLoadMoreMovies_Success() {
        // Given
        let response1 = createSampleMovieResponse()
        let response2 = DiscoverMoviesResponse(
            page: 2,
            results: [DiscoverMovieItem(
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
            )],
            totalPages: 10,
            totalResults: 200
        )
        
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response1)
        
        let expectation1 = XCTestExpectation(description: "Load first page")
        let expectation2 = XCTestExpectation(description: "Load more movies")
        
        // When
        sut.getMovies()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.currentPage, 1)
            expectation1.fulfill()
            self.mockFetchRepository.result = .success(response2)
            self.sut.loadMoreMovies()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertEqual(self.sut.currentPage, 2)
                XCTAssertFalse(self.sut.isLoadingMore)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }
    
    func testLoadMoreMovies_WhenCannotLoadMore() {
        // Given
        sut.hasMorePages = false
        sut.isLoadingMore = true
        sut.searchText = "test"
        
        // When
        sut.loadMoreMovies()
        
        // Then
        XCTAssertTrue(sut.isLoadingMore)
    }
    
    func testRefreshMovies() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response)
        
        let expectation = XCTestExpectation(description: "Refresh movies")
        
        // When
        sut.currentPage = 5
        sut.allMovies = [createSampleMovieResponse().results!.first!]
        sut.refreshMovies()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.currentPage, 1)
            XCTAssertTrue(self.sut.allMovies.isEmpty)
            XCTAssertTrue(self.sut.hasMorePages)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testRetryAfterError() {
        // Given
        let response = createSampleMovieResponse()
        mockFetchUseCase.reset()
        mockFetchRepository.result = .failure(APIErrorHandler.requestFailed)
        
        let expectation1 = XCTestExpectation(description: "Initial error")
        let expectation2 = XCTestExpectation(description: "Retry after error")
        
        // When
        sut.getMovies()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(self.sut.error)
            expectation1.fulfill()
            
            // Retry
            self.mockFetchRepository.result = .success(response)
            self.sut.retryAfterError()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertNil(self.sut.error)
                XCTAssertFalse(self.sut.isOffline)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 2.0)
    }
    
    func testConnectivityMonitoring_Connected() {
        // Given
        mockReachabilityUseCase.isConnectedResponse = true
        mockReachabilityUseCase.isConnectedPublisherResponse = Just(true).eraseToAnyPublisher()
        
        let expectation = XCTestExpectation(description: "Connectivity monitoring - connected")
        
        // When
        sut.isOffline = true
        sut.connectionStatus = .disconnected
        mockReachabilityUseCase.isConnectedPublisherResponse = Just(true).eraseToAnyPublisher()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.sut.connectionStatus, .connected)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectivityMonitoring_Disconnected() {
        // Given
        mockReachabilityUseCase.isConnectedResponse = false
        mockReachabilityUseCase.isConnectedPublisherResponse = Just(false).eraseToAnyPublisher()
        
        let expectation = XCTestExpectation(description: "Connectivity monitoring - disconnected")
        
        // When
        sut.isOffline = false
        sut.connectionStatus = .connected
        mockReachabilityUseCase.isConnectedPublisherResponse = Just(false).eraseToAnyPublisher()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.sut.connectionStatus, .disconnected)
            XCTAssertTrue(self.sut.showReconnectionToast)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testCheckForCachedData_HasCachedData() {
        // Given
        mockOfflineUseCase.reset()
        mockOfflineUseCase.shouldSucceed = true
        mockOfflineUseCase.hasCachedMoviesResponse = true
        
        let expectation = XCTestExpectation(description: "Check for cached data - has cached data")
        
        // When
        sut = TestableFetchMoviesViewModel(
            fetchDiscoverMoviesUseCase: mockFetchUseCase,
            reachabilityUseCase: mockReachabilityUseCase,
            offlineMoviesUseCase: mockOfflineUseCase
        )
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.hasCachedData)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCheckForCachedData_NoCachedData() {
        // Given
        mockOfflineUseCase.reset()
        mockOfflineUseCase.shouldSucceed = true
        mockOfflineUseCase.hasCachedMoviesResponse = false
        
        let expectation = XCTestExpectation(description: "Check for cached data - no cached data")
        
        // When
        sut = TestableFetchMoviesViewModel(
            fetchDiscoverMoviesUseCase: mockFetchUseCase,
            reachabilityUseCase: mockReachabilityUseCase,
            offlineMoviesUseCase: mockOfflineUseCase
        )
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.hasCachedData)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadCachedMovies_Success() {
        // Given
        let cachedMovies = [createSampleMovieResponse().results!.first!]
        mockOfflineUseCase.reset()
        mockOfflineUseCase.shouldSucceed = true
        mockOfflineUseCase.savedMovies = cachedMovies
        
        let expectation = XCTestExpectation(description: "Load cached movies succeeds")
        
        // When
        sut.loadCachedMovies()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.sut.isOfflineMode)
            XCTAssertEqual(self.sut.allMovies.count, cachedMovies.count)
            XCTAssertEqual(self.sut.filteredMovies.count, cachedMovies.count)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadCachedMovies_Failure() {
        // Given
        mockOfflineUseCase.reset()
        mockOfflineUseCase.shouldSucceed = false
        mockOfflineUseCase.errorToThrow = OfflineError.noCachedData
        
        let expectation = XCTestExpectation(description: "Load cached movies fails")
        
        // When
        sut.loadCachedMovies()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isOfflineMode)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func testCanLoadMore_True() {
        // Given
        sut.isLoadingMore = false
        sut.hasMorePages = true
        sut.searchText = ""
        sut.isOffline = false
        mockReachabilityUseCase.isConnectedResponse = true
        
        // When
        let result = sut.canLoadMore
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testCanLoadMore_False_LoadingMore() {
        // Given
        sut.isLoadingMore = true
        sut.hasMorePages = true
        sut.searchText = ""
        sut.isOffline = false
        mockReachabilityUseCase.isConnectedResponse = true
        
        // When
        let result = sut.canLoadMore
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testCanLoadMore_False_NoMorePages() {
        // Given
        sut.isLoadingMore = false
        sut.hasMorePages = false
        sut.searchText = ""
        sut.isOffline = false
        mockReachabilityUseCase.isConnectedResponse = true
        
        // When
        let result = sut.canLoadMore
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testCanLoadMore_False_HasSearchText() {
        // Given
        sut.isLoadingMore = false
        sut.hasMorePages = true
        sut.searchText = "test"
        sut.isOffline = false
        mockReachabilityUseCase.isConnectedResponse = true
        
        // When
        let result = sut.canLoadMore
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testCanLoadMore_False_Offline() {
        // Given
        sut.isLoadingMore = false
        sut.hasMorePages = true
        sut.searchText = ""
        sut.isOffline = true
        mockReachabilityUseCase.isConnectedResponse = true
        
        // When
        let result = sut.canLoadMore
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testCanLoadMore_False_NoNetwork() {
        // Given
        sut.isLoadingMore = false
        sut.hasMorePages = true
        sut.searchText = ""
        sut.isOffline = false
        mockReachabilityUseCase.isConnectedResponse = false
        
        // When
        let result = sut.canLoadMore
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testCompleteWorkflow_SearchAndPagination() {
        // Given
        let response1 = createSampleMovieResponse()
        let response2 = DiscoverMoviesResponse(
            page: 2,
            results: [DiscoverMovieItem(
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
            )],
            totalPages: 10,
            totalResults: 200
        )
        
        mockFetchUseCase.reset()
        mockFetchRepository.result = .success(response1)
        
        let expectation1 = XCTestExpectation(description: "Load first page")
        let expectation2 = XCTestExpectation(description: "Search movies")
        let expectation3 = XCTestExpectation(description: "Load more movies")
        
        // When
        sut.getMovies() 
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.filteredMovies.count, 1)
            expectation1.fulfill()
            
            // Search
            self.sut.searchMovies(with: "Sample")
            XCTAssertEqual(self.sut.searchText, "Sample")
            expectation2.fulfill()
            
            // Load more
            self.mockFetchRepository.result = .success(response2)
            self.sut.loadMoreMovies()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertEqual(self.sut.currentPage, 2)
                expectation3.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 3.0)
    }
}
