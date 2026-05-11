//
//  QuranDetailOptionsSheet.swift
//  Quran App
//
//  Created by apple on 07/02/2026.
//

import SwiftUI
import UIKit
import AlertKit
// MARK: - Translation Item for Options Sheet
struct TranslationItem: Identifiable {
    /// Stable ID for persistence and API mapping (e.g. "en", "ur", "ar").
    let translationId: String
    /// Language code for Al-Quran API ?lang= (e.g. "en", "ur").
    let apiLangCode: String
    let flag: String
    /// Resolved display strings only: API names stay literal; UI strings use `String(localized:)` when built.
    let name: String
    let secondary: String
    var id: String { translationId }
}

/// Maps old stored IDs to Al-Quran Cloud edition identifiers for migration.
private let legacyIdToEditionIdentifier: [String: String] = [
    "ar": "quran-buck",
    "ur": "ur.jalandhry",
    "en": "en.shakir",
    "en_yusuf_ali": "en.yusufali",
    "en_phonetic": "en.transliteration"
]

/// Fixed display for Arabic mushaf (quran-buck); title is localized.
private func makeQuranInArabicTranslationItem() -> TranslationItem {
    let title = String(localized: String.LocalizationValue("quran_in_arabic_title"))
    return TranslationItem(
        translationId: "quran-buck",
        apiLangCode: "ar",
        flag: "🇦🇪",
        name: title,
        secondary: title
    )
}

/// Only this edition is shown in the dedicated "Phonetic" section; other transliterations go in Available/Downloaded.
private let phoneticOnlyEditionIdentifier = "en.transliteration"

/// Resolves edition identifier for fetching (supports legacy IDs).
enum TranslationRegistry {
    /// Edition ID used for phonetic transliteration; when selected, we fetch from Quran.com API for reference-style text.
    static let phoneticEditionIdentifier = "en.transliteration"

    static func editionIdentifier(for translationId: String) -> String? {
        if translationId.contains(".") { return translationId }
        return legacyIdToEditionIdentifier[translationId]
    }

    /// Flag emoji for the given translation ID (for toolbar in surah detail).
    static func flag(for translationId: String) -> String {
        if translationId == "quran-buck" { return "🇦🇪" }
        if translationId == phoneticOnlyEditionIdentifier { return "🇬🇧" }
        let lang = String(translationId.prefix(while: { $0 != "." }))
        return languageFlagMap[lang] ?? "🌐"
    }
}

/// Only these editions (from the reference images) are shown; no other API translations.
private let allowedEditionIdentifiers: Set<String> = [
    "quran-buck", "ur.jalandhry", "sq.ahmeti", "az.mammadaliyev", "ber.mensur", "bn.hoque", "bs.korkut",
    "zh.jian", "cs.hrbek", "dv.divehi", "nl.keyzer", "en.shakir", "en.yusufali", "fr.hamidullah", "de.aburida",
    "hi.farooq", "id.indonesian", "it.piccardo", "ja.japanese", "ku.asan", "ms.basmeih", "ml.abdulhameed",
    "no.berg", "fa.makarem", "pl.bielawskiego", "pt.elhayek", "ru.kuliev", "sd.amroti", "so.abduh",
    "es.cortes", "sv.bernstrom", "ta.tamil", "tr.bulac", "uz.sodik"
]

/// Display order for Available section (matches the reference images).
private let availableTranslationOrder: [String] = [
    "sq.ahmeti",            // Albanian - sherif ahmeti
    "az.mammadaliyev",      // Azerbaijan - mammadaliyev & bunyadov
    "ber.mensur",           // Amazigh
    "bn.hoque",             // Bengali - zohurul hoque
    "bs.korkut",            // Bosnian - besim korkut
    "zh.jian",              // Chinese - ma jian
    "cs.hrbek",             // Czech
    "dv.divehi",            // Divehi
    "nl.keyzer",            // Dutch - salomo keyzer
    "en.shakir",            // English - mohammad habib shakir
    "en.yusufali",          // English - abdullah yusuf ali
    "fr.hamidullah",        // French - muhammad hamidullah
    "de.aburida",           // German - abu rida muhammad
    "hi.farooq",            // Hindi - muhammad farooq khan
    "id.indonesian",        // Indonesian
    "it.piccardo",          // Italian - hamza roberto piccardo
    "ja.japanese",          // Japanese
    "ku.asan",              // Kurdish - burhan muhammad-amin
    "ms.basmeih",           // Malay - abdullah muhammad basmeih
    "ml.abdulhameed",      // Malayalam - cheriyamundam abdul hameed
    "no.berg",              // Norwegian - einar berg
    "fa.makarem",           // Persian - naser makarem shirazi
    "pl.bielawskiego",      // Polish - józefa bielawskiego
    "pt.elhayek",           // Portuguese - samir el-hayek
    "ru.kuliev",            // Russian - elmir kuliev
    "sd.amroti",            // Sindhi - taj mehmood amroti
    "so.abduh",             // Somali - mahmud muhammad abduh
    "es.cortes",            // Spanish - julio cortes
    "sv.bernstrom",         // Swedish - knut bernström
    "ta.tamil",             // Tamil - jan turst foundation
    "tr.bulac",             // Turkish - ali bulaç
    "ur.jalandhry",         // Urdu - fateh muhammad jalandhry
    "uz.sodik",             // Uzbek - muhammad sodik muhammad yusuf
]

