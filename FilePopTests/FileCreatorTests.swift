import XCTest

final class FileCreatorTests: XCTestCase {
    private var directoryURL: URL!

    override func setUpWithError() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directoryURL {
            try? FileManager.default.removeItem(at: directoryURL)
        }
    }

    func testManualFileCreationAllowsExtensionAndNoExtension() throws {
        let txtURL = try FileCreator.createManualFile(named: "note.md", in: directoryURL)
        let noExtensionURL = try FileCreator.createManualFile(named: "todo", in: directoryURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: txtURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: noExtensionURL.path))
    }

    func testInvalidManualFileNameThrows() {
        XCTAssertThrowsError(try FileCreator.createManualFile(named: "", in: directoryURL))
        XCTAssertThrowsError(try FileCreator.createManualFile(named: "bad/name.txt", in: directoryURL))
    }

    func testNameConflictThrowsWithoutOverwriting() throws {
        _ = try FileCreator.createManualFile(named: "same.txt", in: directoryURL)

        XCTAssertThrowsError(try FileCreator.createManualFile(named: "same.txt", in: directoryURL)) { error in
            XCTAssertEqual(error as? FileCreationError, .fileAlreadyExists("same.txt"))
        }
    }

    func testTemplateAppendsExtensionWhenMissing() throws {
        let template = FileTemplate(displayName: "Markdown", fileExtension: "md", order: 0)
        let url = try FileCreator.createTemplateFile(named: "notes", template: template, in: directoryURL)

        XCTAssertEqual(url.lastPathComponent, "notes.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testTemplateUniqueCreationAvoidsOverwriting() throws {
        let template = FileTemplate(displayName: "Markdown", fileExtension: "md", order: 0)
        let firstURL = try FileCreator.createTemplateFileWithUniqueName(template: template, in: directoryURL)
        let secondURL = try FileCreator.createTemplateFileWithUniqueName(template: template, in: directoryURL)

        XCTAssertEqual(firstURL.lastPathComponent, "\(L10n.t(.untitledMarkdown)).md")
        XCTAssertEqual(secondURL.lastPathComponent, "\(L10n.t(.untitledMarkdown)) 2.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path))
    }

    func testOfficeTemplateWritesData() throws {
        let template = FileTemplate(displayName: "Word", fileExtension: "docx", order: 0)
        let url = try FileCreator.createTemplateFile(named: "draft", template: template, in: directoryURL)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? NSNumber

        XCTAssertEqual(url.pathExtension, "docx")
        XCTAssertGreaterThan(size?.intValue ?? 0, 0)
    }

    func testPowerPointTemplateUsesCompletePresentationPackage() throws {
        let data = try XCTUnwrap(OfficeTemplateData.data(for: "pptx"))

        XCTAssertGreaterThan(data.count, 9_000)
        XCTAssertEqual(Array(data.prefix(2)), [0x50, 0x4B])
    }

    func testManualDesktopRenameToOfficeExtensionWritesValidTemplateData() throws {
        let url = try FileCreator.createManualFile(named: "draft.xlsx", in: directoryURL)

        let adapted = try FileCreator.adaptNewlyCreatedFile(at: url, from: nil)
        let data = try Data(contentsOf: url)

        XCTAssertTrue(adapted)
        XCTAssertEqual(data, OfficeTemplateData.data(for: "xlsx"))
    }

    func testTemplateDesktopRenameToDifferentOfficeExtensionReplacesTemplateData() throws {
        let excelTemplate = FileTemplate(displayName: "Excel", fileExtension: "xlsx", order: 0)
        let originalURL = try FileCreator.createTemplateFile(
            named: "draft",
            template: excelTemplate,
            in: directoryURL
        )
        let renamedURL = directoryURL.appendingPathComponent("draft.docx")
        try FileManager.default.moveItem(at: originalURL, to: renamedURL)

        let adapted = try FileCreator.adaptNewlyCreatedFile(at: renamedURL, from: "xlsx")
        let data = try Data(contentsOf: renamedURL)

        XCTAssertTrue(adapted)
        XCTAssertEqual(data, OfficeTemplateData.data(for: "docx"))
    }

    func testManualDesktopRenameToPlainExtensionKeepsEmptyFile() throws {
        let url = try FileCreator.createManualFile(named: "notes.md", in: directoryURL)

        let adapted = try FileCreator.adaptNewlyCreatedFile(at: url, from: nil)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? NSNumber

        XCTAssertFalse(adapted)
        XCTAssertEqual(size?.intValue, 0)
    }
}
