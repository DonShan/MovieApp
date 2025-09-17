//
//  FetchDiscoverMoviesRepositoryProtocol.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Combine

protocol FetchDiscoverMoviesRepositoryProtocol {
    func discoverMovies(
        includeAdult: Bool,
        includeVideo: Bool,
        language: String,
        page: Int,
        sortBy: String
    ) -> AnyPublisher<DiscoverMoviesResponse, APIErrorHandler>
}

