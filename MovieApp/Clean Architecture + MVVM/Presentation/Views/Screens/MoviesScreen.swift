//
//  MoviesScreen.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI
import Combine

struct MoviesScreen: View {
    @StateObject private var viewModel = FetchMoviesViewModel()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @Inject(key: "ReachabilityUseCase")
    private var reachabilityUseCase: ReachabilityUseCaseProtocol
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            OfflineIndicator(
                isOffline: viewModel.isOfflineMode,
                isRefreshing: viewModel.isRefreshingOnReconnect,
                connectionStatus: viewModel.connectionStatus,
                isShowing: $viewModel.showReconnectionToast
            )
            
            if !viewModel.filteredMovies.isEmpty {
                let movies = Array(viewModel.filteredMovies.enumerated())
                List(movies, id: \.offset) { item in
                    let index = item.offset
                    let movie = item.element
                    
                    MovieRowView(movie: movie)
                        .onAppear {
                            if index >= viewModel.filteredMovies.count - 1 && viewModel.canLoadMore {
                                viewModel.loadMoreMovies()
                            }
                        }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    viewModel.refreshMovies()
                }
                .overlay(
                    VStack {
                        Spacer()
                        if viewModel.isLoadingMore {
                            LoadingMoreView()
                                .padding(.bottom, 20)
                        } else if viewModel.canLoadMore && !viewModel.isOffline {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Text("Scroll for more movies")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                Spacer()
                            }
                            .padding(.bottom, 20)
                        }
                    }
                )
            } else if let error = viewModel.error {
                if case .noInternetConnection = error {
                    if viewModel.hasCachedData {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("No Internet Connection")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Showing cached movies. Tap to retry when connection is available.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Retry") {
                                viewModel.getMovies(page: 1)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground).opacity(0.8))
                    } else {
                        NetworkUnavailableView(
                            connectionType: reachabilityUseCase.connectionType,
                            onRetry: {
                                viewModel.getMovies(page: 1)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground).opacity(0.8))
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: getErrorIcon(for: error))
                            .font(.system(size: 50))
                            .foregroundColor(getErrorColor(for: error))
                        
                        Text(getErrorTitle(for: error))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            viewModel.retryAfterError()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
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
            } else if viewModel.searchText.isEmpty {
                LoadingView(message: "Loading movies...")
                    .onAppear {
                        viewModel.getMovies(page: 1)
                    }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No movies found")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("No movies found for '\(viewModel.searchText)'")
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
        .navigationTitle("Movies")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            favoritesManager.loadFavorites()
        }
        .onReceive(favoritesManager.$favoriteMovies) { _ in }
    }
    
    private func getErrorIcon(for error: APIErrorHandler) -> String {
        switch error {
        case .noInternetConnection, .offlineMode:
            return "wifi.slash"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func getErrorColor(for error: APIErrorHandler) -> Color {
        switch error {
        case .noInternetConnection, .offlineMode:
            return .orange
        default:
            return .red.opacity(0.8)
        }
    }
    
    private func getErrorTitle(for error: APIErrorHandler) -> String {
        switch error {
        case .noInternetConnection:
            return "No Internet Connection"
        case .offlineMode:
            return "Offline Mode"
        default:
            return "Something went wrong"
        }
    }
}
