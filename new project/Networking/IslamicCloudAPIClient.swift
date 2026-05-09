//
//  IslamicCloudAPIClient.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import Foundation
final class IslamicCloudAPIClient {
    static let shared = IslamicCloudAPIClient()
    
    private let baseURL = AppConfig.IslamicCloud.baseURL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let bearerToken = AppConfig.IslamicCloud.bearerToken

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    /// Generic GET request with query parameters. Use for any Islamic Cloud API endpoint.
    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw IslamicCloudAPIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw IslamicCloudAPIError.invalidURL
        }
        #if DEBUG
        print("[IslamicCloudAPI] Request URL: \(url)")
        #endif
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw IslamicCloudAPIError.noData
        }
        guard (200..<300).contains(http.statusCode) else {
            throw IslamicCloudAPIError.serverError(http.statusCode, data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw IslamicCloudAPIError.decodingError(error)
        }
    }
    /// GET /stories/categories?lang=...
    func fetchStoriesCategories(lang: String = "en") async throws -> [StoryCategoryDTO] {
        let response: StoriesCategoriesResponse = try await get(
            path: "/stories/categories",
            queryItems: [URLQueryItem(name: "lang", value: lang)]
        )
        return response.data.categories
    }
    /// GET /stories/{categoryId}?lang=...
    func fetchStories(categoryId: String, lang: String = "en") async throws -> [StoryDTO] {
        let response: StoriesByCategoryResponse = try await get(
            path: "/stories/\(categoryId)",
            queryItems: [URLQueryItem(name: "lang", value: lang)]
        )
        return response.data.stories
    }
    /// GET /stories/item/{storyId}
    func fetchStoryDetail(storyId: String) async throws -> StoryDetailDTO {
        let response: StoryDetailResponse = try await get(
            path: "/stories/item/\(storyId)",
            queryItems: []
        )
        return response.data.story
    }
    /// Single reciter with `surahs[]` and audio URLs — `GET /reciters/{slug}`.
    func fetchReciterDetail(slug: String) async throws -> IslamicCloudReciterDetailPayload {
        let segment = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !segment.isEmpty else { throw IslamicCloudAPIError.invalidURL }
        let encoded = segment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? segment
        let path = AppConfig.IslamicCloud.recitersPath + "/" + encoded
        let envelope: IslamicCloudReciterDetailEnvelope = try await get(path: path, queryItems: [])
        guard let data = envelope.data else {
            throw IslamicCloudAPIError.noData
        }
        return data
    }
    /// Fetches all Quran reciters (`/reciters`): each row includes `type` (`featured` | `standard`).
    func fetchReciters() async throws -> [IslamicCloudReciterDTO] {
        let envelope: IslamicCloudRecitersEnvelope = try await get(path: AppConfig.IslamicCloud.recitersPath, queryItems: [])
        return envelope.data?.reciters ?? []
    }
}

// MARK: - Islamic Cloud API Error
enum IslamicCloudAPIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int, Data?)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .serverError(let code, _): return "Server error (\(code))"
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        }
    }
}
