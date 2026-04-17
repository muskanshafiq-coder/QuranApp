import SwiftUI

struct AppearanceView: View {

    @EnvironmentObject private var themeManager: ThemeManager

    private var appearanceMode: AppearanceMode {
        themeManager.appearanceMode
    }

    var body: some View {
        VStack(spacing: 20) {

            Toggle(
                "Automatic (System)",
                isOn: Binding(
                    get: { appearanceMode == .auto },
                    set: { isAuto in
                        if isAuto {
                            themeManager.appearanceMode = .auto
                        } else {
                            // Leaving automatic: default to light so the style list matches a sensible selection.
                            if appearanceMode == .auto {
                                themeManager.appearanceMode = .light
                            }
                        }
                    }
                )
            )
            .padding()
            .background(Color.card)
            .cornerRadius(10)
            .toggleStyle(SwitchToggleStyle(tint: .blue))

            if appearanceMode != .auto {
                VStack(alignment: .leading, spacing: 10) {

                    Text("Style")
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        themeRow(title: "Always Light", type: .light)
                        Divider()
                        themeRow(title: "Always Dark", type: .dark)
                    }
                    .background(Color.card)
                    .cornerRadius(12)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.app)
    }
}

extension AppearanceView {
    func themeRow(title: String, type: AppearanceMode) -> some View {
        Button {
            themeManager.appearanceMode = type
        } label: {
            HStack {
                Text(title)

                Spacer()

                if appearanceMode == type {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
