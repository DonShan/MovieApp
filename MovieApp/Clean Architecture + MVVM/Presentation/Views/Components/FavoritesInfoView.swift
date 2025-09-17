//
//  FavoritesInfoView.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI

struct FavoritesInfoView: View {
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Favorites Information")
                .font(.headline)
            
            HStack {
                Text("Total Favorites:")
                Spacer()
                Text("\(favoritesManager.favoriteMovies.count)")
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Status:")
                Spacer()
                Text(favoritesManager.isUpdating ? "Updating..." : "Ready")
                    .fontWeight(.medium)
                    .foregroundColor(favoritesManager.isUpdating ? .orange : .green)
            }
            
            if !favoritesManager.favoriteMovies.isEmpty {
                HStack {
                    Text("Last Updated:")
                    Spacer()
                    Text("Just now")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Refresh Favorites") {
                favoritesManager.refreshFavorites()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    FavoritesInfoView()
        .padding()
}
