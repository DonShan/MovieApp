//
//  FetchDiscoverMoviesUseCase.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Combine

class FetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCaseProtocol {
    @Inject(key: "FetchDiscoverMoviesRepository")
    private var fetchDiscoverMoviesRepository: FetchDiscoverMoviesRepositoryProtocol
    
    func discoverMovies(
        includeAdult: Bool,
        includeVideo: Bool,
        language: String,
        page: Int,
        sortBy: String
    ) -> AnyPublisher<DiscoverMoviesResponse, APIErrorHandler> {
        fetchDiscoverMoviesRepository.discoverMovies(
            includeAdult: includeAdult,
            includeVideo: includeVideo,
            language: language,
            page: page,
            sortBy: sortBy
        )
    }
}

