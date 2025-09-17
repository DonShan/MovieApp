//
//  MainTabView.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                MoviesScreen()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "film")
                Text("Movies")
            }
            .tag(0)
            
            NavigationView {
                FavoritesScreen()
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Favorites")
            }
            .tag(1)
        }
        .accentColor(.red)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToFavoritesTab"))) { _ in
            selectedTab = 1
        }
    }
}
