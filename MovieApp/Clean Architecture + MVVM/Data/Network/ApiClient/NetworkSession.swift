//
//  NetworkSession.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

protocol NetworkSessionProtocol: AnyObject {
    func publisher<T>(_ request: URLRequest, decodingType: T.Type) -> AnyPublisher<T, APIErrorHandler> where T: Decodable
}

extension URLSession: NetworkSessionProtocol {
    func publisher<T>(_ request: URLRequest, decodingType: T.Type) -> AnyPublisher<T, APIErrorHandler> where T: Decodable {
        return dataTaskPublisher(for: request)
            .tryMap({ result in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw APIErrorHandler.requestFailed
                }
                if (200..<300) ~= httpResponse.statusCode {
                    return result.data
                } else if httpResponse.statusCode == 401 {
                    throw APIErrorHandler.tokenExpired
                } else {
                    if let error = try? JSONDecoder().decode(ApiError.self, from: result.data) {
                        throw APIErrorHandler.customApiError(error)
                    } else {
                        throw APIErrorHandler.emptyErrorWithStatusCode(httpResponse.statusCode.description)
                    }
                }
            })
            .decode(type: T.self, decoder: customDateJSONDecoder)
            .mapError({ error -> APIErrorHandler in
                if let error = error as? APIErrorHandler {
                    return error
                }
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .timedOut:
                        return APIErrorHandler.noInternetConnection
                    default:
                        return APIErrorHandler.normalError(error)
                    }
                }
                
                return APIErrorHandler.normalError(error)
            })
            .eraseToAnyPublisher()
    }
}

public let customDateJSONDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom(customDateDecodingStrategy)
    return decoder
}()

public func customDateDecodingStrategy(decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    return try Date.dateFromString(str)
}
