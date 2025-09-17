//
//  APIErrorHandler.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

public struct ApiError: Codable {
    public let code: String?
    public let message: String?
    public let errorItems: [String: String]?
    public init(
        code: String? = nil,
        message: String? = nil,
        errorItems: [String: String]? = nil
    ) {
        self.code = code
        self.message = message
        self.errorItems = errorItems
    }
}

public enum APIErrorHandler: Error {
    case customApiError(ApiError)
    case requestFailed
    case normalError(Error)
    case tokenExpired
    case emptyErrorWithStatusCode(String)
    case noData
    case noInternetConnection
    case offlineMode
    public var errorDescription: String? {
        switch self {
        case .customApiError(let apiErrorDTO):
            var itemsText: String?
            if let dict = apiErrorDTO.errorItems {
                itemsText = dict
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: "\n")
            }
            if itemsText == nil,
               apiErrorDTO.code == nil,
               apiErrorDTO.message == nil
            {
                itemsText = "Internal error!"
            }
            return """
                   \(apiErrorDTO.code ?? "")
                   \(apiErrorDTO.message ?? "")
                   \(itemsText ?? "")
                   """
        case .requestFailed:
            return "Request failed"
        case .normalError(let error):
            return error.localizedDescription
        case .tokenExpired:
            return "Token expired or invalid"
        case .emptyErrorWithStatusCode(let status):
            return status
        case .noData:
            return "No data available"
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .offlineMode:
            return "You're currently offline. Showing cached data."
        }
    }
}
