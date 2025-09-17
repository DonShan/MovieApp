//
//  MockNetworkManagerTests.swift
//  MovieAppTests
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import XCTest
import Combine
@testable import MovieApp

final class MockNetworkManagerTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()
    private var mockNetworkManager: MockNetworkManager!

    override func setUp() {
        super.setUp()
        mockNetworkManager = MockNetworkManager()
    }

    override func tearDown() {
        cancellables.removeAll()
        mockNetworkManager = nil
        super.tearDown()
    }

    func test_performRequest_success() {
        // Given
        let expectedResponse = TestResponse(message: "Success", code: 200)
        mockNetworkManager.setSuccessResult(expectedResponse)
        
        let url = URL(string: "https://www.googlr.com/test")!
        let request = URLRequest(url: url)
        let expectation = self.expectation(description: "Should return success response")

        // When
        mockNetworkManager.performRequest(request, decodingType: TestResponse.self)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected failure: \(error)")
                }
            }, receiveValue: { response in
                // Then
                XCTAssertEqual(response.message, expectedResponse.message)
                XCTAssertEqual(response.code, expectedResponse.code)
                XCTAssertEqual(self.mockNetworkManager.performRequestCallCount, 1)
                XCTAssertEqual(self.mockNetworkManager.lastRequest?.url, url)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_performRequest_failure() {
        // Given
        let expectedError = APIErrorHandler.tokenExpired
        mockNetworkManager.setFailureResult(expectedError)
        
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        let expectation = self.expectation(description: "Should return error")

        // When
        mockNetworkManager.performRequest(request, decodingType: TestResponse.self)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertEqual(error.errorDescription, expectedError.errorDescription)
                    XCTAssertEqual(self.mockNetworkManager.performRequestCallCount, 1)
                    XCTAssertEqual(self.mockNetworkManager.lastRequest?.url, url)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure, got success")
                }
            }, receiveValue: { _ in
                XCTFail("Expected no value on failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_performRequest_noResultSet() {
        // Given
        mockNetworkManager.result = nil
        
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        let expectation = self.expectation(description: "Should fail due to missing result")

        // When
        mockNetworkManager.performRequest(request, decodingType: TestResponse.self)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertEqual(error.errorDescription, APIErrorHandler.requestFailed.errorDescription)
                    XCTAssertEqual(self.mockNetworkManager.performRequestCallCount, 1)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected failure due to missing mock result")
                }
            }, receiveValue: { _ in
                XCTFail("Expected no value when result is nil")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func test_reset() {
        // Given
        let testResponse = TestResponse(message: "Test", code: 200)
        mockNetworkManager.setSuccessResult(testResponse)
        let url = URL(string: "https://api.example.com/test")!
        let request = URLRequest(url: url)
        mockNetworkManager.performRequest(request, decodingType: TestResponse.self)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        // When
        mockNetworkManager.reset()

        // Then
        XCTAssertNil(mockNetworkManager.result)
        XCTAssertEqual(mockNetworkManager.performRequestCallCount, 0)
        XCTAssertNil(mockNetworkManager.lastRequest)
        XCTAssertNil(mockNetworkManager.lastDecodingType)
    }
}

private struct TestResponse: Codable, Equatable {
    let message: String
    let code: Int
}
