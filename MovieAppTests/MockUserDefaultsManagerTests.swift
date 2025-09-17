//
//  MockUserDefaultsManagerTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import XCTest
@testable import MovieApp

final class MockUserDefaultsManagerTests: XCTestCase {

    private var mockUserDefaults: MockUserDefaultsManager!

    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaultsManager()
    }

    override func tearDown() {
        mockUserDefaults = nil
        super.tearDown()
    }

    func test_save_success() {
        // Given
        let testObject = TestCodableObject(name: "Test", value: 123)
        let key = "test_key"

        // When
        mockUserDefaults.save(testObject, forKey: key)

        // Then
        XCTAssertEqual(mockUserDefaults.saveCallCount, 1)
        XCTAssertEqual(mockUserDefaults.lastSavedKey, key)
        XCTAssertTrue(mockUserDefaults.exists(forKey: key))
    }

    func test_load_success() {
        // Given
        let testObject = TestCodableObject(name: "Test", value: 123)
        let key = "test_key"
        mockUserDefaults.save(testObject, forKey: key)

        // When
        let loadedObject = mockUserDefaults.load(TestCodableObject.self, forKey: key)

        // Then
        XCTAssertEqual(mockUserDefaults.loadCallCount, 1)
        XCTAssertEqual(mockUserDefaults.lastLoadedKey, key)
        XCTAssertNotNil(loadedObject)
        XCTAssertEqual(loadedObject?.name, "Test")
        XCTAssertEqual(loadedObject?.value, 123)
    }

    func test_load_notFound() {
        // Given
        let key = "non_existent_key"

        // When
        let loadedObject = mockUserDefaults.load(TestCodableObject.self, forKey: key)

        // Then
        XCTAssertEqual(mockUserDefaults.loadCallCount, 1)
        XCTAssertEqual(mockUserDefaults.lastLoadedKey, key)
        XCTAssertNil(loadedObject)
    }

    func test_remove_success() {
        // Given
        let testObject = TestCodableObject(name: "Test", value: 123)
        let key = "test_key"
        mockUserDefaults.save(testObject, forKey: key)
        XCTAssertTrue(mockUserDefaults.exists(forKey: key))

        // When
        mockUserDefaults.remove(forKey: key)

        // Then
        XCTAssertEqual(mockUserDefaults.removeCallCount, 1)
        XCTAssertEqual(mockUserDefaults.lastRemovedKey, key)
        XCTAssertFalse(mockUserDefaults.exists(forKey: key))
    }

    func test_exists_true() {
        // Given
        let testObject = TestCodableObject(name: "Test", value: 123)
        let key = "test_key"
        mockUserDefaults.save(testObject, forKey: key)

        // When
        let exists = mockUserDefaults.exists(forKey: key)

        // Then
        XCTAssertEqual(mockUserDefaults.existsCallCount, 1)
        XCTAssertEqual(mockUserDefaults.lastCheckedKey, key)
        XCTAssertTrue(exists)
    }

    func test_exists_false() {
        // Given
        let key = "non_existent_key"

        // When
        let exists = mockUserDefaults.exists(forKey: key)

        // Then
        XCTAssertEqual(mockUserDefaults.existsCallCount, 1)
        XCTAssertEqual(mockUserDefaults.lastCheckedKey, key)
        XCTAssertFalse(exists)
    }

    func test_reset() {
        // Given
        let testObject = TestCodableObject(name: "Test", value: 123)
        let key = "test_key"
        mockUserDefaults.save(testObject, forKey: key)
        mockUserDefaults.load(TestCodableObject.self, forKey: key)
        mockUserDefaults.remove(forKey: key)
        mockUserDefaults.exists(forKey: key)

        // When
        mockUserDefaults.reset()

        // Then
        XCTAssertEqual(mockUserDefaults.saveCallCount, 0)
        XCTAssertEqual(mockUserDefaults.loadCallCount, 0)
        XCTAssertEqual(mockUserDefaults.removeCallCount, 0)
        XCTAssertEqual(mockUserDefaults.existsCallCount, 0)
        XCTAssertNil(mockUserDefaults.lastSavedKey)
        XCTAssertNil(mockUserDefaults.lastLoadedKey)
        XCTAssertNil(mockUserDefaults.lastRemovedKey)
        XCTAssertNil(mockUserDefaults.lastCheckedKey)
        XCTAssertFalse(mockUserDefaults.shouldThrowError)
    }
}

private struct TestCodableObject: Codable, Equatable {
    let name: String
    let value: Int
}
