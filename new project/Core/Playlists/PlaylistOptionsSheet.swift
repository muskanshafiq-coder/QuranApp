//
//  PlaylistOptionsSheet.swift
//

import SwiftUI
import UIKit

struct PlaylistOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let accentColor: Color
    let onReorder: () -> Void
    let onShare: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    private var sheetBackground: Color {
        Color(UIColor.systemGroupedBackground)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(sheetBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("playlist_sheet_title")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .toolbarBackground(sheetBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
