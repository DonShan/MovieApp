//
//  MovieRowView.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI

struct MovieRowView: View {
    let movie: DiscoverMovieItem
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        NavigationLink {
            MovieDetailView(movie: movie)
        } label: {
            HStack(spacing: 12) {
                CachedAsyncImage(url: movie.posterImageURL, movieId: movie.id)
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title ?? "Unknown Title")
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let releaseDate = movie.releaseDate {
                        Text(DateFormatterUtil.formatMovieReleaseDate(releaseDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let voteAverage = movie.voteAverage {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", voteAverage))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            .overlay(
                HStack {
                    Spacer()
                    Button(action: {
                        favoritesManager.toggleFavorite(movie)
                    }) {
                        Image(systemName: favoritesManager.isFavorite(movie) ? "heart.fill" : "heart")
                            .foregroundColor(favoritesManager.isFavorite(movie) ? .red : .gray)
                            .font(.title2)
                    }
                    .disabled(favoritesManager.isUpdating)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 16)
                }
            )
        }
    }
}
