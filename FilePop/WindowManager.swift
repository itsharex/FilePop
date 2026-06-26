import AppKit
import SwiftUI

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    private init() {}

    func showSettings(viewModel: SettingsViewModel) {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = L10n.t(.settingsTitle)
            settingsWindow?.contentView = NSHostingView(
                rootView: SettingsView()
                    .environmentObject(viewModel)
            )
            settingsWindow?.center()
        }

        show(window: settingsWindow)
    }

    func showOnboarding(viewModel: SettingsViewModel) {
        if onboardingWindow == nil {
            onboardingWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            onboardingWindow?.title = L10n.t(.onboarding)
            onboardingWindow?.contentView = NSHostingView(
                rootView: OnboardingView {
                    viewModel.completeOnboarding()
                    self.onboardingWindow?.close()
                }
                .environmentObject(viewModel)
            )
            onboardingWindow?.center()
        }

        show(window: onboardingWindow)
    }

    private func show(window: NSWindow?) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
