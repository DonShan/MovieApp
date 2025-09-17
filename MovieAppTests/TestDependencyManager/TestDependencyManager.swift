//
//  TestDependencyManager.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
@testable import MovieApp

class TestDependencyManager {
    static let shared = TestDependencyManager()
    
    private var testContainer: DependencyContainerProtocol
    private var isInitialized = false
    
    private init() {
        self.testContainer = TestDependencyContainer()
    }

    func initializeTestDependencies() {
        guard !isInitialized else { return }
        (testContainer as! TestDependencyContainer).reset()
        registerTestDependencies()
        isInitialized = true
    }

    func resetTestDependencies() {
        (testContainer as! TestDependencyContainer).reset()
        isInitialized = false
    }

    func getTestContainer() -> DependencyContainerProtocol {
        if !isInitialized {
            initializeTestDependencies()
        }
        return testContainer
    }
    
    private func registerTestDependencies() {
        testContainer.register(key: "UserDefaultsManager") {
            MockUserDefaultsManager() as UserDefaultsManagerProtocol
        }
        
        testContainer.register(key: "FavoritesRepository") {
            MockFavoritesRepository() as FavoritesRepositoryProtocol
        }
        
        testContainer.register(key: "FetchDiscoverMoviesRepository") {
            MockFetchDiscoverMoviesRepository() as FetchDiscoverMoviesRepositoryProtocol
        }

        testContainer.register(key: "NetworkManager") {
            MockNetworkManager() as NetworkManagerProtocol
        }
        
        testContainer.register(key: "NetworkConnectivityMonitor") {
            MockNetworkConnectivityMonitor() as NetworkConnectivityMonitorProtocol
        }
        
        testContainer.register(key: "OfflineMoviesRepository") {
            MockOfflineMoviesRepository() as OfflineMoviesRepositoryProtocol
        }
    }
}

extension TestDependencyManager {
    
    func getMockFavoritesRepository() -> MockFavoritesRepository {
        return testContainer.resolve<FavoritesRepositoryProtocol>(key: "FavoritesRepository", mode: .shared)
    }
    
    func getMockUserDefaultsManager() -> MockUserDefaultsManager {
        return testContainer.resolve<UserDefaultsManagerProtocol>(key: "UserDefaultsManager", mode: .shared)
    }
    
    func getMockFetchDiscoverMoviesRepository() -> MockFetchDiscoverMoviesRepository {
        return testContainer.resolve<FetchDiscoverMoviesRepositoryProtocol>(key: "FetchDiscoverMoviesRepository", mode: .shared)
    }
    
    func getMockNetworkManager() -> MockNetworkManager {
        return testContainer.resolve<NetworkManagerProtocol>(key: "NetworkManager", mode: .shared)
    }
    
    func getMockNetworkConnectivityMonitor() -> MockNetworkConnectivityMonitor {
        return testContainer.resolve<NetworkConnectivityMonitorProtocol>(key: "NetworkConnectivityMonitor", mode: .shared) 
    }
    
    func getMockOfflineMoviesRepository() -> MockOfflineMoviesRepository {
        return testContainer.resolve<OfflineMoviesRepositoryProtocol>(key: "OfflineMoviesRepository", mode: .shared)
    }
}

private class TestDependencyContainer: DependencyContainerProtocol {
    public var dependencyInitializer: [String: () -> Any] = [:]
    public var dependencyShared: [String: Any] = [:]
    
    public func register<DependencyType>(type: DependencyType.Type, dependency: @escaping () -> DependencyType) {
        register(key: dependencyKey(for: type), dependency: dependency)
    }
    
    public func register<DependencyType>(key: String, dependency: @escaping () -> DependencyType) {
        dependencyInitializer[key] = dependency
    }
    
    public func resolve<DependencyType>(type: DependencyType.Type, mode: DependencyResolveMode) -> DependencyType {
        resolve(key: dependencyKey(for: type), mode: mode)
    }
    
    public func resolve<DependencyType>(key: String, mode: DependencyResolveMode) -> DependencyType {
        switch mode {
        case .new:
            guard let newDependency = dependencyInitializer[key]?() as? DependencyType else {
                preconditionFailure("TestDependencyContainer.resolve. There is no dependency registered for this type. Please register a dependency for this type.")
            }
            return newDependency
        case .shared:
            if dependencyShared[key] == nil, let dependency = dependencyInitializer[key]?() {
                dependencyShared[key] = dependency
            }
            guard let sharedDependency = dependencyShared[key] as? DependencyType else {
                preconditionFailure("TestDependencyContainer.resolve. There is no dependency registered for this type. Please register a dependency for this type.")
            }
            return sharedDependency
        }
    }
    
    private func dependencyKey<DependencyType>(for type: DependencyType.Type) -> String {
        String(describing: type)
    }
    
    func reset() {
        dependencyInitializer.removeAll()
        dependencyShared.removeAll()
    }
}
