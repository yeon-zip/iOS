//
//  RepositoryProtocols.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

protocol SearchRepository {
    func searchBooks(query: String) async -> [BookSummary]
}

protocol BookRepository {
    func fetchBookDetail(id: String) async -> BookDetail?
}

protocol LibraryRepository {
    func fetchHomeLibraries(distance: DistanceOption, excludeClosed: Bool) async -> [LibrarySummary]
    func fetchNearbyLibraries(query: SearchQuery) async -> [LibrarySummary]
    func fetchLibraryDetail(id: String) async -> LibraryDetail?
}

protocol FavoritesRepository {
    func fetchFavoriteBooks() async -> [BookSummary]
    func fetchFavoriteLibraries() async -> [LibrarySummary]
}

protocol AlertsRepository {
    func fetchAlerts() async -> [AlertItem]
}

protocol ProfileRepository {
    func fetchProfile() async -> UserProfile
}
