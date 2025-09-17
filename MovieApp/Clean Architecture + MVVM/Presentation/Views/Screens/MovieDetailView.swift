//
//  MovieDetailView.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI

struct MovieDetailView: View {
    let movie: DiscoverMovieItem
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    CachedAsyncImage(url: movie.posterImageURL, movieId: movie.id)
                        .frame(width: 120, height: 180)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(movie.title ?? "Unknown Title")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                        
                        if let releaseDate = movie.releaseDate {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                Text(DateFormatterUtil.formatMovieReleaseDate(releaseDate))
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        if let voteAverage = movie.voteAverage {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", voteAverage))
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                        }
                        
                        if let popularity = movie.popularity {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.blue)
                                Text(String(format: "%.0f", popularity))
                                    .fontWeight(.medium)
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                if let overview = movie.overview, !overview.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(overview)
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        if let originalTitle = movie.originalTitle, originalTitle != movie.title {
                            DetailRow(title: "Original Title", value: originalTitle)
                        }
                        
                        if let originalLanguage = movie.originalLanguage {
                            DetailRow(title: "Original Language", value: originalLanguage.uppercased())
                        }
                        
                        if let adult = movie.adult {
                            DetailRow(title: "Content Rating", value: adult ? "Adult" : "General Audience")
                        }
                        
                        if let voteCount = movie.voteCount {
                            DetailRow(title: "Vote Count", value: "\(voteCount)")
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 50)
            }
        }
        .navigationTitle(movie.title ?? "Movie Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    favoritesManager.toggleFavorite(movie)
                }) {
                    Image(systemName: favoritesManager.isFavorite(movie) ? "heart.fill" : "heart")
                        .foregroundColor(favoritesManager.isFavorite(movie) ? .red : .primary)
                        .font(.title2)
                }
                .disabled(favoritesManager.isUpdating)
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}
