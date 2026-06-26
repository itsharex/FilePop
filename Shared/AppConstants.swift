import Foundation

enum AppConstants {
    static let appName = "FilePop"
    static let appGroupIdentifier = "group.com.filepop.app"
    static let extensionBundleIdentifier = "com.filepop.FilePop.FinderExtension"
    static let settingsJSONKey = "FilePopSettingsJSON"
    static let urlScheme = "filepop"
}

enum FilePopDebugLogger {
    static func log(_ message: String) {
        let normalizedMessage = message.hasPrefix("FilePopDebug")
            ? message
            : "FilePopDebug \(message)"

        NSLog("%@", normalizedMessage)
    }
}
