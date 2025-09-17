//
//  NetworkConnectivityMonitor.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Network
import Combine
import SystemConfiguration

final class NetworkConnectivityMonitor: ObservableObject, ReachabilityUseCaseProtocol {
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")
    private var isMonitoring = false
    
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
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func execute() -> Bool {
        isConnected
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let connected = path.status == .satisfied
                let wasConnected = self?.isConnected ?? false
                self?.isConnected = connected
                self?.connectionType = self?.getConnectionType(from: path) ?? .unknown
                if connected {
                    self?.testActualConnectivity()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func testActualConnectivity() {
        let testURLs = [
            "https://www.google.com",
            "https://www.apple.com",
            "https://httpbin.org/status/200"
        ]
        
        guard let url = URL(string: testURLs.randomElement() ?? testURLs[0]) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, 
                   (200...299).contains(httpResponse.statusCode) {
                    self?.isConnected = true
                } else {
                    self?.performAlternativeConnectivityTest()
                }
            }
        }
        task.resume()
    }
    
    private func performAlternativeConnectivityTest() {
        guard let url = URL(string: "https://httpbin.org/status/200") else {
            DispatchQueue.main.async {
                self.isConnected = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, 
                   (200...299).contains(httpResponse.statusCode) {
                    self?.isConnected = true
                } else {
                    self?.isConnected = false
                }
            }
        }
        task.resume()
    }
    
    func checkConnectivity() {
        testActualConnectivity()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}
