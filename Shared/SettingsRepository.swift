import Foundation

final class SettingsRepository {
    static let shared = SettingsRepository()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> FilePopSettings {
        if let settings = loadFromSharedDefaults() {
            return settings
        }

        if let settings = loadFromApplicationSupport() {
            save(settings)
            return settings
        }

        let defaults = FilePopSettings.defaults
        save(defaults)
        return defaults
    }

    func save(_ settings: FilePopSettings) {
        guard let data = try? encoder.encode(settings) else {
            return
        }

        if let json = String(data: data, encoding: .utf8) {
            sharedDefaults.set(json, forKey: AppConstants.settingsJSONKey)
        }

        do {
            try FileManager.default.createDirectory(
                at: settingsDirectoryURL,
                withIntermediateDirectories: true
            )
            try data.write(to: settingsFileURL, options: .atomic)
        } catch {
            FilePopDebugLogger.log("failed to persist settings: \(error.localizedDescription)")
        }
    }

    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? .standard
    }

    private var settingsDirectoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent(AppConstants.appName, isDirectory: true)
    }

    private var settingsFileURL: URL {
        settingsDirectoryURL.appendingPathComponent("settings.json")
    }

    private func loadFromSharedDefaults() -> FilePopSettings? {
        guard
            let json = sharedDefaults.string(forKey: AppConstants.settingsJSONKey),
            let data = json.data(using: .utf8)
        else {
            return nil
        }

        return try? decoder.decode(FilePopSettings.self, from: data)
    }

    private func loadFromApplicationSupport() -> FilePopSettings? {
        guard let data = try? Data(contentsOf: settingsFileURL) else {
            return nil
        }

        return try? decoder.decode(FilePopSettings.self, from: data)
    }
}
