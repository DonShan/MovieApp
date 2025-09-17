//
//  CachedAsyncImage.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI
import UIKit

struct CachedAsyncImage: View {
    let url: URL?
    let movieId: Int?
    @StateObject private var imageCacheManager = ImageCacheManager.shared
    @State private var cachedImage: UIImage?
    
    init(url: URL?, movieId: Int? = nil) {
        self.url = url
        self.movieId = movieId
    }
    
    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let url = url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear {
                            imageCacheManager.cacheImage(from: url, for: movieId)
                        }
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(2/3, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(2/3, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadCachedImage()
        }
    }
    
    private func loadCachedImage() {
        guard let url = url else { return }
        
        if let cached = imageCacheManager.getCachedImage(for: url.absoluteString) {
            cachedImage = cached
        }
    }
}
