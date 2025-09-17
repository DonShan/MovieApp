//
//  DependencyContainerProtocol.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

public protocol DependencyContainerProtocol {
    func register<DependencyType>(type: DependencyType.Type, dependency: @escaping () -> DependencyType)
    func resolve<DependencyType>(type: DependencyType.Type, mode: DependencyResolveMode) -> DependencyType
    func register<DependencyType>(key: String, dependency: @escaping () -> DependencyType)
    func resolve<DependencyType>(key: String, mode: DependencyResolveMode) -> DependencyType
}
