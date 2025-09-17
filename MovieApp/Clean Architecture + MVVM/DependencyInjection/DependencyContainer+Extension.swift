//
//  DependencyContainer+Extension.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

extension DependencyContainer: DependencyContainerProtocol {
    public func register<DependencyType>(type: DependencyType.Type, dependency: @escaping () -> DependencyType) {
        register(key: dependencyKey(for: type), dependency: dependency)
    }
    
    public func register<DependencyType>(key: String, dependency: @escaping () -> DependencyType) {
        dependencyInitializer[key] = dependency
    }
    
    public func resolve<DependencyType>(type: DependencyType.Type, mode: DependencyResolveMode) -> DependencyType {
        resolve(key: dependencyKey(for: type), mode: mode)
    }
    
    public func resolve<DependencyType>(key: String, mode: DependencyResolveMode) -> DependencyType {
        switch mode {
        case .new:
            guard let newDependency = dependencyInitializer[key]?() as? DependencyType else {
                preconditionFailure("DependencyContainer.resolve. There is no dependency registered for this type. Please register a dependency for this type.")
            }
            return newDependency
        case .shared:
            if dependencyShared[key] == nil, let dependency = dependencyInitializer[key]?() {
                dependencyShared[key] = dependency
            }
            guard let sharedDependency = dependencyShared[key] as? DependencyType else {
                preconditionFailure("DependencyContainer.resolve. There is no dependency registered for this type. Please register a dependency for this type.")
            }
            return sharedDependency
        }
    }
    
    private func dependencyKey<DependencyType>(for type: DependencyType.Type) -> String {
        String(describing: type)
    }
}
