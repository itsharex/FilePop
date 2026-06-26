import AppKit
import ApplicationServices
import Carbon.HIToolbox

private enum FilePopDebug {
    static func log(_ message: String) {
        FilePopDebugLogger.log(message)
    }

    static func frontmostApplicationDescription() -> String {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return "nil"
        }

        return "\(app.localizedName ?? "unknown") [\(app.bundleIdentifier ?? "nil")] pid=\(app.processIdentifier)"
    }
}

@MainActor
private enum KeyboardInputSourceSwitcher {
    static func selectEnglishInputSource(traceID: String) async {
        FilePopDebug.log("[\(traceID)] input before: \(currentInputSourceDescription())")

        if isCurrentInputSourceASCIICapable() {
            FilePopDebug.log("[\(traceID)] input already ASCII-capable; skip shortcut")
            return
        }

        FilePopDebug.log("[\(traceID)] input shortcut CapsLock begin")
        await postInputSourceSwitchShortcut()
        let switched = await waitForASCIICapableInputSource()
        FilePopDebug.log("[\(traceID)] input shortcut end switched=\(switched) after: \(currentInputSourceDescription())")
    }

    private static func postInputSourceSwitchShortcut() async {
        let source = CGEventSource(stateID: .hidSystemState)
        let capsLockKeyCode: CGKeyCode = 57

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: capsLockKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: capsLockKeyCode, keyDown: false)

        if keyDown == nil || keyUp == nil {
            FilePopDebug.log("input shortcut event creation failed")
        }

        keyDown?.flags = []
        keyUp?.flags = []

        keyDown?.post(tap: .cghidEventTap)
        try? await Task.sleep(nanoseconds: 50_000_000)
        keyUp?.post(tap: .cghidEventTap)
    }

    private static func isCurrentInputSourceASCIICapable() -> Bool {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return false
        }

        return boolProperty(inputSource, kTISPropertyInputSourceIsASCIICapable) == true
    }

    private static func waitForASCIICapableInputSource() async -> Bool {
        for _ in 0..<5 {
            try? await Task.sleep(nanoseconds: 60_000_000)
            if isCurrentInputSourceASCIICapable() {
                return true
            }
        }

        return false
    }

    private static func currentInputSourceDescription() -> String {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return "nil"
        }

        let id = stringProperty(inputSource, kTISPropertyInputSourceID) ?? "nil"
        let name = stringProperty(inputSource, kTISPropertyLocalizedName) ?? "nil"
        let type = stringProperty(inputSource, kTISPropertyInputSourceType) ?? "nil"
        let ascii = boolProperty(inputSource, kTISPropertyInputSourceIsASCIICapable).map(String.init) ?? "nil"
        return "\(name) [\(id)] type=\(type) ascii=\(ascii)"
    }

    private static func stringProperty(_ inputSource: TISInputSource, _ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(inputSource, key) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    private static func boolProperty(_ inputSource: TISInputSource, _ key: CFString) -> Bool? {
        guard let pointer = TISGetInputSourceProperty(inputSource, key) else {
            return nil
        }

        let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
        return CFBooleanGetValue(value)
    }
}

@MainActor
final class CommandHandler {
    static let shared = CommandHandler()

    private init() {}

    func handle(url: URL) {
        FilePopDebug.log("handle url=\(url.absoluteString)")

        guard url.scheme == AppConstants.urlScheme else {
            FilePopDebug.log("ignored url with unexpected scheme=\(url.scheme ?? "nil")")
            return
        }

        guard let command = command(from: url) else {
            FilePopDebug.log("failed to parse command from url")
            showErrorMessage(L10n.t(.commandUnavailable))
            return
        }

        handle(command)
    }

    private func handle(_ command: FilePopCommand) {
        let directoryURL = URL(fileURLWithPath: command.directoryPath, isDirectory: true)
        FilePopDebug.log("command action=\(command.action.rawValue) directory=\(directoryURL.path) frontmost=\(FilePopDebug.frontmostApplicationDescription())")

        switch command.action {
        case .manualFile:
            createManualFile(in: directoryURL)
        case .templateFile:
            createTemplateFile(command: command, in: directoryURL)
        case .openTerminal:
            openTerminal(in: directoryURL)
        case .copyPath:
            copyPath(directoryURL.path)
        }
    }

    private func createManualFile(in directoryURL: URL) {
        do {
            let fileURL = try FileCreator.createManualFileWithUniqueName(in: directoryURL)
            FilePopDebug.log("manual file created path=\(fileURL.path)")
            revealInFinderForRenaming(fileURL)
        } catch {
            FilePopDebug.log("manual file create failed error=\(error.localizedDescription)")
            showError(error)
        }
    }

    private func createTemplateFile(command: FilePopCommand, in directoryURL: URL) {
        guard let template = command.template ?? templateFromSettings(id: command.templateID) else {
            showErrorMessage(L10n.t(.templateUnavailable))
            return
        }

        do {
            let fileURL = try FileCreator.createTemplateFileWithUniqueName(template: template, in: directoryURL)
            FilePopDebug.log("template file created template=\(template.menuTitle) path=\(fileURL.path)")
            revealInFinderForRenaming(fileURL)
        } catch {
            FilePopDebug.log("template file create failed error=\(error.localizedDescription)")
            showError(error)
        }
    }

