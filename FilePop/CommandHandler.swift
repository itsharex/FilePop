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

    private enum CreatedFileSource {
        case manual
        case template(fileExtension: String)

        var originalExtension: String? {
            switch self {
            case .manual:
                return nil
            case .template(let fileExtension):
                return FileTemplate.normalizedExtension(fileExtension)
            }
        }
    }

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
            revealInFinderForRenaming(fileURL, source: .manual)
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
            revealInFinderForRenaming(
                fileURL,
                source: .template(fileExtension: template.fileExtension)
            )
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

    private func revealInFinderForRenaming(_ fileURL: URL, source: CreatedFileSource) {
        let traceID = String(UUID().uuidString.prefix(8))
        let isDesktopFile = isFileOnDesktop(fileURL)
        FilePopDebug.log("[\(traceID)] rename flow start file=\(fileURL.path) exists=\(FileManager.default.fileExists(atPath: fileURL.path)) desktop=\(isDesktopFile) frontmost=\(FilePopDebug.frontmostApplicationDescription())")

        Task { @MainActor in
            await KeyboardInputSourceSwitcher.selectEnglishInputSource(traceID: traceID)
            try? await Task.sleep(nanoseconds: 80_000_000)

            if isDesktopFile {
                await selectDesktopFileForRenaming(
                    fileURL,
                    source: source,
                    traceID: traceID
                )
                return
            }

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

    private func isFileOnDesktop(_ fileURL: URL) -> Bool {
        guard let desktopURL = FileManager.default.urls(
            for: .desktopDirectory,
            in: .userDomainMask
        ).first else {
            return false
        }

        let directoryURL = fileURL.deletingLastPathComponent()
        let resourceKeys: Set<URLResourceKey> = [.fileResourceIdentifierKey]

        if
            let directoryIdentifier = try? directoryURL
                .resourceValues(forKeys: resourceKeys)
                .fileResourceIdentifier as? NSObject,
            let desktopIdentifier = try? desktopURL
                .resourceValues(forKeys: resourceKeys)
                .fileResourceIdentifier as? NSObject
        {
            return directoryIdentifier.isEqual(desktopIdentifier)
        }

        return directoryURL
            .standardizedFileURL
            .resolvingSymlinksInPath() == desktopURL
            .standardizedFileURL
            .resolvingSymlinksInPath()
    }

    private func selectDesktopFileForRenaming(
        _ fileURL: URL,
        source: CreatedFileSource,
        traceID: String
    ) async {
        guard isAccessibilityTrusted() else {
            FilePopDebug.log("[\(traceID)] desktop selection aborted: accessibility not trusted")
            return
        }

        if source.originalExtension != nil {
            applyDesktopTypeIcon(to: fileURL, traceID: traceID)
        }

        let resourceIdentifier = fileResourceIdentifier(for: fileURL)
        let maximumAttempts = 12
        for attempt in 1...maximumAttempts {
            let finderPID = selectFinderDesktopIcon(fileURL, traceID: traceID)
            FilePopDebug.log("[\(traceID)] desktop selection attempt=\(attempt) selected=\(finderPID != nil) frontmost=\(FilePopDebug.frontmostApplicationDescription())")

            if let finderPID {
                try? await Task.sleep(nanoseconds: 100_000_000)
                postDesktopRenameReturn(
                    toFinderPID: finderPID,
                    traceID: traceID
                )
                await waitForDesktopRenameToFinish(
                    originalURL: fileURL,
                    resourceIdentifier: resourceIdentifier,
                    source: source,
                    traceID: traceID
                )
                return
            }

            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        FilePopDebug.log("[\(traceID)] desktop icon selection failed after \(maximumAttempts) attempts; Finder reveal intentionally skipped")
    }

    private func waitForDesktopRenameToFinish(
        originalURL: URL,
        resourceIdentifier: NSObject?,
        source: CreatedFileSource,
        traceID: String
    ) async {
        for _ in 0..<3_000 {
            let finalURL = resolveRenamedDesktopFile(
                originalURL: originalURL,
                resourceIdentifier: resourceIdentifier
            )
            if
                let finalURL,
                finalURL.standardizedFileURL != originalURL.standardizedFileURL
            {
                finalizeDesktopFile(
                    at: finalURL,
                    source: source,
                    traceID: traceID
                )
                return
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }

        FilePopDebug.log("[\(traceID)] desktop rename path-change wait timed out or rename was cancelled")
    }

    private func selectFinderDesktopIcon(
        _ fileURL: URL,
        traceID: String
    ) -> pid_t? {
        guard
            let finder = NSRunningApplication
                .runningApplications(withBundleIdentifier: "com.apple.finder")
                .first
        else {
            FilePopDebug.log("[\(traceID)] desktop AX selection failed: Finder is not running")
            return nil
        }

        let finderElement = AXUIElementCreateApplication(finder.processIdentifier)
        guard let match = findDesktopIcon(
            in: finderElement,
            fileURL: fileURL,
            maximumDepth: 12,
            maximumElements: 3_000
        ) else {
            return nil
        }

        let desktopContainer = match.ancestors.last
        var selectionResult = AXError.failure
        if let desktopContainer {
            selectionResult = AXUIElementSetAttributeValue(
                desktopContainer,
                kAXSelectedChildrenAttribute as CFString,
                [match.element] as CFArray
            )
        }

        if selectionResult != .success {
            let result = AXUIElementSetAttributeValue(
                match.element,
                kAXSelectedAttribute as CFString,
                kCFBooleanTrue
            )
            selectionResult = result
        }

        guard selectionResult == .success else {
            FilePopDebug.log("[\(traceID)] desktop AX selection failed: matching icon is not selectable")
            return nil
        }

        let focusTarget = desktopContainer ?? match.element
        let focusResult = AXUIElementSetAttributeValue(
            focusTarget,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
        let appFocusResult = AXUIElementSetAttributeValue(
            finderElement,
            kAXFocusedUIElementAttribute as CFString,
            focusTarget
        )
        FilePopDebug.log("[\(traceID)] desktop AX focus result=\(focusResult.rawValue) appFocus=\(appFocusResult.rawValue)")
        return finder.processIdentifier
    }

    private func postDesktopRenameReturn(
        toFinderPID finderPID: pid_t,
        traceID: String
    ) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 36, keyDown: false)

        guard let keyDown, let keyUp else {
            FilePopDebug.log("[\(traceID)] desktop Return event creation failed")
            return
        }

        keyDown.postToPid(finderPID)
        keyUp.postToPid(finderPID)
        FilePopDebug.log("[\(traceID)] desktop Return posted to Finder pid=\(finderPID)")
    }

    private func findDesktopIcon(
        in root: AXUIElement,
        fileURL: URL,
        maximumDepth: Int,
        maximumElements: Int
    ) -> (element: AXUIElement, ancestors: [AXUIElement])? {
        struct PendingElement {
            let element: AXUIElement
            let ancestors: [AXUIElement]
            let depth: Int
        }

        let targetName = fileURL.lastPathComponent
        let targetURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()
        var pending = [PendingElement(element: root, ancestors: [], depth: 0)]
        var pendingIndex = 0
        var visitedCount = 0

        while pendingIndex < pending.count, visitedCount < maximumElements {
            let current = pending[pendingIndex]
            pendingIndex += 1
            visitedCount += 1

            if
                isDesktopIcon(current.element, named: targetName, fileURL: targetURL),
                !isInsideStandardFinderWindow(current.ancestors)
            {
                return (current.element, current.ancestors)
            }

            guard current.depth < maximumDepth else {
                continue
            }

            let nextAncestors = current.ancestors + [current.element]
            for child in axChildren(of: current.element) {
                pending.append(PendingElement(
                    element: child,
                    ancestors: nextAncestors,
                    depth: current.depth + 1
                ))
            }
        }

        return nil
    }

    private func isInsideStandardFinderWindow(_ ancestors: [AXUIElement]) -> Bool {
        ancestors.contains { element in
            let role = axStringValue(
                of: element,
                attribute: kAXRoleAttribute as CFString
            )
            guard role == (kAXWindowRole as String) else {
                return false
            }

            let subrole = axStringValue(
                of: element,
                attribute: kAXSubroleAttribute as CFString
            )
            return subrole == "AXStandardWindow"
        }
    }

    private func isDesktopIcon(_ element: AXUIElement, named targetName: String, fileURL: URL) -> Bool {
        let role = axStringValue(of: element, attribute: kAXRoleAttribute as CFString)
        let isIconRole = role == (kAXImageRole as String) || role == "AXIcon"
        guard isIconRole else {
            return false
        }

        let candidateNames = [
            axStringValue(of: element, attribute: kAXTitleAttribute as CFString),
            axStringValue(of: element, attribute: kAXDescriptionAttribute as CFString),
            axStringValue(of: element, attribute: kAXValueAttribute as CFString)
        ]
        if candidateNames.compactMap({ $0 }).contains(targetName) {
            return true
        }

        guard
            let candidateURL = axURLValue(of: element),
            candidateURL.isFileURL
        else {
            return false
        }

        return candidateURL.standardizedFileURL.resolvingSymlinksInPath() == fileURL
    }

    private func axChildren(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &value
        )
        guard result == .success, let children = value as? [AXUIElement] else {
            return []
        }
        return children
    }

    private func axStringValue(of element: AXUIElement, attribute: CFString) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else {
            return nil
        }
        return value as? String
    }

    private func axURLValue(of element: AXUIElement) -> URL? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXURLAttribute as CFString,
            &value
        )
        guard result == .success else {
            return nil
        }

        if let url = value as? URL {
            return url
        }
        if let string = value as? String {
            return URL(string: string)
        }
        return nil
    }

    private func fileResourceIdentifier(for fileURL: URL) -> NSObject? {
        let values = try? fileURL.resourceValues(forKeys: [.fileResourceIdentifierKey])
        return values?.fileResourceIdentifier as? NSObject
    }

    private func resolveRenamedDesktopFile(
        originalURL: URL,
        resourceIdentifier: NSObject?
    ) -> URL? {
        if
            FileManager.default.fileExists(atPath: originalURL.path),
            resourceIdentifier == nil || fileResourceIdentifier(for: originalURL)?.isEqual(resourceIdentifier) == true
        {
            return originalURL
        }

        guard let resourceIdentifier else {
            return nil
        }

        let desktopURL = originalURL.deletingLastPathComponent()
        let candidates = try? FileManager.default.contentsOfDirectory(
            at: desktopURL,
            includingPropertiesForKeys: [.fileResourceIdentifierKey],
            options: [.skipsHiddenFiles]
        )
        return candidates?.first { candidate in
            fileResourceIdentifier(for: candidate)?.isEqual(resourceIdentifier) == true
        }
    }

    private func finalizeDesktopFile(
        at fileURL: URL,
        source: CreatedFileSource,
        traceID: String
    ) {
        do {
            let adapted = try FileCreator.adaptNewlyCreatedFile(
                at: fileURL,
                from: source.originalExtension
            )
            FilePopDebug.log("[\(traceID)] desktop final content adapted=\(adapted) file=\(fileURL.path)")
        } catch {
            FilePopDebug.log("[\(traceID)] desktop final content adaptation failed error=\(error.localizedDescription)")
        }

        applyDesktopTypeIcon(to: fileURL, traceID: traceID)
    }

    private func applyDesktopTypeIcon(to fileURL: URL, traceID: String) {
        let fileExtension = FileTemplate.normalizedExtension(fileURL.pathExtension)
        guard !fileExtension.isEmpty else {
            _ = NSWorkspace.shared.setIcon(nil, forFile: fileURL.path, options: [])
            return
        }

        let workspace = NSWorkspace.shared
        let typeIcon: NSImage
        if let applicationURL = workspace.urlForApplication(toOpen: fileURL) {
            typeIcon = workspace.icon(forFile: applicationURL.path)
        } else {
            typeIcon = workspace.icon(forFileType: fileExtension)
        }

        let applied = workspace.setIcon(typeIcon, forFile: fileURL.path, options: [])
        FilePopDebug.log("[\(traceID)] desktop type icon applied=\(applied) extension=\(fileExtension)")
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
