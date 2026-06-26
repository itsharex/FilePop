import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            for url in urls {
                CommandHandler.shared.handle(url: url)
            }
        }
    }
}
