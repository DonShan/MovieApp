//
//  WeakInject.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

@propertyWrapper
public struct WeakInject<Value> {
    private weak var underlyingValue: AnyObject?
    public var wrappedValue: Value? {
        underlyingValue as? Value
    }
    
    public init(container: DependencyContainerProtocol = DependencyContainer.shared, key: String? = nil, mode: DependencyResolveMode = .shared) {
        if let key = key {
            underlyingValue = container.resolve(key: key, mode: mode)
        } else {
            underlyingValue = container.resolve(type: Value.self, mode: mode) as AnyObject
        }
    }
}
