import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var settings: FilePopSettings
    @Published var lastErrorMessage: String?

    init(repository: SettingsRepository = .shared) {
        self.repository = repository
        self.settings = repository.load()
    }

    private let repository: SettingsRepository

    var creationMode: CreationMode {
        get { settings.creationMode }
        set {
            settings.creationMode = newValue
            persist()
        }
    }

    var templates: [FileTemplate] {
        settings.templates.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
            }

            return lhs.order < rhs.order
        }
    }

    var launchAtLogin: Bool {
        get { settings.launchAtLogin }
        set {
            do {
                try LoginItemManager.setEnabled(newValue)
                settings.launchAtLogin = newValue
                persist()
            } catch {
                lastErrorMessage = L10n.t(.loginItemError)
            }
        }
    }

    var externalVolumeIntegrationEnabled: Bool {
        get { settings.externalVolumeIntegrationEnabled }
        set {
            settings.externalVolumeIntegrationEnabled = newValue
            persist()
        }
    }

    func addTemplate(displayName: String, fileExtension: String) {
        let nextOrder = (settings.templates.map(\.order).max() ?? -1) + 1
        let template = FileTemplate(
            displayName: displayName,
            fileExtension: fileExtension,
            order: nextOrder
        )
        settings.templates.append(template)
        persist()
    }

    func updateTemplate(_ template: FileTemplate, displayName: String, fileExtension: String, enabled: Bool) {
        guard let index = settings.templates.firstIndex(where: { $0.id == template.id }) else {
            return
        }

        settings.templates[index].displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.templates[index].fileExtension = FileTemplate.normalizedExtension(fileExtension)
        settings.templates[index].kind = FileTemplate.kind(for: fileExtension)
        settings.templates[index].enabled = enabled
        persist()
    }

    func setTemplateEnabled(_ template: FileTemplate, enabled: Bool) {
        guard let index = settings.templates.firstIndex(where: { $0.id == template.id }) else {
            return
        }

        settings.templates[index].enabled = enabled
        persist()
    }

    func deleteTemplate(_ template: FileTemplate) {
        settings.templates.removeAll { $0.id == template.id }
        normalizeTemplateOrder()
        persist()
    }

    func moveTemplate(_ template: FileTemplate, direction: Int) {
        var sortedTemplates = templates
        guard
            let index = sortedTemplates.firstIndex(where: { $0.id == template.id }),
            sortedTemplates.indices.contains(index + direction)
        else {
            return
        }

        sortedTemplates.swapAt(index, index + direction)
        for index in sortedTemplates.indices {
            sortedTemplates[index].order = index
        }
        settings.templates = sortedTemplates
        persist()
    }

    func resetTemplates() {
        settings.templates = FileTemplate.defaultTemplates
        persist()
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        persist()
    }

    private func normalizeTemplateOrder() {
        var sortedTemplates = templates
        for index in sortedTemplates.indices {
            sortedTemplates[index].order = index
        }
        settings.templates = sortedTemplates
    }

    private func persist() {
        repository.save(settings)
        DistributedNotificationCenter.default().post(
            name: AppConstants.settingsDidChangeNotification,
            object: AppConstants.appName
        )
    }
}
