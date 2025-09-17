//
//  MovieRepositoryEndpoint.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

enum MovieRepositoryEndpoint {
    case discoverMovies(
        includeAdult: Bool,
        includeVideo: Bool,
        language: String,
        page: Int,
        sortBy: String
    )
}

extension MovieRepositoryEndpoint: ApiEndpoint {
    var baseURLString: String {
        return "https://api.themoviedb.org"
    }
    
    var apiPath: String {
        switch self {
        case .discoverMovies:
            return "3"
        }
    }
    
    var apiVersion: String? {
        return nil
    }
    
    var separatorPath: String? {
        switch self {
        case .discoverMovies:
            return "discover"
        }
    }
    
    var path: String {
        switch self {
        case .discoverMovies:
            return "movie"
        }
    }
    
    var headers: [String: String]? {
        return [
            "accept": "application/json",
            "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJiYjkyN2FjNjkwZmY5ODk1ZjI5ZWM3ZWViOGFlMDAxYSIsIm5iZiI6MTc1NzgzMTU4My40MjU5OTk5LCJzdWIiOiI2OGM2NjE5ZmUxYjU5MWIwYmJlMmZiYzEiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.XIld-MK_7_zdYui1Iy9Bd22T55a3fW-5a8HyclzIO8c"
        ]
    }
    
    var queryForCall: [URLQueryItem]? {
        switch self {
        case let .discoverMovies(includeAdult, includeVideo, language, page, sortBy):
            return [
                URLQueryItem(name: "include_adult", value: includeAdult ? "true" : "false"),
                URLQueryItem(name: "include_video", value: includeVideo ? "true" : "false"),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "sort_by", value: sortBy)
            ]
        }
    }
    
    var params: Any? {
        return nil
    }
    
    var method: APIHTTPMethod {
        return .GET
    }
    
    var customDataBody: Data? {
        return nil
    }
}
