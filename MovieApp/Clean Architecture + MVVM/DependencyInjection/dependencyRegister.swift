//
//  dependencyRegister.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine
import SwiftData

public func dependencyRegister() {
    DependencyContainer.shared.register(key: "NetworkSession", dependency: {
        URLSession.shared as NetworkSessionProtocol
    })
    DependencyContainer.shared.register(key: "NetworkManager", dependency: {
        NetworkManager()
    })
    DependencyContainer.shared.register(key: "NetworkConnectivityMonitor", dependency: {
        NetworkConnectivityMonitor()
    })
    DependencyContainer.shared.register(key: "ReachabilityUseCase", dependency: {
        NetworkConnectivityMonitor() as ReachabilityUseCaseProtocol
    })
    DependencyContainer.shared.register(key: "UserDefaultsManager", dependency: {
        UserDefaultsManager()
    })
    DependencyContainer.shared.register(key: "FetchDiscoverMoviesRepository", dependency: {
        FetchDiscoverMoviesRepository()
    })
    DependencyContainer.shared.register(key: "FavoritesRepository", dependency: {
        FavoritesRepositoryFactory.createRepository()
    })
    DependencyContainer.shared.register(key: "FetchDiscoverMoviesUseCase", dependency: {
        FetchDiscoverMoviesUseCase()
    })
    DependencyContainer.shared.register(key: "FavoritesUseCase", dependency: {
        FavoritesUseCase()
    })
    DependencyContainer.shared.register(key: "OfflineMoviesRepository", dependency: {
        OfflineMoviesRepositoryFactory.createRepository()
    })
    DependencyContainer.shared.register(key: "OfflineMoviesUseCase", dependency: {
        OfflineMoviesUseCase(offlineMoviesRepository: DependencyContainer.shared.resolve(key: "OfflineMoviesRepository", mode: .shared) as OfflineMoviesRepositoryProtocol)
    })
}
