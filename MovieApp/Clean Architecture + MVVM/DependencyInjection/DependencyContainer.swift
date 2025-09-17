//
//  DependencyContainer.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

public class DependencyContainer {
    public static let shared: DependencyContainerProtocol = DependencyContainer()
    public var dependencyInitializer: [String: () -> Any] = [:]
    public var dependencyShared: [String: Any] = [:]
}
