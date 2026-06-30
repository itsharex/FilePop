import AppKit
import SwiftUI

@MainActor
final class WindowManager: NSObject, NSWindowDelegate {
    static let shared = WindowManager()

    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    private override init() {
        super.init()
    }

    func showSettings(viewModel: SettingsViewModel) {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.title = L10n.t(.settingsTitle)
            window.contentView = NSHostingView(
                rootView: SettingsView()
                    .environmentObject(viewModel)
            )
            window.center()
            settingsWindow = window
        }

        show(window: settingsWindow)
    }

    func showOnboarding(viewModel: SettingsViewModel) {
        if onboardingWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.title = L10n.t(.onboarding)
            window.contentView = NSHostingView(
                rootView: OnboardingView {
                    viewModel.completeOnboarding()
                    self.onboardingWindow?.close()
                }
                .environmentObject(viewModel)
            )
            window.center()
            onboardingWindow = window
        }

        show(window: onboardingWindow)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }

        if window === settingsWindow {
            settingsWindow = nil
        } else if window === onboardingWindow {
            onboardingWindow = nil
        }
    }

    private func show(window: NSWindow?) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
