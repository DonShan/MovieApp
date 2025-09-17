//
//  FavoritesViewModel.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

class FavoritesViewModel: ObservableObject {
    @Published var isFavorite: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let movie: DiscoverMovieItem
    private var cancellables = Set<AnyCancellable>()
    @Inject(key: "FavoritesUseCase")
    private var favoritesUseCase: FavoritesUseCaseProtocol
    
    init(movie: DiscoverMovieItem) {
        self.movie = movie
        checkFavoriteStatus()
    }
    
    func toggleFavorite() {
        isLoading = true
        error = nil
        
        favoritesUseCase.toggleFavorite(movie)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] isFavorite in
                    self?.isFavorite = isFavorite
                }
            )
            .store(in: &cancellables)
    }
    
    private func checkFavoriteStatus() {
        favoritesUseCase.isFavorite(movie)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] isFavorite in
                    self?.isFavorite = isFavorite
                }
            )
            .store(in: &cancellables)
    }
}
