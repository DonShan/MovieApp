//
//  MockNetworkConnectivityMonitor.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

protocol NetworkConnectivityMonitorProtocol: ReachabilityUseCaseProtocol {
    var isConnected: Bool { get }
    var connectionType: ConnectionType { get }
    var isConnectedPublisher: AnyPublisher<Bool, Never> { get }
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> { get }
    var reconnectedPublisher: AnyPublisher<Void, Never> { get }
    
    func execute() -> Bool
    func startMonitoring()
    func stopMonitoring()
}

final class MockNetworkConnectivityMonitor: NetworkConnectivityMonitorProtocol {
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .wifi
    
    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        $isConnected.removeDuplicates().eraseToAnyPublisher()
    }
    
    var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
        $connectionType.removeDuplicates().eraseToAnyPublisher()
    }
    
    var reconnectedPublisher: AnyPublisher<Void, Never> {
        $isConnected
            .removeDuplicates()
            .filter { $0 }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    var mockIsConnected: Bool = true {
        didSet {
            isConnected = mockIsConnected
        }
    }
    
    var mockConnectionType: ConnectionType = .wifi {
        didSet {
            connectionType = mockConnectionType
        }
    }
    
    var startMonitoringCallCount = 0
    var stopMonitoringCallCount = 0
    var executeCallCount = 0
    
    func execute() -> Bool {
        executeCallCount += 1
        return isConnected
    }
    
    func startMonitoring() {
        startMonitoringCallCount += 1
    }
    
    func stopMonitoring() {
        stopMonitoringCallCount += 1
    }
    
    func reset() {
        mockIsConnected = true
        mockConnectionType = .wifi
        isConnected = true
        connectionType = .wifi
        startMonitoringCallCount = 0
        stopMonitoringCallCount = 0
        executeCallCount = 0
    }
    
    func simulateConnectionChange(isConnected: Bool, connectionType: ConnectionType = .wifi) {
        self.mockIsConnected = isConnected
        self.mockConnectionType = connectionType
    }
    
    func simulateReconnection() {
        mockIsConnected = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mockIsConnected = true
        }
    }
}
