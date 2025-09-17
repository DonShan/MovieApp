//
//  NetworkMonitorView.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI
import Combine

struct NetworkMonitorView: View {
    @StateObject private var reachability = NetworkConnectivityMonitor()
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: reachability.isConnected ? "globe" : "wifi.slash")
                    .font(.system(size: 60))
                    .foregroundColor(reachability.isConnected ? .green : .red)
                
                Text(reachability.isConnected ? "Connected" : "Disconnected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(reachability.isConnected ? .green : .red)
                
                Text("Connection Type: \(reachability.connectionType.displayName)")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .shadow(radius: 4)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(reachability.isConnected ? "Online" : "Offline")
                        .foregroundColor(reachability.isConnected ? .green : .red)
                }
                HStack {
                    Text("Type:")
                    Spacer()
                    Text(reachability.connectionType.displayName)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
            VStack(spacing: 12) {
                Button("Check Connection Status") {
                    print("Manual check: \(reachability.execute())")
                }
                .buttonStyle(.borderedProminent)
                Button("Force Refresh Data") {
                    refreshData()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Network Monitor")
        .onAppear {
            reachability.reconnectedPublisher
                .sink { refreshData() }
                .store(in: &cancellables)
        }
    }
    
    private func refreshData() {
        print("Data refresh triggered after reconnect")
    }
}