/// Language code -> flag emoji for edition list (Al-Quran Cloud uses 2-letter codes).
private let languageFlagMap: [String: String] = [
    "ar": "🇦🇪", "az": "🇦🇿", "bn": "🇧🇩", "bs": "🇧🇦", "cs": "🇨🇿", "de": "🇩🇪", "dv": "🇲🇻",
    "en": "🇬🇧", "es": "🇪🇸", "fa": "🇮🇷", "fr": "🇫🇷", "ha": "🇳🇬", "hi": "🇮🇳", "id": "🇮🇩",
    "it": "🇮🇹", "ja": "🇯🇵", "ko": "🇰🇷", "ku": "🇮🇶", "ml": "🇮🇳", "ms": "🇲🇾", "nl": "🇳🇱",
    "no": "🇳🇴", "pl": "🇵🇱", "ps": "🇦🇫", "pt": "🇵🇹", "ro": "🇷🇴", "ru": "🇷🇺", "sd": "🇵🇰",
    "si": "🇱🇰", "so": "🇸🇴", "sq": "🇦🇱", "sv": "🇸🇪", "sw": "🇹🇿", "ta": "🇮🇳", "tg": "🇹🇯",
    "th": "🇹🇭", "tr": "🇹🇷", "tt": "🇷🇺", "ug": "🇨🇳", "ur": "🇵🇰", "uz": "🇺🇿", "zh": "🇨🇳",
    "ber": "🇩🇿", "ce": "🇷🇺", "ba": "🇧🇦", "am": "🇪🇹", "my": "🇲🇲"
]

// MARK: - Quran Detail Options (Translations / Appearance)
enum QuranDetailOptionsTab: String, CaseIterable, Identifiable {
    case translations
    case appearance
    var id: String { rawValue }

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .translations: return "quran_options_tab_translations"
        case .appearance: return "quran_options_tab_appearance"
        }
    }
}

private enum QuranAppearanceRoute: Hashable {
    case fontAndSize
}

struct QuranDetailOptionsSheet: View {
    /// Default editions shown with no delete/checkmark icons (Al-Quran Cloud identifiers).
    private let defaultTranslationIds: Set<String> = ["quran-buck"]
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    let initialTab: QuranDetailOptionsTab
    let onDismiss: () -> Void
    
    @State private var selectedTab: QuranDetailOptionsTab
    @AppStorage(UserDefaultsManager.Keys.quranFontFamily) private var selectedFont: String = QuranAyahDisplayFont.freeReciterArabicFontFamilyId
    @ObservedObject private var premiumManager = PremiumManager.shared
    @AppStorage(UserDefaultsManager.Keys.quranFontSize) private var fontSize: Double = 20
    @AppStorage(UserDefaultsManager.Keys.quranReciterAyahScrollSpeed) private var reciterAyahScrollSpeed: Double = 0.5
    @State private var appearanceNavPath = NavigationPath()
    @State private var downloadedIds: [String] = []
    @State private var selectedIds: [String] = []
    /// Loaded from Al-Quran Cloud GET /v1/edition?format=text&type=translation
    @State private var allTranslationItems: [TranslationItem] = []
    /// Loaded from GET /v1/edition?format=text&type=transliteration (phonetic)
    @State private var allPhoneticItems: [TranslationItem] = []
    @State private var editionsLoading = true

