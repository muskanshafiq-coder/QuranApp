//
//  AppConfig.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import Foundation

enum AppConfig {

    // MARK: - Islamic Cloud API
    enum IslamicCloud {
        static let baseURL = "https://app.islamicloud.com/api"
        static let bearerToken = AppSecrets.islamicCloudBearerToken
        /// Quran reciter catalogue (profiles + portraits). GET `{base}/reciters`
        static let recitersPath = "/reciters"
    }
}

/// Reads compile-time secrets from `Info.plist`, which are injected from
/// `Secrets.xcconfig` via build settings.
enum AppSecrets {
    static let islamicCloudBearerToken: String = value(for: "ISLAMIC_CLOUD_TOKEN")

    private static func value(for key: String) -> String {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !raw.isEmpty,
            raw != "$(\(key))"
        else {
            fatalError(
                """
                Missing secret '\(key)'.
                Make sure Secrets.xcconfig exists at the project root, defines \(key),
                and is attached as the project base configuration in Xcode.
                See Secrets.xcconfig.example for the template.
                """
            )
        }
        return raw
    }
}
