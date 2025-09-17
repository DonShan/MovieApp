//
//  ApiEndpoint.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation

protocol ApiEndpoint {
    var baseURLString: String { get }
    var apiPath: String { get }
    var apiVersion: String? { get }
    var separatorPath: String? { get }
    var path: String { get }
    var headers: [String: String]? { get }
    var queryForCall: [URLQueryItem]? { get }
    var params: Any? { get }
    var method: APIHTTPMethod { get }
    var customDataBody: Data? { get }
}

extension ApiEndpoint {
    var makeRequest: URLRequest {
        var urlComponents = URLComponents(string: baseURLString)
        var pathComponents = [apiPath]
        
        if let apiVersion = apiVersion, !apiVersion.isEmpty {
            pathComponents.append(apiVersion)
        }
        
        if let separatorPath = separatorPath, !separatorPath.isEmpty {
            pathComponents.append(separatorPath)
        }
        
        if !path.isEmpty {
            pathComponents.append(path)
        }
        
        if let existingPath = urlComponents?.path, !existingPath.isEmpty {
            urlComponents?.path = existingPath + "/" + pathComponents.joined(separator: "/")
        } else {
            urlComponents?.path = "/" + pathComponents.joined(separator: "/")
        }
        
        if let queryForCalls = queryForCall {
            urlComponents?.queryItems = queryForCalls
        }
        
        guard let url = urlComponents?.url else { return URLRequest(url: URL(string: baseURLString)!) }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let headers = headers {
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        if let params = params {
            if JSONSerialization.isValidJSONObject(params) {
                let jsonData = try? JSONSerialization.data(withJSONObject: params)
                request.httpBody = jsonData
            } else if let encodableParams = params as? Encodable {
                let encoder = JSONEncoder()
                request.httpBody = try? encoder.encode(encodableParams)
            } else {
                print("Invalid parameters for JSON serialization.")
            }
        }
        
        if let customDataBody = customDataBody {
            request.httpBody = customDataBody
        }
        
        return request
    }
}

