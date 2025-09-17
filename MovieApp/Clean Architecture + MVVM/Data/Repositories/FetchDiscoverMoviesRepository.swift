//
//  FetchDiscoverMoviesRepository.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Combine

class FetchDiscoverMoviesRepository: FetchDiscoverMoviesRepositoryProtocol {
    @Inject(key: "NetworkManager") var networkManager: NetworkManager
    @Inject(key: "NetworkConnectivityMonitor") var connectivityMonitor: NetworkConnectivityMonitor
    
    func discoverMovies(
        includeAdult: Bool,
        includeVideo: Bool,
        language: String,
        page: Int,
        sortBy: String
    ) -> AnyPublisher<DiscoverMoviesResponse, APIErrorHandler> {
        
        guard connectivityMonitor.isConnected else {
            return Fail(error: APIErrorHandler.noInternetConnection)
                .eraseToAnyPublisher()
        }
        
        let endpoint = MovieRepositoryEndpoint.discoverMovies(
            includeAdult: includeAdult,
            includeVideo: includeVideo,
            language: language,
            page: page,
            sortBy: sortBy
        )
        
        let request = endpoint.makeRequest
        
        return networkManager.performRequest(request, decodingType: DiscoverMoviesResponse.self)
            .eraseToAnyPublisher()
    }
    
}
