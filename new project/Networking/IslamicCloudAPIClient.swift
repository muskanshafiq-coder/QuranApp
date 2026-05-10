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

    /// When `cache` is true, the raw response is persisted under `cacheKey(for:)` so
    /// repositories can read the same bytes back. Callers pass un-encoded paths.
    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        cache: Bool = false
    ) async throws -> T {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        guard var components = URLComponents(string: baseURL + encodedPath) else {
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
            let decoded = try decoder.decode(T.self, from: data)
            if cache {
                DiskCache.shared.setData(data, for: Self.cacheKey(for: path, queryItems: queryItems))
            }
            return decoded
        } catch {
            throw IslamicCloudAPIError.decodingError(error)
        }
    }

    static func cacheKey(for path: String, queryItems: [URLQueryItem] = []) -> String {
        var key = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !queryItems.isEmpty {
            let query = queryItems
                .sorted { $0.name < $1.name }
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")
            key += "?" + query
        }
        return key
    }
    func fetchStoriesCategories(lang: String = "en") async throws -> [StoryCategoryDTO] {
        let response: StoriesCategoriesResponse = try await get(
            path: "/stories/categories",
            queryItems: [URLQueryItem(name: "lang", value: lang)]
        )
        return response.data.categories
    }
    func fetchStories(categoryId: String, lang: String = "en") async throws -> [StoryDTO] {
        let response: StoriesByCategoryResponse = try await get(
            path: "/stories/\(categoryId)",
            queryItems: [URLQueryItem(name: "lang", value: lang)]
        )
        return response.data.stories
    }
    func fetchStoryDetail(storyId: String) async throws -> StoryDetailDTO {
        let response: StoryDetailResponse = try await get(
            path: "/stories/item/\(storyId)",
            queryItems: []
        )
        return response.data.story
    }
    func fetchReciterDetail(slug: String, cache: Bool = false) async throws -> IslamicCloudReciterDetailPayload {
        let segment = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !segment.isEmpty else { throw IslamicCloudAPIError.invalidURL }
        let envelope: IslamicCloudReciterDetailEnvelope = try await get(
            path: AppConfig.IslamicCloud.recitersPath + "/" + segment,
            cache: cache
        )
        guard let data = envelope.data else {
            throw IslamicCloudAPIError.noData
        }
        return data
    }
    func fetchReciters(cache: Bool = false) async throws -> [IslamicCloudReciterDTO] {
        let envelope: IslamicCloudRecitersEnvelope = try await get(
            path: AppConfig.IslamicCloud.recitersPath,
            cache: cache
        )
        return envelope.data?.reciters ?? []
    }

    func fetchQuranPDFs(cache: Bool = false) async throws -> [QuranPDFDTO] {
        let envelope: QuranPDFListEnvelope = try await get(
            path: AppConfig.IslamicCloud.quranPDFsPath,
            cache: cache
        )
        return envelope.data ?? []
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
