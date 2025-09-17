//
//  CachedImage.swift
//  MovieApp
//
//  Created by MadushanSenavirathna on 2025-09-14.
//

import Foundation
import SwiftData
import UIKit

@Model
final class CachedImage {
    var url: String
    var imageData: Data
    var dateCached: Date
    var movieId: Int?
    
    init(url: String, imageData: Data, movieId: Int? = nil) {
        self.url = url
        self.imageData = imageData
        self.movieId = movieId
        self.dateCached = Date()
    }
    
    var uiImage: UIImage? {
        return UIImage(data: imageData)
    }
}