    private func templateFromSettings(id templateID: UUID?) -> FileTemplate? {
        guard let templateID else {
            return nil
        }

        return SettingsRepository.shared.load().templates.first(where: { $0.id == templateID })
    }

    private func openTerminal(in directoryURL: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", directoryURL.path]

        do {
            try process.run()
        } catch {
            showError(error)
        }
    }

    private func copyPath(_ path: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
    }

    private func revealInFinderForRenaming(_ fileURL: URL) {
        let traceID = String(UUID().uuidString.prefix(8))
        FilePopDebug.log("[\(traceID)] rename flow start file=\(fileURL.path) exists=\(FileManager.default.fileExists(atPath: fileURL.path)) frontmost=\(FilePopDebug.frontmostApplicationDescription())")

        Task { @MainActor in
            await KeyboardInputSourceSwitcher.selectEnglishInputSource(traceID: traceID)
            try? await Task.sleep(nanoseconds: 80_000_000)
            FilePopDebug.log("[\(traceID)] activateFileViewerSelecting before frontmost=\(FilePopDebug.frontmostApplicationDescription())")
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            FilePopDebug.log("[\(traceID)] activateFileViewerSelecting called")
            await waitForFinderToBecomeFrontmost(timeoutNanoseconds: 450_000_000)
            try? await Task.sleep(nanoseconds: 120_000_000)
            FilePopDebug.log("[\(traceID)] activateFinder before frontmost=\(FilePopDebug.frontmostApplicationDescription())")
            activateFinder()
            await waitForFinderToBecomeFrontmost(timeoutNanoseconds: 250_000_000)
            try? await Task.sleep(nanoseconds: 80_000_000)
            FilePopDebug.log("[\(traceID)] before Return frontmost=\(FilePopDebug.frontmostApplicationDescription())")
            beginFinderRename(traceID: traceID)
        }
    }

    private func activateFinder() {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.finder")
            .first?
            .activate(options: [.activateIgnoringOtherApps])
    }

    private func waitForFinderToBecomeFrontmost(timeoutNanoseconds: UInt64) async {
        let interval: UInt64 = 50_000_000
        var elapsed: UInt64 = 0

        while elapsed < timeoutNanoseconds {
            if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder" {
                return
            }

            try? await Task.sleep(nanoseconds: interval)
            elapsed += interval
        }
    }

    private func beginFinderRename(traceID: String) {
        guard isAccessibilityTrusted() else {
            FilePopDebug.log("[\(traceID)] Return aborted: accessibility not trusted")
            return
        }

        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder" else {
            FilePopDebug.log("[\(traceID)] Return aborted: frontmost is \(FilePopDebug.frontmostApplicationDescription())")
            return
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false)
        if keyDown == nil || keyUp == nil {
            FilePopDebug.log("[\(traceID)] Return event creation failed")
        }

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        FilePopDebug.log("[\(traceID)] Return posted")
    }

    private func isAccessibilityTrusted() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func command(from url: URL) -> FilePopCommand? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        guard
            let actionValue = queryItems.value(named: "action"),
            let action = FilePopCommandAction(rawValue: actionValue),
            let directoryPath = queryItems.value(named: "directory"),
            !directoryPath.isEmpty
        else {
            return nil
        }

        let templateID = queryItems.value(named: "templateID").flatMap(UUID.init(uuidString:))
        let template = template(from: queryItems, id: templateID)
        return FilePopCommand(
            action: action,
            directoryPath: directoryPath,
            templateID: templateID,
            template: template
        )
    }

    private func template(from queryItems: [URLQueryItem], id templateID: UUID?) -> FileTemplate? {
        guard
            let displayName = queryItems.value(named: "templateName"),
            let fileExtension = queryItems.value(named: "templateExtension"),
            !displayName.isEmpty,
            !fileExtension.isEmpty
        else {
            return nil
        }

        let kindValue = queryItems.value(named: "templateKind")
        let kind = kindValue.flatMap(FileTemplateKind.init(rawValue:))

        return FileTemplate(
            id: templateID ?? UUID(),
            displayName: displayName,
            fileExtension: fileExtension,
            kind: kind,
            order: 0,
            enabled: true
        )
    }

    private func promptForFileName(title: String, defaultValue: String) -> String? {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = title
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.t(.create))
        alert.addButton(withTitle: L10n.t(.cancel))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        textField.stringValue = defaultValue
        alert.accessoryView = textField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return nil
        }

        return textField.stringValue
    }

    private func showInfo(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = message
        alert.runModal()
    }

    private func showError(_ error: Error) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert(error: error)
        alert.messageText = L10n.t(.error)
        alert.runModal()
    }

    private func showErrorMessage(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = L10n.t(.error)
        alert.informativeText = message
        alert.runModal()
    }
}

private extension Array where Element == URLQueryItem {
    func value(named name: String) -> String? {
        first(where: { $0.name == name })?.value
    }
}
