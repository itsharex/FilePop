import SwiftUI

enum TemplateEditorMode: Identifiable {
    case add
    case edit(FileTemplate)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let template):
            return template.id.uuidString
        }
    }

    var template: FileTemplate? {
        if case .edit(let template) = self {
            return template
        }

        return nil
    }
}

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: SettingsViewModel

    let mode: TemplateEditorMode

    @State private var displayName: String
    @State private var fileExtension: String
    @State private var enabled: Bool

    init(mode: TemplateEditorMode) {
        self.mode = mode
        let template = mode.template
        _displayName = State(initialValue: template?.displayName ?? "")
        _fileExtension = State(initialValue: template?.fileExtension ?? "")
        _enabled = State(initialValue: template?.enabled ?? true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(mode.template == nil ? L10n.t(.addTemplate) : L10n.t(.editTemplate))
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField(L10n.t(.templateName), text: $displayName)
                TextField(L10n.t(.fileExtension), text: $fileExtension)
                Toggle(L10n.t(.enabled), isOn: $enabled)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button(L10n.t(.cancel)) {
                    dismiss()
                }
                Button(L10n.t(.save)) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !FileTemplate.normalizedExtension(fileExtension).isEmpty
    }

    private func save() {
        if let template = mode.template {
            viewModel.updateTemplate(
                template,
                displayName: displayName,
                fileExtension: fileExtension,
                enabled: enabled
            )
        } else {
            viewModel.addTemplate(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                fileExtension: fileExtension
            )
        }

        dismiss()
    }
}
