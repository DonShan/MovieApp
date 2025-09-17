//
//  NetworkUnavailableView.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import SwiftUI

struct NetworkUnavailableView: View {
    let connectionType: ConnectionType
    let onRetry: (() -> Void)?
    
    init(connectionType: ConnectionType = .unknown, onRetry: (() -> Void)? = nil) {
        self.connectionType = connectionType
        self.onRetry = onRetry
    }
    
    var body: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(
                "No Internet Connection",
                systemImage: "wifi.exclamationmark",
                description: Text("Please check your \(connectionType.displayName.lowercased()) connection and try again.")
            )
            .overlay(
                VStack {
                    Spacer()
                    if let onRetry = onRetry {
                        Button("Try Again") {
                            onRetry()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 20)
                    }
                }
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("No Internet Connection")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Please check your \(connectionType.displayName.lowercased()) connection and try again.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let onRetry = onRetry {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct NetworkReconnectingView: View {
    let connectionType: ConnectionType
    
    var body: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(
                "Reconnecting...",
                systemImage: connectionType.iconName,
                description: Text("Attempting to reconnect to \(connectionType.displayName)")
            )
            .overlay(
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.bottom, 20)
                }
            )
        } else {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .foregroundColor(.blue)
                
                Text("Reconnecting...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Attempting to reconnect to \(connectionType.displayName)")
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
        }
    }
}

struct NetworkConnectedView: View {
    let connectionType: ConnectionType
    let message: String
    
    init(connectionType: ConnectionType, message: String = "Connected") {
        self.connectionType = connectionType
        self.message = message
    }
    
    var body: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView(
                message,
                systemImage: "checkmark.circle.fill",
                description: Text("Connected via \(connectionType.displayName)")
            )
        } else {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Connected via \(connectionType.displayName)")
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
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        NetworkUnavailableView(connectionType: .wifi) {}
        NetworkReconnectingView(connectionType: .cellular)
        NetworkConnectedView(connectionType: .wifi, message: "Connected - Data refreshed")
    }
    .padding()
}
