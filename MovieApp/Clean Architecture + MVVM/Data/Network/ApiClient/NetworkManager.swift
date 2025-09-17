//
//  NetworkManager.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    @Inject(key: "NetworkSession") var NetworkSession: NetworkSessionProtocol
    
    func performRequest<T>(_ request: URLRequest, decodingType: T.Type) -> AnyPublisher<T, APIErrorHandler> where T: Decodable {
        return NetworkSession.publisher(request, decodingType: decodingType)
            .mapError { error -> APIErrorHandler in
                if let error = error as? APIErrorHandler {
                    return error
                }
                return APIErrorHandler.normalError(error)
            }
            .eraseToAnyPublisher()
    }
}
