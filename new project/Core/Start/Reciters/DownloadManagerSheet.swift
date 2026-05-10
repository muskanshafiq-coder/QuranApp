//
//  DownloadManagerSheet.swift
//

import SwiftUI

struct DownloadManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DownloadManagerViewModel()

    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    overallSection
                    perReciterSection
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Color.app.ignoresSafeArea())
            .navigationTitle("download_manager_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(Circle().fill(Color.card))
                    }
                    .accessibilityLabel(Text("alert_cancel"))
                }
            }
            .alert(
                "download_manager_delete_confirm_title",
                isPresented: $showDeleteConfirmation
            ) {
                Button("alert_cancel", role: .cancel) {}
                Button("download_manager_delete_now", role: .destructive) {
                    viewModel.clearAllDownloads()
                }
            } message: {
                Text("download_manager_delete_confirm_message")
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var overallSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("download_manager_section_overall")

            VStack(spacing: 0) {
                infoRow(
                    titleKey: "download_manager_downloaded_data",
                    trailing: viewModel.formattedTotalSize
                )
                Divider()
                    .padding(.horizontal, 16)
                deleteRow(enabled: viewModel.hasDownloads) {
                    showDeleteConfirmation = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.card)
            )

            footerNote("download_manager_overall_footnote")
        }
    }

    private var perReciterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("download_manager_section_by_reciter")

            if viewModel.perReciter.isEmpty {
                emptyReciterCard
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.perReciter.enumerated()), id: \.element.id) { index, item in
                        reciterRow(item)
                        if index < viewModel.perReciter.count - 1 {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.card)
                )
            }

            footerNote("download_manager_by_reciter_footnote")
        }
    }

    // MARK: - Building blocks

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .padding(.horizontal, 4)
    }

    private func footerNote(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
            .padding(.top, 2)
    }

    private func infoRow(titleKey: LocalizedStringKey, trailing: String) -> some View {
        HStack {
            Text(titleKey)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.primary)
            Spacer()
            Text(trailing)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func deleteRow(enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text("download_manager_delete_now")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(enabled ? Color.red : Color.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var emptyReciterCard: some View {
        Text("download_manager_no_downloads")
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.card)
            )
    }

    private func reciterRow(_ item: DownloadManagerReciterEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.reciterName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(item.formattedSize)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                viewModel.removeDownloads(forReciterId: item.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.red)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("download_manager_remove_reciter"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
