import Foundation

struct FilePopSettings: Codable, Equatable {
    var creationMode: CreationMode
    var templates: [FileTemplate]
    var hasCompletedOnboarding: Bool
    var launchAtLogin: Bool
    var externalVolumeIntegrationEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case creationMode
        case templates
        case hasCompletedOnboarding
        case launchAtLogin
        case externalVolumeIntegrationEnabled
    }

    init(
        creationMode: CreationMode,
        templates: [FileTemplate],
        hasCompletedOnboarding: Bool,
        launchAtLogin: Bool,
        externalVolumeIntegrationEnabled: Bool
    ) {
        self.creationMode = creationMode
        self.templates = templates
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.launchAtLogin = launchAtLogin
        self.externalVolumeIntegrationEnabled = externalVolumeIntegrationEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creationMode = try container.decode(CreationMode.self, forKey: .creationMode)
        templates = try container.decode([FileTemplate].self, forKey: .templates)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        launchAtLogin = try container.decode(Bool.self, forKey: .launchAtLogin)
        externalVolumeIntegrationEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .externalVolumeIntegrationEnabled
        ) ?? false
    }

    static var defaults: FilePopSettings {
        FilePopSettings(
            creationMode: .manualSuffix,
            templates: FileTemplate.defaultTemplates,
            hasCompletedOnboarding: false,
            launchAtLogin: false,
            externalVolumeIntegrationEnabled: false
        )
    }
}
