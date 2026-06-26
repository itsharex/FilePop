import Foundation

struct FilePopSettings: Codable, Equatable {
    var creationMode: CreationMode
    var templates: [FileTemplate]
    var hasCompletedOnboarding: Bool
    var launchAtLogin: Bool

    static var defaults: FilePopSettings {
        FilePopSettings(
            creationMode: .manualSuffix,
            templates: FileTemplate.defaultTemplates,
            hasCompletedOnboarding: false,
            launchAtLogin: false
        )
    }
}
