//
//  FetchMoviesViewModel.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine
import UIKit

public class FetchMoviesViewModel: ObservableObject {
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
    
    private var allMovies: [DiscoverMovieItem] = []
    private var cancellables = Set<AnyCancellable>()
    private var cachedMovieIds: Set<Int> = []
    private var lastAppUsageTime: Date = Date()

    private var lastOfflinePage: Int?

    private var reconnectionTimer: Timer?
    private var reconnectionAttempts: Int = 0
    private let maxReconnectionAttempts: Int = 5
    private let baseReconnectionDelay: TimeInterval = 2.0
    
    @Inject(key: "FetchDiscoverMoviesUseCase")
    private var fetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCaseProtocol
    @Inject(key: "ReachabilityUseCase")
    private var reachabilityUseCase: ReachabilityUseCaseProtocol
    @Inject(key: "OfflineMoviesUseCase")
    private var offlineMoviesUseCase: OfflineMoviesUseCaseProtocol
    
    init() {
        setupSearchSubscription()
        setupConnectivityMonitoring()
        checkForCachedData()
        setupPeriodicCacheSave()
        setupAppStateMonitoring()
        setupAppLifecycleMonitoring()
        loadSavedAppState()
        checkAppIdleTime()
    }
    
    deinit {
        stopAutomaticReconnection()
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
                        self.lastOfflinePage = page
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
                self.saveCompleteResponseData(response, page: page)
                
                if self.isRefreshingOnReconnect {
                    self.showReconnectionToast = true
                    self.connectionStatus = .reconnected
                    self.isRefreshingOnReconnect = false
                } else {
                    self.connectionStatus = .connected
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSearchSubscription() {
        $searchText
            .sink { [weak self] searchText in
                self?.filterMovies(searchText: searchText)
            }
            .store(in: &cancellables)
        $searchText
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .removeDuplicates()
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
                        self.stopAutomaticReconnection()
                        self.connectionStatus = .reconnecting
                        self.showReconnectionToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.refreshDataOnReconnection()
                        }
                    } else {
                        self.connectionStatus = .connected
                        self.stopAutomaticReconnection()
                    }
                } else {
                    self.connectionStatus = .disconnected
                    self.showReconnectionToast = true
                    self.startAutomaticReconnection()
                    self.saveCurrentDataToCache()
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
        reconnectionAttempts = 0
        let retryPage = lastOfflinePage ?? (currentPage + 1)
        getMovies(page: retryPage)
        lastOfflinePage = nil
    }
    
    private func startAutomaticReconnection() {
        stopAutomaticReconnection()
        reconnectionAttempts = 0
        scheduleNextReconnectionAttempt()
    }
    
    private func stopAutomaticReconnection() {
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
        reconnectionAttempts = 0
    }
    
