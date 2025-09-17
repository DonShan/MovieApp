//
//  ReachabilityUseCaseProtocol.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//


import Foundation
import Combine

protocol ReachabilityUseCaseProtocol: AnyObject {
    var isConnected: Bool { get }
    var connectionType: ConnectionType { get }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> { get }
    var reconnectedPublisher: AnyPublisher<Void, Never> { get }
    
    func execute() -> Bool
    func startMonitoring()
    func stopMonitoring()
}

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
    
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        case .unknown: return "questionmark.circle"
        }
    }
}
