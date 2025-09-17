//
//  LazyInject.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

@propertyWrapper
public struct LazyInject<Value> {
    private let container: DependencyContainerProtocol
    private let key: String?
    private let mode: DependencyResolveMode
    
    public private(set) lazy var wrappedValue: Value = {
        if let key = key {
            return container.resolve(key: key, mode: mode)
        } else {
            return container.resolve(type: Value.self, mode: mode)
        }
    }()
    
    public init(container: DependencyContainerProtocol = DependencyContainer.shared, key: String? = nil, mode: DependencyResolveMode = .shared) {
        self.container = container
        self.key = key
        self.mode = mode
    }
}
