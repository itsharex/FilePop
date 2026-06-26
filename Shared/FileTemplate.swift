import Foundation

enum FileTemplateKind: String, Codable {
    case plain
    case office
}

struct FileTemplate: Identifiable, Codable, Hashable {
    var id: UUID
    var displayName: String
    var fileExtension: String
    var kind: FileTemplateKind
    var order: Int
    var enabled: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        fileExtension: String,
        kind: FileTemplateKind? = nil,
        order: Int,
        enabled: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.fileExtension = FileTemplate.normalizedExtension(fileExtension)
        self.kind = kind ?? FileTemplate.kind(for: fileExtension)
        self.order = order
        self.enabled = enabled
    }

    var menuTitle: String {
        "\(displayName) (.\(fileExtension))"
    }

    static func normalizedExtension(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
    }

    static func kind(for fileExtension: String) -> FileTemplateKind {
        let officeExtensions: Set<String> = ["docx", "xlsx", "pptx"]
        return officeExtensions.contains(normalizedExtension(fileExtension)) ? .office : .plain
    }

    static var defaultTemplates: [FileTemplate] {
        [
            FileTemplate(displayName: "TXT", fileExtension: "txt", order: 0),
            FileTemplate(displayName: "Markdown", fileExtension: "md", order: 1),
            FileTemplate(displayName: "Word", fileExtension: "docx", order: 2),
            FileTemplate(displayName: "Excel", fileExtension: "xlsx", order: 3),
            FileTemplate(displayName: "PowerPoint", fileExtension: "pptx", order: 4)
        ]
    }
}
