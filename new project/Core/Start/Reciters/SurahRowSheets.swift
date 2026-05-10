//
//  SurahRowSheets.swift
//  new project
//
//  Bottom sheet: surah actions (playlist / bookmark / play next / share) and
//  nested playlist picker. Styling follows the reference (dark card, red primary).
//

import SwiftUI

struct SurahOptionsFlowSheet: View {
    let surahRow: PlayerSurahRowModel
    let accentColor: Color

    @ObservedObject private var playlistsViewModel = PlaylistsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showPlaylistPicker = false
    @State private var showAddPlaylistAlert = false
    @State private var newPlaylistName = ""

    let onAddBookmark: () -> Void
    let onPlayNext: () -> Void
    let onShare: () -> Void
    let onPlaylistChosen: (Playlist) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if showPlaylistPicker {
                    playlistPickerBody
                } else {
                    optionsBody
                }
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .background(Color.app.ignoresSafeArea())
            .navigationTitle(showPlaylistPicker ? "playlists_title" : "surah_options_nav_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if showPlaylistPicker {
                            showPlaylistPicker = false
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                if showPlaylistPicker {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            newPlaylistName = ""
                            showAddPlaylistAlert = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel(Text("playlist_add_button_accessibility"))
                    }
                }
            }
            .alert("playlist_alert_title", isPresented: $showAddPlaylistAlert) {
                TextField("playlist_alert_placeholder", text: $newPlaylistName)
                Button("alert_cancel", role: .cancel) {
                    newPlaylistName = ""
                }
                Button("playlist_alert_add") {
                    let name = newPlaylistName
                    newPlaylistName = ""
                    if playlistsViewModel.addPlaylist(named: name) {
                        PlaylistSuccessFeedback.presentPlaylistCreated()
                    }
                }
            } message: {
                Text("playlist_alert_message")
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Options (first screen)

    private var optionsBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(surahRow.englishLine)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black)
                    .frame(height: 160)
                    .overlay(
                        Text("surah_options_media_placeholder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    )

                primaryOptionButton(
                    titleKey: "surah_options_add_playlist",
                    systemImage: "music.note.list",
                    background: accentColor
                ) {
                    showPlaylistPicker = true
                }

                secondaryOptionButton(titleKey: "surah_options_add_bookmark", systemImage: "bookmark") {
                    dismiss()
                    onAddBookmark()
                }

                secondaryOptionButton(titleKey: "surah_options_play_next", systemImage: "text.line.first.and.arrowtriangle.forward") {
                    dismiss()
                    onPlayNext()
                }

                secondaryOptionButton(titleKey: "surah_options_share_surah", systemImage: "square.and.arrow.up") {
                    dismiss()
                    onShare()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func primaryOptionButton(titleKey: LocalizedStringKey, systemImage: String, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 28)
                Text(titleKey)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(background))
        }
        .buttonStyle(.plain)
    }

    private func secondaryOptionButton(titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 28)
                Text(titleKey)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Playlist picker

    @ViewBuilder
    private var playlistPickerBody: some View {
        if playlistsViewModel.playlists.isEmpty {
            VStack(spacing: 12) {
                Spacer(minLength: 40)
                Text("playlists_empty_title")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("playlists_empty_subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        } else {
            List {
                ForEach(playlistsViewModel.playlists) { playlist in
                    Button {
                        onPlaylistChosen(playlist)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playlist.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(surahCountText(for: playlist))
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.card)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func surahCountText(for playlist: Playlist) -> String {
        switch playlist.surahCount {
        case 0: return String(localized: "playlist_surah_count_zero")
        case 1: return String(localized: "playlist_surah_count_one")
        default:
            return String(format: NSLocalizedString("playlist_surah_count_other", comment: ""), playlist.surahCount)
        }
    }
}
