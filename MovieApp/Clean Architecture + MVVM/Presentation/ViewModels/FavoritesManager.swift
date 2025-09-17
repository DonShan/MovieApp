//
//  FavoritesManager.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    @Published var favoriteMovies: [DiscoverMovieItem] = []
    @Published var isUpdating: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    @Inject(key: "FavoritesUseCase")
    private var favoritesUseCase: FavoritesUseCaseProtocol
    
    private init() {
        loadFavorites()
    }
    
    func loadFavorites() {
        isUpdating = true
        favoritesUseCase.getFavorites()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isUpdating = false
                },
                receiveValue: { [weak self] favorites in
                    self?.favoriteMovies = favorites
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleFavorite(_ movie: DiscoverMovieItem) {
        isUpdating = true
        
        favoritesUseCase.toggleFavorite(movie)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isUpdating = false
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        break
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadFavorites()
                }
            )
            .store(in: &cancellables)
    }
    
    func isFavorite(_ movie: DiscoverMovieItem) -> Bool {
        return favoriteMovies.contains { $0.id == movie.id }
    }
    
    func refreshFavorites() {
        loadFavorites()
    }
}

