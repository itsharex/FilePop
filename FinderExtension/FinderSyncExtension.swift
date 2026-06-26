import AppKit
import FinderSync

private final class TemplateMenuPayload: NSObject {
    let template: FileTemplate

    init(template: FileTemplate) {
        self.template = template
    }
}

final class FinderSyncExtension: FIFinderSync {
    private var settings: FilePopSettings {
        SettingsRepository.shared.load()
    }

    override init() {
        super.init()
        let directoryURLs = monitoredDirectoryURLs()
        FIFinderSyncController.default().directoryURLs = directoryURLs
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu()
        let currentSettings = settings

        switch currentSettings.creationMode {
        case .manualSuffix:
            menu.addItem(makeItem(
                title: L10n.t(.newFile),
                action: #selector(createManualFile)
            ))
        case .templatePicker:
            let newFileItem = NSMenuItem(title: L10n.t(.newFile), action: nil, keyEquivalent: "")
            newFileItem.image = nil
            newFileItem.view = nil

            let submenu = NSMenu(title: L10n.t(.newFile))
            submenu.autoenablesItems = false

            for template in currentSettings.templates
                .filter(\.enabled)
                .sorted(by: { $0.order < $1.order }) {
                let item = makeItem(
                    title: template.menuTitle,
                    action: #selector(createTemplateFile(_:))
                )
                item.representedObject = TemplateMenuPayload(template: template)
                item.identifier = NSUserInterfaceItemIdentifier(template.id.uuidString)
                item.tag = template.order
                item.isEnabled = true
                submenu.addItem(item)
            }

            newFileItem.submenu = submenu
            menu.addItem(newFileItem)
        }

        menu.addItem(makeItem(
            title: L10n.t(.openTerminalHere),
            action: #selector(openTerminalHere)
        ))

        menu.addItem(makeItem(
            title: L10n.t(.copyFolderPath),
            action: #selector(copyFolderPath)
        ))

        return menu
    }

    private func makeItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = nil
        item.view = nil
        return item
    }

    @objc private func createManualFile() {
        FilePopDebugLogger.log("Extension manual command invoked")
        dispatch(.manualFile)
    }

    @objc private func createTemplateFile(_ sender: NSMenuItem) {
        guard let template = template(from: sender) else {
            FilePopDebugLogger.log("Extension template command failed: missing template payload")
            return
        }

        FilePopDebugLogger.log("Extension template command invoked: \(template.menuTitle)")
        dispatch(.templateFile, template: template)
    }

    @objc private func openTerminalHere() {
        dispatch(.openTerminal)
    }

    @objc private func copyFolderPath() {
        dispatch(.copyPath)
    }

    private func currentDirectoryURL() -> URL? {
        let controller = FIFinderSyncController.default()

        if let targetedURL = controller.targetedURL() {
            return directoryURL(for: targetedURL)
        }

        if let selectedURL = controller.selectedItemURLs()?.first {
            return directoryURL(for: selectedURL)
        }

        return nil
    }

    private func directoryURL(for url: URL) -> URL {
        if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            return url
        }

        return url.deletingLastPathComponent()
    }

    private func template(from item: NSMenuItem) -> FileTemplate? {
        if let payload = item.representedObject as? TemplateMenuPayload {
            return payload.template
        }

        let availableTemplates = settings.templates
            .filter(\.enabled)
            .sorted(by: { $0.order < $1.order })

        if
            let idString = item.identifier?.rawValue,
            let templateID = UUID(uuidString: idString),
            let template = availableTemplates.first(where: { $0.id == templateID })
        {
            return template
        }

        return availableTemplates.first(where: { $0.order == item.tag })
    }

    private func dispatch(_ action: FilePopCommandAction, template: FileTemplate? = nil) {
        guard let directoryURL = currentDirectoryURL() else {
            FilePopDebugLogger.log("Extension dispatch failed action=\(action.rawValue): missing Finder directory")
            return
        }

        FilePopDebugLogger.log("Extension dispatch action=\(action.rawValue) directory=\(directoryURL.path)")
        openMainApp(action: action, directoryPath: directoryURL.path, template: template)
    }

    private func openMainApp(action: FilePopCommandAction, directoryPath: String, template: FileTemplate?) {
        var components = URLComponents()
        components.scheme = AppConstants.urlScheme
        components.host = "command"

        var queryItems = [
            URLQueryItem(name: "id", value: UUID().uuidString),
            URLQueryItem(name: "action", value: action.rawValue),
            URLQueryItem(name: "directory", value: directoryPath)
        ]

        if let template {
            queryItems.append(URLQueryItem(name: "templateID", value: template.id.uuidString))
            queryItems.append(URLQueryItem(name: "templateName", value: template.displayName))
            queryItems.append(URLQueryItem(name: "templateExtension", value: template.fileExtension))
            queryItems.append(URLQueryItem(name: "templateKind", value: template.kind.rawValue))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            FilePopDebugLogger.log("Extension dispatch failed action=\(action.rawValue): invalid URL")
            return
        }

        FilePopDebugLogger.log("Extension open URL=\(url.absoluteString)")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url.absoluteString]

        do {
            try process.run()
            if let template {
                FilePopDebugLogger.log("Extension command dispatched action=\(action.rawValue) template=\(template.menuTitle) directory=\(directoryPath)")
            } else {
                FilePopDebugLogger.log("Extension command dispatched action=\(action.rawValue) directory=\(directoryPath)")
            }
        } catch {
            FilePopDebugLogger.log("Extension failed to open main app: \(error.localizedDescription)")
        }
    }

    private func monitoredDirectoryURLs() -> Set<URL> {
        var urls: Set<URL> = [
            URL(fileURLWithPath: "/", isDirectory: true),
            URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        ]

        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        if let volumes = try? FileManager.default.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for volume in volumes {
                urls.insert(volume)
            }
        }

        return urls
    }
}
