//
//  MockFetchDiscoverMoviesRepository.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

final class MockFetchDiscoverMoviesRepository: FetchDiscoverMoviesRepositoryProtocol {
    var result: Result<DiscoverMoviesResponse, APIErrorHandler>?
    func reset() {
        result = nil
    }

    func discoverMovies(
        includeAdult: Bool,
        includeVideo: Bool,
        language: String,
        page: Int,
        sortBy: String
    ) -> AnyPublisher<DiscoverMoviesResponse, APIErrorHandler> {
        guard let result = result else {
            return Fail(error: APIErrorHandler.requestFailed).eraseToAnyPublisher()
        }
        switch result {
        case .success(let response):
            return Just(response)
                .setFailureType(to: APIErrorHandler.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
