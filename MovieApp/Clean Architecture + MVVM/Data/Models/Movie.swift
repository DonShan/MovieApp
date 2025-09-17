//
//  Movie.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import SwiftData

@Model
final class Movie {
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
    var dateAdded: Date
    
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
         voteCount: Int? = nil) {
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
        self.dateAdded = Date()
    }
    
    convenience init(from discoverMovie: DiscoverMovieItem) {
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
            voteCount: discoverMovie.voteCount
        )
    }
    
    var posterImageURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w154\(posterPath)")
    }
    
    var backdropImageURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(backdropPath)")
    }
    
    var originalPosterImageURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(posterPath)")
    }
    
    var originalBackdropImageURL: URL? {
        guard let backdropPath = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/original\(backdropPath)")
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
}

extension Movie: Equatable {
    static func == (lhs: Movie, rhs: Movie) -> Bool {
        return lhs.id == rhs.id
    }
}

