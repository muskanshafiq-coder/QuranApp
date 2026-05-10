//
//  IslamicCloudStoriesModels.swift
//

import Foundation

// MARK: - Categories (GET /stories/categories?lang=en)

struct StoriesCategoriesResponse: Codable {
    let code: Int
    let status: String
    let data: StoriesCategoriesData
}

struct StoriesCategoriesData: Codable {
    let supportedLangs: [String]
    let categories: [StoryCategoryDTO]
    let total: Int
}

struct StoryCategoryDTO: Codable, Identifiable {
    let id: String
    let slug: String
    let thumbnail: String?
    let createdAt: String
    let language: String
    let title: String
    let description: String?
}

// MARK: - Stories by category (GET /stories/{categoryId}?lang=en)

struct StoriesByCategoryResponse: Codable {
    let code: Int
    let status: String
    let data: StoriesByCategoryData
    let attribution: AttributionDTO?
}

struct AttributionDTO: Codable {
    let note: String?
    let sources: [String]?
}

struct StoriesByCategoryData: Codable {
    let lang: String
    let supportedLangs: [String]
    let category: StoryCategoryMiniDTO
    let stories: [StoryDTO]
    let total: Int
}

struct StoryCategoryMiniDTO: Codable {
    let id: String
    let slug: String
    let thumbnail: String?
}

struct StoryDTO: Codable, Identifiable {
    let id: String
    let type: String
    let hasChapters: Bool
    let thumbnail: String?
    let author: String?
    let source: String?
    let createdAt: String
    let language: String
    let title: String
    let description: String?
    let files: [StoryFileDTO]
}

struct StoryFileDTO: Codable, Identifiable {
    let id: String
    let fileUrl: String
    let duration: Double?
    let isChapter: Bool
    let chapterNumber: Int?
}

// MARK: - Single story detail (GET /stories/item/{storyId})

struct StoryDetailResponse: Codable {
    let code: Int
    let status: String
    let data: StoryDetailData
}

struct StoryDetailData: Codable {
    let story: StoryDetailDTO
    let supportedLangs: [String]
}

struct StoryDetailDTO: Codable {
    let id: String
    let categoryId: String
    let type: String
    let hasChapters: Bool
    let thumbnail: String?
    let author: String?
    let source: String?
    let createdAt: String
    let category: StoryCategoryMiniDTO
    let translations: [StoryTranslationDTO]
}

struct StoryTranslationDTO: Codable {
    let id: String
    let language: String
    let title: String
    let description: String?
    let files: [StoryFileDTO]
}
