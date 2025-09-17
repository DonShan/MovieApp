//
//  MockNetworkManager.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

protocol NetworkManagerProtocol {
    func performRequest<T>(_ request: URLRequest, decodingType: T.Type) -> AnyPublisher<T, APIErrorHandler> where T: Decodable
}

final class MockNetworkManager: NetworkManagerProtocol {
    var result: Result<Data, APIErrorHandler>?
    var performRequestCallCount = 0
    var lastRequest: URLRequest?
    var lastDecodingType: Any.Type?

    func performRequest<T>(_ request: URLRequest, decodingType: T.Type) -> AnyPublisher<T, APIErrorHandler> where T: Decodable {
        performRequestCallCount += 1
        lastRequest = request
        lastDecodingType = T.self
        
        guard let result = result else {
            return Fail(error: APIErrorHandler.requestFailed).eraseToAnyPublisher()
        }
        
        switch result {
        case .success(let data):
            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                return Just(decodedObject)
                    .setFailureType(to: APIErrorHandler.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: APIErrorHandler.requestFailed).eraseToAnyPublisher()
            }
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func reset() {
        result = nil
        performRequestCallCount = 0
        lastRequest = nil
        lastDecodingType = nil
    }
    
    func setSuccessResult<T: Codable>(_ object: T) {
        do {
            let data = try JSONEncoder().encode(object)
            result = .success(data)
        } catch {
            result = .failure(.normalError(error))
        }
    }
    
    func setFailureResult(_ error: APIErrorHandler) {
        result = .failure(error)
    }
}
