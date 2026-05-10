//
//  PlaylistPickerSheet.swift
//  new project
//
//  Sheet wrapper that hosts `PlaylistsView` in `.picker` mode so callers
//  (e.g. the surah row "Add to a Playlist…" flow) can let the user select
//  an existing playlist or create a new one in place.
//

import SwiftUI

struct PlaylistPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (Playlist) -> Void

    var body: some View {
        NavigationStack {
            PlaylistsView(mode: .picker) { playlist in
                onSelect(playlist)
                dismiss()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("alert_cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
