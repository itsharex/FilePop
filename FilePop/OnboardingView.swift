import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t(.onboardingTitle))
                    .font(.system(size: 30, weight: .semibold))
                Text(L10n.t(.onboardingBody))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.t(.onboardingStepOne))
                Text(L10n.t(.onboardingStepTwo))
                Text(L10n.t(.onboardingStepThree))
            }
            .font(.body)

            Toggle(L10n.t(.launchAtLogin), isOn: Binding(
                get: { viewModel.launchAtLogin },
                set: { viewModel.launchAtLogin = $0 }
            ))

            Spacer()

            HStack {
                Button {
                    openExtensionSettings()
                } label: {
                    Label(L10n.t(.openExtensionSettings), systemImage: "puzzlepiece.extension")
                }

                Spacer()

                Button(L10n.t(.finishOnboarding)) {
                    onFinish()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(minWidth: 560, minHeight: 360)
    }

    private func openExtensionSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.ExtensionsPreferences",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Extensions"
        ]

        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
