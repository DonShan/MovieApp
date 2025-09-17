//
//  NetworkStatusView.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI

struct NetworkStatusView: View {
    @StateObject private var reachability = NetworkConnectivityMonitor()
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: reachability.isConnected ? reachability.connectionType.iconName : "wifi.slash")
                .foregroundColor(reachability.isConnected ? .green : .orange)
                .font(.system(size: 14, weight: .medium))
            
            Text(reachability.isConnected ? "Connected via \(reachability.connectionType.displayName)" : "No Connection")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(reachability.isConnected ? .green : .orange)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(reachability.isConnected ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

