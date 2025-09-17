//
//  Inject.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

@propertyWrapper
public struct Inject<Value> {
    public private(set) var wrappedValue: Value
    public init(container: DependencyContainerProtocol = DependencyContainer.shared, key: String? = nil, mode: DependencyResolveMode = .shared) {
        if let key = key {
            wrappedValue = container.resolve(key: key, mode: mode)
        } else {
            wrappedValue = container.resolve(type: Value.self, mode: mode)
        }
    }
}
