import SwiftUI

private enum AppState {
    @MainActor static let settingsViewModel = SettingsViewModel()
}

@main
struct FilePopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settingsViewModel = AppState.settingsViewModel

    init() {
        DispatchQueue.main.async {
            let viewModel = AppState.settingsViewModel
            if !viewModel.settings.hasCompletedOnboarding {
                WindowManager.shared.showOnboarding(viewModel: viewModel)
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            Button(L10n.t(.openSettings)) {
                WindowManager.shared.showSettings(viewModel: settingsViewModel)
            }

            Picker(L10n.t(.creationMode), selection: Binding(
                get: { settingsViewModel.creationMode },
                set: { settingsViewModel.creationMode = $0 }
            )) {
                ForEach(CreationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            Divider()

            Button(L10n.t(.showGuide)) {
                WindowManager.shared.showOnboarding(viewModel: settingsViewModel)
            }

            Button(L10n.t(.quit)) {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
                .resizable()
                .frame(width: 18, height: 18)
                .accessibilityLabel(Text(AppConstants.appName))
        }
        .menuBarExtraStyle(.menu)
    }
}
