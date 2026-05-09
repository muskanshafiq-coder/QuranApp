//
//  PlayerAllRecitersView.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import SwiftUI

/// Segments shown in the principal toolbar of `PlayerAllRecitersView`.
enum ReciterListSegment: String, CaseIterable, Identifiable {
    case mostPopular
    case favorites

    var id: String { rawValue }

    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .mostPopular: return "reciters_segment_most_popular"
        case .favorites:   return "reciters_segment_favorites"
        }
    }
}

struct PlayerAllRecitersView: View {
    let reciters: [PlayerReciterDisplayItem]
    @Binding var preferredReciterId: String

    @State private var searchText = ""
    @State private var selectedSegment: ReciterListSegment = .mostPopular

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Adaptive grid: 3 columns on iPhone, 5 on iPad / regular width.
    private var gridColumns: [GridItem] {
        let count = (horizontalSizeClass == .regular) ? 5 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    /// Reciters available in the current segment (before search filtering).
    private var segmentReciters: [PlayerReciterDisplayItem] {
        switch selectedSegment {
        case .mostPopular:
            return reciters
        case .favorites:
            // TODO: Replace with persisted favorites once that store exists.
            return []
        }
    }

    private var filtered: [PlayerReciterDisplayItem] {
        let base = segmentReciters
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.englishName.localizedCaseInsensitiveContains(q)
                || $0.arabicDisplayName?.contains(q) == true
        }
    }

    var body: some View {
        Group {
            if filtered.isEmpty && selectedSegment == .favorites {
                emptyFavoritesState
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 14) {
                        ForEach(filtered) { item in
                            NavigationLink(
                                destination: PlayerReciterSurahListView(
                                    reciter: item,
                                    preferredReciterId: $preferredReciterId
                                )
                            ) {
                                PlayerReciterAvatarCell(
                                    item: item,
                                    diameter: 112,
                                    isSelected: preferredReciterId == item.id,
                                    onSelect: nil
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                segmentPicker
            }
        }
        .background(Color.app.ignoresSafeArea())
    }

    private var segmentPicker: some View {
        Picker(selection: $selectedSegment) {
            ForEach(ReciterListSegment.allCases) { segment in
                Text(segment.localizedTitleKey).tag(segment)
            }
        } label: {
            Text("reciters_segment_picker_label")
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var emptyFavoritesState: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            Text("reciters_favorites_empty_title")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.55))
                .multilineTextAlignment(.center)
            Text("reciters_favorites_empty_subtitle")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.35))
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

// MARK: - iOS compatibility

private extension View {
    /// Dark blurred glass navigation bar.
    /// `.toolbarBackground(.visible, ...)` forces the bar to always be visible (not just on scroll),
    /// `.ultraThinMaterial` gives the blur you see in the reference.
    @ViewBuilder
    func glassNavigationBar() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            self
        }
    }

    @ViewBuilder
    func playerSearchable(text: Binding<String>, prompt: String) -> some View {
        if #available(iOS 16.0, *) {
            searchable(text: text, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(prompt))
        } else {
            searchable(text: text, prompt: Text(prompt))
        }
    }
}
