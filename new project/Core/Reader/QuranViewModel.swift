//
//  QuranViewModel.swift
//  Quran App
//
//  Loads surahs, Juz/Hizb/Rubu, and Sajdas from Al-Quran Cloud API.
//

import Combine
import Foundation
import SwiftUI

private let previewSurahsCount = 5
private let previewJuzHizbCount = 5
private let previewSajdasCount = 5

final class QuranViewModel: ObservableObject {
    @Published private(set) var loading = false
    @Published private(set) var surahs: [SurahItem] = []
    @Published private(set) var juzHizbRubuItems: [JuzHizbRubuItem] = []
    @Published private(set) var sajdaItems: [SajdaDisplayItem] = []
    @Published var continueReadingProgress: ReadingProgress?
    @Published var continueReadingSurah: SurahItem?
    
    var previewSurahs: [SurahItem] {
        Array(surahs.prefix(previewSurahsCount))
    }
    
    var previewJuzHizbRubu: [JuzHizbRubuItem] {
        Array(juzHizbRubuItems.prefix(previewJuzHizbCount))
    }
    
    var previewSajdas: [SajdaDisplayItem] {
        Array(sajdaItems.prefix(previewSajdasCount))
    }
    
    var hasMoreSuras: Bool { surahs.count > previewSurahsCount }
    var hasMoreJuzHizbRubu: Bool { juzHizbRubuItems.count > previewJuzHizbCount }
    var hasMoreSajdas: Bool { sajdaItems.count > previewSajdasCount }
    
    init() {
        Task { await loadAll() }
    }
    
    func refreshProgressFromStorage() {
        let progress = UserDefaultsManager.shared.getQuranReadingProgress()
        continueReadingProgress = progress
        if let p = progress, let surah = surahs.first(where: { $0.number == p.surahNumber }) {
            continueReadingSurah = surah
        } else if continueReadingSurah == nil, let first = surahs.first {
            continueReadingSurah = first
            continueReadingProgress = ReadingProgress(
                surahNumber: first.number,
                ayahNumber: 2,
                juz: 1,
                hizbQuarter: 1
            )
        }
    }
    
    func updateContinueReading(surah: SurahItem, progress: ReadingProgress) {
        continueReadingSurah = surah
        continueReadingProgress = progress
    }
    
    private func loadAll() async {
        await MainActor.run { loading = true }
        defer { Task { @MainActor in loading = false } }
        
        do {
            let meta = try await QuranAPIClient.shared.fetchMetaFull()
            let loadedSurahs = meta.surahs.references.map { $0.toSurahItem() }
            await MainActor.run {
                surahs = loadedSurahs
                refreshProgressFromStorage()
            }
            
            if let hizb = meta.hizbQuarters {
                await loadJuzHizbRubu(references: hizb.references, surahs: loadedSurahs)
            }
            
            Task {
                do {
                    let meta = try await QuranAPIClient.shared.fetchMetaFull()
                    if let sajdas = meta.sajdas {
                        await loadSajdas(references: sajdas.references, surahs: loadedSurahs)
                    }
                } catch { }
            }
        } catch {
            // Keep loading false; surahs may be empty
        }
    }
    
    private func loadJuzHizbRubu(references: [HizbQuarterRef], surahs: [SurahItem]) async {
        let nameByNumber: [Int: String] = Dictionary(uniqueKeysWithValues: surahs.map { ($0.number, $0.nameEnglish) })
        var items: [JuzHizbRubuItem] = []
        for (idx, ref) in references.enumerated() {
            let index = idx + 1
            let juzNumber = (index - 1) / 8 + 1
            let name = nameByNumber[ref.surah] ?? "Surah \(ref.surah)"
            items.append(JuzHizbRubuItem(
                id: index,
                index: index,
                juzNumber: juzNumber,
                surahNumber: ref.surah,
                ayahNumber: ref.ayah,
                surahNameEnglish: name,
                arabicText: ""
            ))
        }
        await MainActor.run { juzHizbRubuItems = items }
        
        for (i, item) in items.enumerated() {
            do {
                let text = try await QuranAPIClient.shared.getVerseText(
                    surahNumber: item.surahNumber,
                    ayahNumber: item.ayahNumber,
                    surahNameEnglish: item.surahNameEnglish
                )
                await MainActor.run {
                    if i < juzHizbRubuItems.count {
                        var updated = juzHizbRubuItems
                        let old = updated[i]
                        updated[i] = JuzHizbRubuItem(
                            id: old.id,
                            index: old.index,
                            juzNumber: old.juzNumber,
                            surahNumber: old.surahNumber,
                            ayahNumber: old.ayahNumber,
                            surahNameEnglish: old.surahNameEnglish,
                            arabicText: text
                        )
                        juzHizbRubuItems = updated
                    }
                }
            } catch { }
        }
    }
    
    private func loadSajdas(references: [SajdaRef], surahs: [SurahItem]) async {
        let nameByNumber: [Int: String] = Dictionary(uniqueKeysWithValues: surahs.map { ($0.number, $0.nameEnglish) })
        var items: [SajdaDisplayItem] = []
        for (idx, ref) in references.enumerated() {
            let name = nameByNumber[ref.surah] ?? "Surah \(ref.surah)"
            items.append(SajdaDisplayItem(
                id: idx + 1,
                index: idx + 1,
                surahNumber: ref.surah,
                ayahNumber: ref.ayah,
                surahNameEnglish: name,
                arabicText: "",
                recommended: ref.recommended,
                obligatory: ref.obligatory
            ))
        }
        // Fetch verse text for each item before showing the list so Arabic is visible
        for i in items.indices {
            do {
                let text = try await QuranAPIClient.shared.getVerseText(
                    surahNumber: items[i].surahNumber,
                    ayahNumber: items[i].ayahNumber,
                    surahNameEnglish: items[i].surahNameEnglish
                )
                items[i] = SajdaDisplayItem(
                    id: items[i].id,
                    index: items[i].index,
                    surahNumber: items[i].surahNumber,
                    ayahNumber: items[i].ayahNumber,
                    surahNameEnglish: items[i].surahNameEnglish,
                    arabicText: text,
                    recommended: items[i].recommended,
                    obligatory: items[i].obligatory
                )
            } catch { }
        }
        await MainActor.run { sajdaItems = items }
    }
}
