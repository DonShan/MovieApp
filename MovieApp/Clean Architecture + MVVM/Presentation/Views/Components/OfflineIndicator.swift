//
//  OfflineIndicator.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI

struct OfflineIndicator: View {
    let isOffline: Bool
    let isRefreshing: Bool
    let connectionStatus: ConnectionStatus
    @Binding var isShowing: Bool
    
    @State private var hideTimer: Timer?
    @State private var isVisible: Bool = false
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case reconnecting
        case reconnected
    }
    
    var body: some View {
        if shouldShowBanner {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.system(size: 12, weight: .medium))
                
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(iconColor.opacity(0.1))
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                isVisible = true
                scheduleAutoHide()
            }
            .onDisappear {
                isVisible = false
                hideTimer?.invalidate()
                hideTimer = nil
            }
        }
    }
    
    private var shouldShowBanner: Bool {
        return isShowing || 
               isOffline || 
               connectionStatus == .reconnecting || 
               connectionStatus == .reconnected ||
               connectionStatus == .disconnected
    }

    private var message: String {
        if isOffline {
            return "Offline Mode - Showing Cached Movies"
        }
        
        switch connectionStatus {
        case .reconnecting: return "Reconnecting..."
        case .reconnected:  return "Connected - Data refreshed"
        case .connected:    return "Connected"
        case .disconnected: return "No Internet Connection"
        }
    }

    private var iconName: String {
        if isOffline {
            return "wifi.slash"
        }
        
        switch connectionStatus {
        case .reconnecting: return "arrow.triangle.2.circlepath"
        case .reconnected, .connected: return "checkmark.circle.fill"
        case .disconnected: return "wifi.slash"
        }
    }
    
    private var iconColor: Color {
        if isOffline {
            return .orange
        }
        
        switch connectionStatus {
        case .reconnecting: return .blue
        case .reconnected, .connected: return .green
        case .disconnected: return .orange
        }
    }
    
    private func scheduleAutoHide() {
        hideTimer?.invalidate()
        hideTimer = nil
        if isOffline || connectionStatus == .disconnected {
            return
        }
  
        if connectionStatus == .connected || connectionStatus == .reconnected {
            hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                guard isVisible else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}
