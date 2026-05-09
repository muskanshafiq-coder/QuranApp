//
//  PlaylistOptionsSheet.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import SwiftUI

struct PlaylistOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accentColor: Color
    let onReorder: () -> Void
    let onShare: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                sheetRow(
                    titleKey: "playlist_sheet_reorder",
                    systemImage: "list.number",
                    action: {
                        dismiss()
                        onReorder()
                    }
                )
                sheetRow(
                    titleKey: "playlist_sheet_share",
                    systemImage: "square.and.arrow.up",
                    action: {
                        onShare()
                    }
                )
                sheetRow(
                    titleKey: "playlist_sheet_rename",
                    systemImage: "pencil",
                    action: {
                        dismiss()
                        onRename()
                    }
                )
                sheetRowDestructive(
                    titleKey: "playlist_sheet_delete",
                    systemImage: "trash",
                    action: {
                        dismiss()
                        onDelete()
                    }
                )
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .background(Color.app.ignoresSafeArea())
            .navigationTitle("playlist_sheet_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }

                }
            }
        }
    }

    private func sheetRow( titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
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
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.card)
            )
        }
        .buttonStyle(.plain)
    }

    private func sheetRowDestructive( titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
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
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red)
            )
        }
        .buttonStyle(.plain)
    }
}
