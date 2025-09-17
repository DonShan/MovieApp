//
//  UserDefaultsManager.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

protocol UserDefaultsManagerProtocol {
    func save<T: Codable>(_ object: T, forKey key: String)
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func exists(forKey key: String) -> Bool
}

class UserDefaultsManager: UserDefaultsManagerProtocol {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Failed to save object for key \(key): \(error)")
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load object for key \(key): \(error)")
            return nil
        }
    }
    
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}

extension UserDefaultsManager {
    static let favoritesKey = "favorite_movies"
}
