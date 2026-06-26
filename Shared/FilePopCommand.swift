import Foundation

enum FilePopCommandAction: String, Codable {
    case manualFile
    case templateFile
    case openTerminal
    case copyPath
}

struct FilePopCommand: Codable, Identifiable {
    var id: UUID
    var action: FilePopCommandAction
    var directoryPath: String
    var templateID: UUID?
    var template: FileTemplate?

    init(
        id: UUID = UUID(),
        action: FilePopCommandAction,
        directoryPath: String,
        templateID: UUID? = nil,
        template: FileTemplate? = nil
    ) {
        self.id = id
        self.action = action
        self.directoryPath = directoryPath
        self.templateID = templateID
        self.template = template
    }
}