    /// UserDefaults / `UserDefaultsManager.Keys.quranFontFamily` ids (first is free; rest premium unless subscribed).
    private let quranFontFamilyIds: [String] = [
        QuranAyahDisplayFont.freeReciterArabicFontFamilyId,
        "Me Quran",
        "PDMS Saleem Quran Font",
        "Al Qalam Quran Majeed Web",
        "Scheherazade",
        "SF font",
        "Noto Naskh Arabic",
        "Noto Nastaliq Urdu",
        "Noto Kufi Arabic",
        "Droid Arabic Naskh"
    ]

    /// Localized title for the font picker; `id` is the value stored in UserDefaults.
    private func localizedQuranFontName(_ id: String) -> String {
        let key: String
        switch id {
        case QuranAyahDisplayFont.freeReciterArabicFontFamilyId: key = "quran_font_family_nabi"
        case "Me Quran": key = "quran_font_family_me_quran"
        case "PDMS Saleem Quran Font": key = "quran_font_family_pdms_saleem"
        case "Al Qalam Quran Majeed Web": key = "quran_font_family_al_qalam_majeed_web"
        case "Droid Arabic Naskh": key = "quran_font_family_droid_arabic_naskh"
        case "SF font": key = "quran_font_family_sf"
        case "Noto Kufi Arabic": key = "quran_font_family_noto_kufi_arabic"
        case "Noto Naskh Arabic": key = "quran_font_family_noto_naskh_arabic"
        case "Noto Nastaliq Urdu": key = "quran_font_family_noto_nastaliq_urdu"
        case "Scheherazade": key = "quran_font_family_scheherazade"
        default: return id
        }
        return key
    }
    
