//
//  LanguageSelectedView.swift
//

import SwiftUI

struct LanguageSelectionView: View {
    @AppStorage("appLanguage") private var selectedLanguage: String = "en"
    @EnvironmentObject var languageManager: AppLanguageManager
    
    let languages: [Language] = [
        .init(name: "English", native: "lang_en", flag: "🇬🇧", code: "en"),
        .init(name: "العربية", native: "lang_ar", flag: "🇦🇪", code: "ar"),
        .init(name: "Français", native: "lang_fr", flag: "🇫🇷", code: "fr"),
        .init(name: "Deutsch", native: "lang_de", flag: "🇩🇪", code: "de"),
        .init(name: "Italiano", native: "lang_it", flag: "🇮🇹", code: "it"),
        .init(name: "Español", native: "lang_es", flag: "🇪🇸", code: "es"),
        .init(name: "Nederlands", native: "lang_nl", flag: "🇳🇱", code: "nl"),
        .init(name: "Indonesia", native: "lang_id", flag: "🇮🇩", code: "id"),
        .init(name: "Bahasa Melayu", native: "lang_ms", flag: "🇲🇾", code: "ms"),
        .init(name: "Türkçe", native: "lang_tr", flag: "🇹🇷", code: "tr"),
        .init(name: "اردو", native: "lang_ur", flag: "🇵🇰", code: "ur"),
        .init(name: "Русский", native: "lang_ru", flag: "🇷🇺", code: "ru")
    ]
    var body: some View {
        List {
            ForEach(languages, id: \.code) { lang in
                Button {
                    languageManager.currentLanguage = lang.code // 🔥 THIS CHANGES LANGUAGE
                    openAppSettings() // optional (rakhna hai to rakh lo)
                } label: {
                    HStack(spacing: 12) {
                        
                        Text(lang.flag)
                            .font(.system(size: 26))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.name)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(lang.native)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if selectedLanguage == lang.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("language_title")
        .navigationBarTitleDisplayMode(.inline)
    }
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString){
            UIApplication.shared.open(url)
        }
    }
}
struct Language {
    let name: String
    let native: LocalizedStringKey   // ✅ change here
    let flag: String
    let code: String
}
