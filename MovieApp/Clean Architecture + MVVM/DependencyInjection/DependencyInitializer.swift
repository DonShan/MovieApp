//
//  DependencyInitializer.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import SwiftData
import SwiftUI

public class DependencyInitializer {
    @Inject(key: "NetworkSession", mode: .shared) var networkSession: NetworkSessionProtocol
    @Inject(key: "NetworkManager", mode: .shared) var networkManager: NetworkManager
    @Inject(key: "FetchDiscoverMoviesUseCase", mode: .shared) var fetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCaseProtocol
    @Inject(key: "FetchDiscoverMoviesRepository", mode: .shared) var fetchDiscoverMoviesRepository: FetchDiscoverMoviesRepositoryProtocol
}
