//
//  MockUserDefaultsManager.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

final class MockUserDefaultsManager: UserDefaultsManagerProtocol {
    private var storage: [String: Data] = [:]
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockUserDefaultsManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    var saveCallCount = 0
    var loadCallCount = 0
    var removeCallCount = 0
    var existsCallCount = 0
    
    var lastSavedKey: String?
    var lastLoadedKey: String?
    var lastRemovedKey: String?
    var lastCheckedKey: String?

    func save<T: Codable>(_ object: T, forKey key: String) {
        saveCallCount += 1
        lastSavedKey = key
        
        if shouldThrowError {
            return
        }
        
        do {
            let data = try JSONEncoder().encode(object)
            storage[key] = data
        } catch {
            print("error saving data: \(error)")
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        loadCallCount += 1
        lastLoadedKey = key
        
        if shouldThrowError {
            return nil
        }
        
        guard let data = storage[key] else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return nil
        }
    }
    
    func remove(forKey key: String) {
        removeCallCount += 1
        lastRemovedKey = key
        
        if shouldThrowError {
            return
        }
        
        storage.removeValue(forKey: key)
    }
    
    func exists(forKey key: String) -> Bool {
        existsCallCount += 1
        lastCheckedKey = key
        
        if shouldThrowError {
            return false
        }
        
        return storage[key] != nil
    }
    
    func reset() {
        storage.removeAll()
        saveCallCount = 0
        loadCallCount = 0
        removeCallCount = 0
        existsCallCount = 0
        lastSavedKey = nil
        lastLoadedKey = nil
        lastRemovedKey = nil
        lastCheckedKey = nil
        shouldThrowError = false
    }
    
    func setData(_ data: Data, forKey key: String) {
        storage[key] = data
    }
    
    func getData(forKey key: String) -> Data? {
        return storage[key]
    }
}
