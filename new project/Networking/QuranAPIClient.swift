//
//  QuranAPIClient.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import Foundation
enum QuranAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .networkError(let e): return "Network: \(e.localizedDescription)"
        case .serverError(let code): return "Server error \(code)"
        }
    }
}

final class QuranAPIClient {
    static let shared = QuranAPIClient()
    private let baseURL = AppConfig.QuranCloud.baseURL
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
    }
    func fetchPhoneticTransliteration(surahNumber: Int) async throws -> [Int: String] {
        guard let url = URL(string: "https://api.quran.com/api/v4/quran/translations/57?chapter_number=\(surahNumber)") else {
            throw QuranAPIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        try validateResponse(data: data, response: response)
        let decoded = try decoder.decode(QuranComTransliterationResponse.self, from: data)
        var result: [Int: String] = [:]
        for (index, entry) in decoded.translations.enumerated() {
            result[index + 1] = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
    /// Fetch one surah with translation for a given edition (e.g. en.shakir, ur.jalandhry).
    /// GET https://api.alquran.cloud/v1/surah/{number}/{editionIdentifier}
    /// Returns map: ayah numberInSurah -> translation text.
    func fetchTranslatedSurah(surahNumber: Int, editionIdentifier: String) async throws -> [Int: String] {
        let encoded = editionIdentifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? editionIdentifier
        guard let url = URL(string: "\(baseURL)/surah/\(surahNumber)/\(encoded)") else {
            throw QuranAPIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        try validateResponse(data: data, response: response)
        let surahResponse = try decoder.decode(SurahResponse.self, from: data)
        var result: [Int: String] = [:]
        for ayah in surahResponse.data.ayahs {
            result[ayah.numberInSurah] = ayah.text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }
    /// Fetch one surah with all ayahs (Arabic)
    func fetchSurah(number: Int) async throws -> (surah: SurahItem, ayahs: [AyahItem]) {
        let url = URL(string: "\(baseURL)/surah/\(number)")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(data: data, response: response)
        let surahResponse = try decoder.decode(SurahResponse.self, from: data)
        let item = SurahItem(
            id: surahResponse.data.number,
            number: surahResponse.data.number,
            nameArabic: surahResponse.data.name,
            nameEnglish: surahResponse.data.englishName,
            numberOfAyahs: surahResponse.data.numberOfAyahs,
            revelationType: surahResponse.data.revelationType
        )
        let ayahs = surahResponse.data.ayahs.map { $0.toAyahItem() }
        return (item, ayahs)
    }
    /// Fetch full meta (surahs, hizbQuarters, sajdas)
    func fetchMetaFull() async throws -> QuranMetaData {
        let url = URL(string: "\(baseURL)/meta")!
        let (data, response) = try await session.data(from: url)
        try validateResponse(data: data, response: response)
        let metaResponse = try decoder.decode(QuranMetaResponse.self, from: data)
        return metaResponse.data
    }
    
    /// Get verse text for (surah, ayah); surahName from surahs list
    func getVerseText(surahNumber: Int, ayahNumber: Int, surahNameEnglish: String) async throws -> String {
        let result = try await fetchSurah(number: surahNumber)
        guard let ayah = result.ayahs.first(where: { $0.numberInSurah == ayahNumber }) else {
            return ""
        }
        return ayah.text
    }
    private func validateResponse(data: Data, response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw QuranAPIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw QuranAPIError.serverError(http.statusCode)
        }
    }
}
extension AyahResponse {
    func toAyahItem() -> AyahItem {
        AyahItem(
            id: number,
            numberInSurah: numberInSurah,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            juz: juz,
            hizbQuarter: hizbQuarter,
            page: page
        )
    }
}
