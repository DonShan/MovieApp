//
//  ImageCacheManager.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import SwiftData
import UIKit
import Combine

class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private init() {
        guard let container = ImageCacheManager.sharedModelContainer else {
            fatalError("ImageCacheManager requires ModelContainer to be set")
        }
        self.modelContainer = container
        self.modelContext = ModelContext(modelContainer)
    }
    
    static var sharedModelContainer: ModelContainer?
    func cacheImage(from url: URL, for movieId: Int? = nil) {
        if getCachedImage(for: url.absoluteString) != nil {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                self?.saveImageToCache(url: url.absoluteString, imageData: data, movieId: movieId)
            }
        }.resume()
    }
    
    func cacheImagesBatch(_ urls: [URL], for movieId: Int? = nil) {
        for url in urls {
            cacheImage(from: url, for: movieId)
        }
    }
    
    private func saveImageToCache(url: String, imageData: Data, movieId: Int?) {
        do {
            let descriptor = FetchDescriptor<CachedImage>(
                predicate: #Predicate { $0.url == url }
            )
            let existingImages = try modelContext.fetch(descriptor)
            for image in existingImages {
                modelContext.delete(image)
            }

            let cachedImage = CachedImage(url: url, imageData: imageData, movieId: movieId)
            modelContext.insert(cachedImage)
            try modelContext.save()
        } catch {
        }
    }
    
    func getCachedImage(for url: String) -> UIImage? {
        do {
            let descriptor = FetchDescriptor<CachedImage>(
                predicate: #Predicate { $0.url == url }
            )
            let cachedImages = try modelContext.fetch(descriptor)
            return cachedImages.first?.uiImage
        } catch {
            return nil
        }
    }
    
    func clearOldCache(olderThan days: Int = 7) {
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let descriptor = FetchDescriptor<CachedImage>(
                predicate: #Predicate { $0.dateCached < cutoffDate }
            )
            let oldImages = try modelContext.fetch(descriptor)
            
            for image in oldImages {
                modelContext.delete(image)
            }
            try modelContext.save()
        } catch {
            print("Failed to clear old cache: \(error)")
        }
    }
}
