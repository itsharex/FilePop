import Foundation

enum FileCreationError: LocalizedError, Equatable {
    case invalidFileName
    case fileAlreadyExists(String)
    case missingOfficeTemplate(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidFileName:
            return L10n.t(.invalidFileName)
        case .fileAlreadyExists(let name):
            return String(format: L10n.t(.fileAlreadyExistsFormat), name)
        case .missingOfficeTemplate(let ext):
            return String(format: L10n.t(.missingOfficeTemplateFormat), ext)
        case .writeFailed(let message):
            return message
        }
    }
}

enum FileCreator {
    @discardableResult
    static func createManualFile(named fileName: String, in directoryURL: URL) throws -> URL {
        let normalizedName = try validateFileName(fileName)
        let targetURL = directoryURL.appendingPathComponent(normalizedName, isDirectory: false)
        try ensureDoesNotExist(targetURL)
        return try writeEmptyFile(to: targetURL)
    }

    @discardableResult
    static func createManualFileWithUniqueName(in directoryURL: URL) throws -> URL {
        let targetURL = uniqueURL(
            in: directoryURL,
            baseName: L10n.t(.untitledFile),
            fileExtension: nil
        )
        return try writeEmptyFile(to: targetURL)
    }

    @discardableResult
    static func createTemplateFile(named rawName: String, template: FileTemplate, in directoryURL: URL) throws -> URL {
        let fileName = try normalizedTemplateFileName(rawName, fileExtension: template.fileExtension)
        let targetURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)
        try ensureDoesNotExist(targetURL)

        switch template.kind {
        case .plain:
            return try writeEmptyFile(to: targetURL)
        case .office:
            guard let data = OfficeTemplateData.data(for: template.fileExtension) else {
                throw FileCreationError.missingOfficeTemplate(template.fileExtension)
            }

            do {
                try data.write(to: targetURL, options: .atomic)
                return targetURL
            } catch {
                throw FileCreationError.writeFailed(error.localizedDescription)
            }
        }
    }

    @discardableResult
    static func createTemplateFileWithUniqueName(template: FileTemplate, in directoryURL: URL) throws -> URL {
        let targetURL = uniqueURL(
            in: directoryURL,
            baseName: defaultBaseName(for: template),
            fileExtension: template.fileExtension
        )

        switch template.kind {
        case .plain:
            return try writeEmptyFile(to: targetURL)
        case .office:
            guard let data = OfficeTemplateData.data(for: template.fileExtension) else {
                throw FileCreationError.missingOfficeTemplate(template.fileExtension)
            }

            do {
                try data.write(to: targetURL, options: .atomic)
                return targetURL
            } catch {
                throw FileCreationError.writeFailed(error.localizedDescription)
            }
        }
    }

    static func defaultBaseName(for template: FileTemplate) -> String {
        switch FileTemplate.normalizedExtension(template.fileExtension) {
        case "txt":
            return L10n.t(.untitledText)
        case "md":
            return L10n.t(.untitledMarkdown)
        case "docx":
            return L10n.t(.untitledWord)
        case "xlsx":
            return L10n.t(.untitledExcel)
        case "pptx":
            return L10n.t(.untitledPowerPoint)
        default:
            return L10n.t(.untitledFile)
        }
    }

    static func normalizedTemplateFileName(_ rawName: String, fileExtension: String) throws -> String {
        let cleanExtension = FileTemplate.normalizedExtension(fileExtension)
        let validated = try validateFileName(rawName)

        guard !cleanExtension.isEmpty else {
            return validated
        }

        let url = URL(fileURLWithPath: validated)
        if url.pathExtension.lowercased() == cleanExtension {
            return validated
        }

        return "\(validated).\(cleanExtension)"
    }

    @discardableResult
    static func adaptNewlyCreatedFile(
        at fileURL: URL,
        from originalExtension: String?
    ) throws -> Bool {
        let finalExtension = FileTemplate.normalizedExtension(fileURL.pathExtension)
        let normalizedOriginalExtension = originalExtension.map(FileTemplate.normalizedExtension)

        guard finalExtension != (normalizedOriginalExtension ?? "") else {
            return false
        }

        if let officeData = OfficeTemplateData.data(for: finalExtension) {
            do {
                try officeData.write(to: fileURL, options: .atomic)
                return true
            } catch {
                throw FileCreationError.writeFailed(error.localizedDescription)
            }
        }

        guard normalizedOriginalExtension != nil else {
            return false
        }

        do {
            try Data().write(to: fileURL, options: .atomic)
            return true
        } catch {
            throw FileCreationError.writeFailed(error.localizedDescription)
        }
    }

    static func validateFileName(_ fileName: String) throws -> String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !trimmed.isEmpty,
            trimmed != ".",
            trimmed != "..",
            !trimmed.contains("/"),
            !trimmed.contains(":"),
            !trimmed.contains("\0")
        else {
            throw FileCreationError.invalidFileName
        }

        return trimmed
    }

    private static func ensureDoesNotExist(_ url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            throw FileCreationError.fileAlreadyExists(url.lastPathComponent)
        }
    }

    private static func uniqueURL(in directoryURL: URL, baseName: String, fileExtension: String?) -> URL {
        let cleanBaseName = (try? validateFileName(baseName)) ?? "Untitled"
        let cleanExtension = fileExtension.map(FileTemplate.normalizedExtension).flatMap { $0.isEmpty ? nil : $0 }

        func candidateURL(index: Int?) -> URL {
            let name: String
            if let index {
                name = "\(cleanBaseName) \(index)"
            } else {
                name = cleanBaseName
            }

            let fileName = cleanExtension.map { "\(name).\($0)" } ?? name
            return directoryURL.appendingPathComponent(fileName, isDirectory: false)
        }

        var url = candidateURL(index: nil)
        var index = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = candidateURL(index: index)
            index += 1
        }

        return url
    }

    @discardableResult
    private static func writeEmptyFile(to url: URL) throws -> URL {
        let success = FileManager.default.createFile(atPath: url.path, contents: Data())
        if success {
            return url
        }

        throw FileCreationError.writeFailed(L10n.t(.unableToCreateFile))
    }
}
