import Foundation

enum CreationMode: String, Codable, CaseIterable, Identifiable {
    case manualSuffix
    case templatePicker

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manualSuffix:
            return L10n.t(.manualSuffixMode)
        case .templatePicker:
            return L10n.t(.templatePickerMode)
        }
    }

    var detail: String {
        switch self {
        case .manualSuffix:
            return L10n.t(.manualSuffixModeDetail)
        case .templatePicker:
            return L10n.t(.templatePickerModeDetail)
        }
    }
}