    private func scheduleNextReconnectionAttempt() {
        guard reconnectionAttempts < maxReconnectionAttempts else {

            return
        }
        reconnectionAttempts += 1
        let delay = baseReconnectionDelay * pow(2.0, Double(reconnectionAttempts - 1))
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.attemptReconnection()
        }
    }
    
    private func attemptReconnection() {
        guard !reachabilityUseCase.execute() else {
            stopAutomaticReconnection()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fetchDiscoverMoviesUseCase
                .discoverMovies(
                    includeAdult: false,
                    includeVideo: false,
                    language: "en-US",
                    page: 1,
                    sortBy: "popularity.desc"
                )
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    guard let self else { return }
                    
                    if case .failure(let error) = completion {
                        self.scheduleNextReconnectionAttempt()
                    }
                } receiveValue: { [weak self] _ in
                    guard let self else { return }
                    self.stopAutomaticReconnection()
                    self.refreshDataOnReconnection()
                }
                .store(in: &self.cancellables)
        }
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
    
    private func saveMoviesToCache(_ movies: [DiscoverMovieItem], page: Int) {
        offlineMoviesUseCase.saveMovies(movies, page: page)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Failed to save movies to cache: \(error)")
                }
            } receiveValue: { [weak self] _ in
                self?.hasCachedData = true
            }
            .store(in: &cancellables)
    }
    
    private func loadCachedMovies() {
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
    
    func loadCachedMoviesForPage(_ page: Int) {
        offlineMoviesUseCase.getCachedMoviesForPage(page)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    print("Failed to load cached movies for page \(page): \(error)")
                }
            } receiveValue: { [weak self] movies in
                guard let self else { return }
                self.allMovies.append(contentsOf: movies)

                if self.searchText.isEmpty {
                    self.filteredMovies = self.allMovies
                } else {
                    self.filterMovies()
                }
            }
            .store(in: &cancellables)
    }
    
    func clearOldCache() {
        offlineMoviesUseCase.clearOldCache(olderThan: 1)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Failed to clear old cache: \(error)")
                }
            } receiveValue: { _ in
                self.clearImageCache()
            }
            .store(in: &cancellables)
    }
    
    private func saveCurrentDataToCache() {
        if !allMovies.isEmpty {
            saveMoviesToCache(allMovies, page: 1)
            preCacheImages(allMovies)
        }
    }
    
    private func setupPeriodicCacheSave() {
        Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.reachabilityUseCase.execute() && !self.allMovies.isEmpty {
                    self.saveMoviesToCache(self.allMovies, page: 1)
                    self.saveCurrentAppState()
                }
                self.updateLastAppUsageTime()
            }
            .store(in: &cancellables)
    }
    
    private func setupAppStateMonitoring() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if !self.allMovies.isEmpty {
                    self.saveMoviesToCache(self.allMovies, page: 1)
                    self.saveCurrentAppState()
                }
                self.updateLastAppUsageTime()
            }
            .store(in: &cancellables)
    }
    
    private func preCacheImages(_ movies: [DiscoverMovieItem]) {
        let newMovies = movies.filter { newMovie in
            guard let newMovieId = newMovie.id else { return false }
            return !cachedMovieIds.contains(newMovieId)
        }
        var allImageURLs: [URL] = []
        var movieImageMap: [URL: Int] = [:]
        
        for movie in newMovies {
            guard let movieId = movie.id else { continue }
            let movieImageURLs = getAllMovieImageURLs(movie)
            allImageURLs.append(contentsOf: movieImageURLs)
            for url in movieImageURLs {
                movieImageMap[url] = movieId
            }
            cachedMovieIds.insert(movieId)
        }

        for url in allImageURLs {
            if let movieId = movieImageMap[url] {
                ImageCacheManager.shared.cacheImage(from: url, for: movieId)
            }
        }
    }
    
    private func getAllMovieImageURLs(_ movie: DiscoverMovieItem) -> [URL] {
        var urls: [URL] = []
        if let posterURL = movie.posterImageURL {
            urls.append(posterURL)
        }
        if let originalPosterURL = movie.originalPosterImageURL {
            urls.append(originalPosterURL)
        }
        if let backdropURL = movie.backdropImageURL {
            urls.append(backdropURL)
        }
        if let originalBackdropURL = movie.originalBackdropImageURL {
            urls.append(originalBackdropURL)
        }
        
        return urls
    }
    
    func clearImageCache() {
        ImageCacheManager.shared.clearOldCache(olderThan: 7)
    }
    
    func clearAllCacheAndRefresh() {
        clearAllCacheAndFetchFreshData()
    }
    private func saveCompleteResponseData(_ response: DiscoverMoviesResponse, page: Int) {
        if let movies = response.results {
            saveMoviesToCache(movies, page: page)
            preCacheImages(movies)
        }
        saveResponseMetadata(response, page: page)
        saveCurrentAppState()

    }
    
    private func saveResponseMetadata(_ response: DiscoverMoviesResponse, page: Int) {
        let metadata = [
            "page": page,
            "totalPages": response.totalPages ?? 0,
            "totalResults": response.totalResults ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        UserDefaults.standard.set(metadata, forKey: "lastResponseMetadata_page_\(page)")
    }
    
    private func saveCurrentAppState() {
        let appState = [
            "currentPage": currentPage,
            "totalPages": totalPages,
            "hasMorePages": hasMorePages,
            "totalMoviesCount": allMovies.count,
            "lastUpdateTime": Date().timeIntervalSince1970
        ] as [String: Any]
        
        UserDefaults.standard.set(appState, forKey: "currentAppState")
        saveCachedMovieIds()
    }
    
    func loadSavedAppState() {
        guard let appState = UserDefaults.standard.dictionary(forKey: "currentAppState") else {
            return
        }
        if let savedCurrentPage = appState["currentPage"] as? Int {
            currentPage = savedCurrentPage
        }
        if let savedTotalPages = appState["totalPages"] as? Int {
            totalPages = savedTotalPages
        }
        if let savedHasMorePages = appState["hasMorePages"] as? Bool {
            hasMorePages = savedHasMorePages
        }
        if let savedTotalMoviesCount = appState["totalMoviesCount"] as? Int {
        }

        loadCachedMovieIds()
    }
    
    private func loadCachedMovieIds() {
        if let cachedIds = UserDefaults.standard.array(forKey: "cachedMovieIds") as? [Int] {
            cachedMovieIds = Set(cachedIds)
        }
    }
    
    private func saveCachedMovieIds() {
        UserDefaults.standard.set(Array(cachedMovieIds), forKey: "cachedMovieIds")
    }

    private func checkAppIdleTime() {
        let currentTime = Date()
        let oneHourInSeconds: TimeInterval = 3600
        if let savedLastUsage = UserDefaults.standard.object(forKey: "lastAppUsageTime") as? Date {
            lastAppUsageTime = savedLastUsage
        }
        
        let timeSinceLastUsage = currentTime.timeIntervalSince(lastAppUsageTime)
        
        if timeSinceLastUsage >= oneHourInSeconds {
            clearAllCacheAndFetchFreshData()
        } else {
            print("FetchMoviesViewModel: App used recently - using cached data")
        }
        updateLastAppUsageTime()
    }
    
    private func updateLastAppUsageTime() {
        lastAppUsageTime = Date()
        UserDefaults.standard.set(lastAppUsageTime, forKey: "lastAppUsageTime")
    }
    
    private func clearAllCacheAndFetchFreshData() {
        clearAllCachedData()
        resetAppState()
        if reachabilityUseCase.execute() {
            getMovies(page: 1)
        } else {
            loadCachedMovies()
        }
    }
    
    private func clearAllCachedData() {
        offlineMoviesUseCase.clearOldCache(olderThan: 0)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Failed to clear offline movies cache: \(error)")
                }
            } receiveValue: { _ in
                print("Cleared all offline movies cache")
            }
            .store(in: &cancellables)
        
        ImageCacheManager.shared.clearOldCache(olderThan: 0)
        cachedMovieIds.removeAll()
        saveCachedMovieIds()
        UserDefaults.standard.removeObject(forKey: "currentAppState")
        UserDefaults.standard.removeObject(forKey: "cachedMovieIds")

    }
    
    private func resetAppState() {
        allMovies.removeAll()
        filteredMovies.removeAll()
        currentPage = 1
        totalPages = 1
        hasMorePages = true
        isOfflineMode = false
        hasCachedData = false
        error = nil

    }
    
    private func setupAppLifecycleMonitoring() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateLastAppUsageTime()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.updateLastAppUsageTime()
            }
            .store(in: &cancellables)
    }
}
