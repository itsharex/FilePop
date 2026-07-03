import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    @State private var editorMode: TemplateEditorMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            modeSection
            templateSection
            footerSection
        }
        .padding(24)
        .frame(minWidth: 680, minHeight: 500)
        .sheet(item: $editorMode) { mode in
            TemplateEditorView(mode: mode)
                .environmentObject(viewModel)
        }
        .alert(L10n.t(.error), isPresented: Binding(
            get: { viewModel.lastErrorMessage != nil },
            set: { if !$0 { viewModel.lastErrorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.lastErrorMessage = nil
            }
        } message: {
            Text(viewModel.lastErrorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FilePop")
                .font(.system(size: 28, weight: .semibold))
            Text(L10n.t(.settingsIntro))
                .foregroundStyle(.secondary)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t(.creationMode))
                .font(.headline)

            Picker("", selection: Binding(
                get: { viewModel.creationMode },
                set: { viewModel.creationMode = $0 }
            )) {
                ForEach(CreationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(viewModel.creationMode.detail)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.t(.templates))
                    .font(.headline)
                Spacer()
                Button {
                    editorMode = .add
                } label: {
                    Label(L10n.t(.addTemplate), systemImage: "plus")
                }
            }

            List {
                ForEach(viewModel.templates) { template in
                    TemplateRow(
                        template: template,
                        onEdit: { editorMode = .edit(template) }
                    )
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 210)
        }
    }

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle(L10n.t(.launchAtLogin), isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.launchAtLogin = $0 }
                ))
                Spacer()
                Button(L10n.t(.resetDefaults)) {
                    viewModel.resetTemplates()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle(L10n.t(.externalVolumeIntegration), isOn: Binding(
                    get: { viewModel.externalVolumeIntegrationEnabled },
                    set: { viewModel.externalVolumeIntegrationEnabled = $0 }
                ))
                Text(L10n.t(.externalVolumeIntegrationDetail))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TemplateRow: View {
    @EnvironmentObject private var viewModel: SettingsViewModel
    let template: FileTemplate
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { template.enabled },
                set: { viewModel.setTemplateEnabled(template, enabled: $0) }
            ))
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(template.displayName)
                    .font(.body)
                Text(".\(template.fileExtension)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.moveTemplate(template, direction: -1)
            } label: {
                Image(systemName: "arrow.up")
            }
            .help("Move Up")

            Button {
                viewModel.moveTemplate(template, direction: 1)
            } label: {
                Image(systemName: "arrow.down")
            }
            .help("Move Down")

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .help(L10n.t(.editTemplate))

            Button(role: .destructive) {
                viewModel.deleteTemplate(template)
            } label: {
                Image(systemName: "trash")
            }
            .help(L10n.t(.deleteTemplate))
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }
}
