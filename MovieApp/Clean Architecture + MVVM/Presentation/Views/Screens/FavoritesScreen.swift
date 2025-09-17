//
//  FavoritesScreen.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI
import Combine

struct FavoritesScreen: View {
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @Inject(key: "NetworkConnectivityMonitor") private var connectivityMonitor: NetworkConnectivityMonitor
    
    var body: some View {
        VStack(spacing: 0) {
            if favoritesManager.isUpdating && favoritesManager.favoriteMovies.isEmpty {
                LoadingView(message: "Loading favorites...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !favoritesManager.favoriteMovies.isEmpty {
                List(favoritesManager.favoriteMovies, id: \.id) { movie in
                    MovieRowView(movie: movie)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    favoritesManager.refreshFavorites()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No favorites yet")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Add movies to your favorites by tapping the heart icon")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground).opacity(0.8))
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            favoritesManager.loadFavorites()
        }
        .onReceive(connectivityMonitor.$isConnected) { isConnected in
            if isConnected {
                favoritesManager.refreshFavorites()
            } else {
                print("FavoritesScreen: Network disconnected, showing offline indicator")
            }
        }
    }
}