    init(initialTab: QuranDetailOptionsTab, onDismiss: @escaping () -> Void) {
        self.initialTab = initialTab
        self.onDismiss = onDismiss
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        NavigationStack(path: $appearanceNavPath) {
            ZStack {
                Color.app
                    .ignoresSafeArea()

                Group {
                    if selectedTab == .translations {
                        translationsContent
                    } else {
                        appearanceOverviewContent
                    }
                }
            }
            .navigationDestination(for: QuranAppearanceRoute.self) { route in
                switch route {
                case .fontAndSize:
                    appearanceFontAndSizeDetailContent
                        .navigationTitle("quran_appearance_nav_title_font")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if selectedTab == .translations || appearanceNavPath.isEmpty {
                        Picker("", selection: $selectedTab) {
                            ForEach(QuranDetailOptionsTab.allCases) { tab in
                                Text(tab.localizedTitle).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .onChange(of: selectedTab) { newTab in
                if newTab == .translations {
                    appearanceNavPath = NavigationPath()
                }
            }
            .onAppear {
                SegmentedControlStyle.apply(for: colorScheme)
                syncTranslationStateFromUserDefaults()
                migrateLegacyTranslationIdsIfNeeded()
                ensureQuranInArabicDefault()
                if downloadedIds.isEmpty {
                    downloadedIds = ["quran-buck", "en.shakir", "ur.jalandhry"]
                    selectedIds = ["quran-buck", "en.shakir"]
                    persistTranslationState()
                }
                Task {
                    await loadEditionsFromAPI()
                    await loadPhoneticEditionsFromAPI()
                }
            }
            .onDisappear {
                // Ensures selections/downloads are saved when the sheet closes by any path (button, swipe, etc.).
                persistTranslationState()
            }
        }
    }

    /// Appearance tab root: text-style row, scroll speed, audio sync (paywall).
    private var appearanceOverviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("quran_appearance_text_style")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 4)
                    NavigationLink(value: QuranAppearanceRoute.fontAndSize) {
                        HStack {
                            Text("quran_appearance_font_and_size")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("quran_appearance_scroll_speed")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 4)
                    VStack(spacing: 6) {
                        Slider(value: $reciterAyahScrollSpeed, in: 0...1, step: 0.25)
                            .tint(selectedThemeColorManager.selectedColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 14)
                    .background(.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        DummyPaywallPresenter.shared.present()
                    } label: {
                        HStack {
                            Text("quran_appearance_audio_sync_title")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedThemeColorManager.selectedColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    Text("quran_appearance_audio_sync_description")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
    
    private func syncTranslationStateFromUserDefaults() {
        downloadedIds = UserDefaultsManager.shared.quranDownloadedTranslationIds
        selectedIds = UserDefaultsManager.shared.quranSelectedTranslationIds
    }
    
    private func persistTranslationState() {
        UserDefaultsManager.shared.quranDownloadedTranslationIds = downloadedIds
        UserDefaultsManager.shared.quranSelectedTranslationIds = selectedIds
    }

    private func presentTranslationDownloadHintAlert() {
        let icon: AlertIcon = UIImage(systemName: "arrow.down.circle.fill").map { .custom($0) } ?? .done
        AlertKitAPI.present(
            title: NSLocalizedString("quran_translation_download_hint", comment: ""),
            subtitle: nil,
            icon: icon,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    private func presentMaxTranslationsReachedAlert() {
        let icon: AlertIcon = UIImage(systemName: "exclamationmark.circle.fill").map { .custom($0) } ?? .done
        AlertKitAPI.present(
            title: NSLocalizedString("quran_max_translations_reached", comment: ""),
            subtitle: nil,
            icon: icon,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    /// Replace legacy IDs (ar, ur, en) with Al-Quran Cloud edition identifiers.
    private func migrateLegacyTranslationIdsIfNeeded() {
        func migrate(_ ids: [String]) -> [String] {
            ids.map { legacyIdToEditionIdentifier[$0] ?? $0 }
        }
        let newDownloaded = migrate(downloadedIds)
        let newSelected = migrate(selectedIds)
        if newDownloaded != downloadedIds || newSelected != selectedIds {
            downloadedIds = newDownloaded
            selectedIds = newSelected
            persistTranslationState()
        }
    }

    /// Ensure "Quran in Arabic" (quran-buck) is always downloaded and selected; user cannot remove or unselect it.
    private func ensureQuranInArabicDefault() {
        let pin = "quran-buck"
        var changed = false
        if !downloadedIds.contains(pin) {
            downloadedIds.insert(pin, at: 0)
            changed = true
        }
        if !selectedIds.contains(pin) {
            selectedIds.insert(pin, at: 0)
            changed = true
        }
        if changed { persistTranslationState() }
    }

    private func loadEditionsFromAPI() async {
        await MainActor.run { editionsLoading = true }
        do {
            let editions = try await QuranAPIClient.shared.fetchEditions()
            let items = editions
                .filter { allowedEditionIdentifiers.contains($0.identifier) }
                .map { edition -> TranslationItem in
                let flag = languageFlagMap[edition.language] ?? "🌐"
                if edition.identifier == "quran-buck" {
                    return makeQuranInArabicTranslationItem()
                }
                return TranslationItem(
                    translationId: edition.identifier,
                    apiLangCode: edition.language,
                    flag: flag,
                    name: edition.englishName,
                    secondary: edition.name
                )
            }
            await MainActor.run {
                allTranslationItems = items
                editionsLoading = false
            }
        } catch {
            await MainActor.run {
                allTranslationItems = [
                    makeQuranInArabicTranslationItem(),
                    TranslationItem(translationId: "en.shakir", apiLangCode: "en", flag: "🇬🇧", name: "Mohammad Habib Shakir", secondary: "Shakir"),
                    TranslationItem(translationId: "ur.jalandhry", apiLangCode: "ur", flag: "🇵🇰", name: "Fateh Muhammad Jalandhry", secondary: "جالندہری")
                ]
                editionsLoading = false
            }
        }
    }

    private func loadPhoneticEditionsFromAPI() async {
        do {
            let editions = try await QuranAPIClient.shared.fetchTransliterationEditions()
            let items = editions.map { edition -> TranslationItem in
                let flag = languageFlagMap[edition.language] ?? "🌐"
                let (name, secondary): (String, String) = edition.identifier == phoneticOnlyEditionIdentifier
                    ? ("Phonétique - transliteration", "صوتي")
                    : (edition.englishName, edition.name)
                return TranslationItem(
                    translationId: edition.identifier,
                    apiLangCode: edition.language,
                    flag: flag,
                    name: name,
                    secondary: secondary
                )
            }
            await MainActor.run {
                allPhoneticItems = items.filter { $0.translationId == phoneticOnlyEditionIdentifier }
            }
        } catch {
            await MainActor.run {
                allPhoneticItems = [
                    TranslationItem(translationId: phoneticOnlyEditionIdentifier, apiLangCode: "en", flag: "🇬🇧", name: "Phonétique - transliteration", secondary: "صوتي")
                ]
            }
        }
    }
    
    /// Downloaded list ordered by downloadedIds so "Quran in Arabic" stays first and new downloads appear at the end.
    private var downloadedTranslationItems: [TranslationItem] {
        downloadedIds.compactMap { id in
            if id == "quran-buck" {
                return makeQuranInArabicTranslationItem()
            }
            return allTranslationItems.first { $0.translationId == id }
        }
    }
    
    /// Only "Phonétique - transliteration" (en.transliteration) appears in the Phonetic section; other transliterations are in Available/Downloaded.
    private var phoneticTranslationItems: [TranslationItem] {
        allPhoneticItems  // contains only en.transliteration
    }
    
    /// Available translations in the exact order of the reference images; all allowed editions present, none missing.
    private var availableTranslationItems: [TranslationItem] {
        let available = allTranslationItems.filter { !downloadedIds.contains($0.translationId) }
        return available.sorted { a, b in
            let ia = availableTranslationOrder.firstIndex(of: a.translationId) ?? availableTranslationOrder.count
            let ib = availableTranslationOrder.firstIndex(of: b.translationId) ?? availableTranslationOrder.count
            return ia < ib
        }
    }
    
    private var translationsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if editionsLoading && allTranslationItems.isEmpty {
                    ProgressView("Loading translations…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    if !downloadedTranslationItems.isEmpty {
                        translationsSection(
                            title: "quran_downloaded_translations",
                            subtitle: "quran_downloaded_translations_subtitle",
                            items: downloadedTranslationItems,
                            style: .downloaded
                        )
                    }
                    if !phoneticTranslationItems.isEmpty {
                        translationsSection(
                            title: "quran_phonetic",
                            subtitle: nil,
                            items: phoneticTranslationItems,
                            styleForItem: { downloadedIds.contains($0.translationId) ? .phonetic : .available }
                        )
                    }
                    translationsSection(
                        title: "quran_available",
                        subtitle: nil,
                        items: availableTranslationItems,
                        style: .available
                    )
                    Text("quran_translation_download_hint")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    private enum TranslationRowStyle {
        case downloaded  // checkmark if active, else trash
        case phonetic   // trash
        case available  // cloud download
    }
    
    private func translationsSection(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey?,
        items: [TranslationItem],
        style: TranslationRowStyle
    ) -> some View {
        translationsSection(title: title, subtitle: subtitle, items: items, styleForItem: { _ in style })
    }

    private func translationsSection(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey?,
        items: [TranslationItem],
        styleForItem: @escaping (TranslationItem) -> TranslationRowStyle
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    translationRow(item: item, style: styleForItem(item), isSelected: selectedIds.contains(item.translationId))
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(colorScheme == .dark ? Color(uiColor: .secondarySystemGroupedBackground) : Color(uiColor: .systemBackground))
            .cornerRadius(16)
        }
    }
    
    private func translationRow(item: TranslationItem, style: TranslationRowStyle, isSelected: Bool) -> some View {
        let isRowTappable = style == .downloaded || style == .phonetic
        return HStack(alignment: .center, spacing: 14) {
            Text(item.flag)
                .font(.system(size: 28))
                .frame(width: 40, height: 40)
                .background(Color(uiColor: .tertiarySystemFill))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text(item.secondary)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailingIcon(for: item, style: style, isSelected: isSelected)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if defaultTranslationIds.contains(item.translationId) {
                return  // Quran in Arabic: cannot unselect
            }
            if isRowTappable {
                var next = selectedIds
                if next.contains(item.translationId) {
                    next.removeAll { $0 == item.translationId }
                    selectedIds = next
                    UserDefaultsManager.shared.quranLatestSelectedTranslationId = next.last { !defaultTranslationIds.contains($0) } ?? next.last
                    persistTranslationState()
                } else {
                    let countExcludingDefault = next.filter { !defaultTranslationIds.contains($0) }.count
                    if countExcludingDefault >= 2 {
                        presentMaxTranslationsReachedAlert()
                        return
                    }
                    next.append(item.translationId)
                    selectedIds = next
                    UserDefaultsManager.shared.quranLatestSelectedTranslationId = item.translationId
                    persistTranslationState()
                }
            } else if style == .available {
                presentTranslationDownloadHintAlert()
            }
        }
    }
    
    @ViewBuilder
    private func trailingIcon(for item: TranslationItem, style: TranslationRowStyle, isSelected: Bool) -> some View {
        switch style {
        case .downloaded:
            if defaultTranslationIds.contains(item.translationId) {
                Image(systemName: "checkmark")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .frame(width: 22, height: 22)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark" : "")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .blue : Color(UIColor.tertiaryLabel))
                        .frame(width: 22, height: 22)
                    Button {
                        downloadedIds.removeAll { $0 == item.translationId }
                        selectedIds.removeAll { $0 == item.translationId }
                        persistTranslationState()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        case .phonetic:
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark" : "")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : Color(UIColor.tertiaryLabel))
                    .frame(width: 22, height: 22)
                Button {
                    downloadedIds.removeAll { $0 == item.translationId }
                    selectedIds.removeAll { $0 == item.translationId }
                    persistTranslationState()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        case .available:
            Button {
                if !downloadedIds.contains(item.translationId) {
                    downloadedIds.append(item.translationId)
                    persistTranslationState()
                }
            } label: {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var appearanceFontAndSizeDetailContent: some View {
        ScrollView {
            VStack(alignment: .leading){
                VStack(alignment: .leading, spacing: 4){
                    Text("quran_arabic_text_font")
                        .font(.system(size: 14, weight: .bold,design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(quranFontFamilyIds, id: \.self) { font in
                            Button {
                                let freeId = QuranAyahDisplayFont.freeReciterArabicFontFamilyId
                                if font == freeId {
                                    UserDefaultsManager.shared.quranFontFamily = font
                                    selectedFont = font
                                } else if premiumManager.isPremium {
                                    UserDefaultsManager.shared.quranFontFamily = font
                                    selectedFont = font
                                } else {
                                    DummyPaywallPresenter.shared.present()
                                }
                            } label: {
                                HStack {
                                    Text(LocalizedStringKey(localizedQuranFontName(font)))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    Spacer()
                                    if !premiumManager.isPremium, font != QuranAyahDisplayFont.freeReciterArabicFontFamilyId {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(selectedThemeColorManager.selectedColor)
                                    } else if selectedFont == font {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(selectedThemeColorManager.selectedColor)
                                    }
                                }
                                .padding()
                            }
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    .background(.card)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    
                    Text("quran_font_description")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                // Font Size section
                VStack(alignment: .leading, spacing: 8) {
                    Text("quran_font_size")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Slider(value: $fontSize, in: 18...40, step: 3)
                        .padding(.horizontal)
                        .tint(.blue)
                    Text("quran_font_size_description")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 16)
                // Preview section
                VStack(alignment: .leading, spacing: 8) {
                    Text("quran_preview")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    previewBox
                    Text("quran_preview_description")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(.app)
        }
        .onAppear {
            if !premiumManager.isPremium, selectedFont != QuranAyahDisplayFont.freeReciterArabicFontFamilyId {
                let free = QuranAyahDisplayFont.freeReciterArabicFontFamilyId
                UserDefaultsManager.shared.quranFontFamily = free
                selectedFont = free
            }
        }
    }

    private var previewBox: some View {
        let previewText = "إِنَّ الَّذِينَ قَالُوا رَبُّنَا اللَّهُ ثُمَّ اسْتَقَامُوا فَلَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ"
        return Text(previewText)
            .font(previewFont)
            .multilineTextAlignment(.leading)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(colorScheme == .dark ? Color(hex: "#2c2c2e") : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
    }

    private var previewFont: Font {
        if selectedFont == "SF font" {
            return .system(size: fontSize, weight: .regular)
        }
        if selectedFont == QuranAyahDisplayFont.freeReciterArabicFontFamilyId {
            return .custom(QuranAyahDisplayFont.nabiResolvedFontName, size: fontSize)
        }
        let fontNameMap: [String: String] = [
            "Me Quran": "me_quran",
            "PDMS Saleem Quran Font": "PDMS Saleem QuranFont",
            "Al Qalam Quran Majeed Web": "Al Qalam Quran Majeed",
            "Droid Arabic Naskh": "Droid Arabic Naskh",
            "Noto Kufi Arabic": "Noto Kufi Arabic",
            "Noto Naskh Arabic": "Noto Naskh Arabic",
            "Noto Nastaliq Urdu": "Noto Nastaliq Urdu",
            "Scheherazade": "Scheherazade New"
        ]
        let fontName = fontNameMap[selectedFont] ?? selectedFont
        return .custom(fontName, size: fontSize)
    }
}
