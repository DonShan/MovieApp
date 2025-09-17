//
//  OfflineMovie.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import SwiftData

@Model
final class OfflineMovie {
    var adult: Bool
    var backdropPath: String?
    var genreIds: [Int]
    var id: Int
    var originalLanguage: String?
    var originalTitle: String?
    var overview: String?
    var popularity: Double?
    var posterPath: String?
    var releaseDate: String?
    var title: String?
    var video: Bool
    var voteAverage: Double?
    var voteCount: Int?
    var dateCached: Date
    var pageNumber: Int
    
    init(adult: Bool = false,
         backdropPath: String? = nil,
         genreIds: [Int] = [],
         id: Int,
         originalLanguage: String? = nil,
         originalTitle: String? = nil,
         overview: String? = nil,
         popularity: Double? = nil,
         posterPath: String? = nil,
         releaseDate: String? = nil,
         title: String? = nil,
         video: Bool = false,
         voteAverage: Double? = nil,
         voteCount: Int? = nil,
         pageNumber: Int = 1) {
        self.adult = adult
        self.backdropPath = backdropPath
        self.genreIds = genreIds
        self.id = id
        self.originalLanguage = originalLanguage
        self.originalTitle = originalTitle
        self.overview = overview
        self.popularity = popularity
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.title = title
        self.video = video
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.dateCached = Date()
        self.pageNumber = pageNumber
    }
    
    convenience init(from discoverMovie: DiscoverMovieItem, pageNumber: Int = 1) {
        self.init(
            adult: discoverMovie.adult ?? false,
            backdropPath: discoverMovie.backdropPath,
            genreIds: discoverMovie.genreIds ?? [],
            id: discoverMovie.id ?? 0,
            originalLanguage: discoverMovie.originalLanguage,
            originalTitle: discoverMovie.originalTitle,
            overview: discoverMovie.overview,
            popularity: discoverMovie.popularity,
            posterPath: discoverMovie.posterPath,
            releaseDate: discoverMovie.releaseDate,
            title: discoverMovie.title,
            video: discoverMovie.video ?? false,
            voteAverage: discoverMovie.voteAverage,
            voteCount: discoverMovie.voteCount,
            pageNumber: pageNumber
        )
    }
    
    var discoverMovieItem: DiscoverMovieItem {
        return DiscoverMovieItem(
            adult: adult,
            backdropPath: backdropPath,
            genreIds: genreIds.isEmpty ? nil : genreIds,
            id: id,
            originalLanguage: originalLanguage,
            originalTitle: originalTitle,
            overview: overview,
            popularity: popularity,
            posterPath: posterPath,
            releaseDate: releaseDate,
            title: title,
            video: video,
            voteAverage: voteAverage,
            voteCount: voteCount
        )
    }
    
    var posterImageURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(posterPath)")
    }
}

extension OfflineMovie: Equatable {
    static func == (lhs: OfflineMovie, rhs: OfflineMovie) -> Bool {
        return lhs.id == rhs.id
    }
}
