import Foundation

enum L10nKey: String {
    case openSettings
    case settingsTitle
    case creationMode
    case manualSuffixMode
    case manualSuffixModeDetail
    case templatePickerMode
    case templatePickerModeDetail
    case templates
    case addTemplate
    case editTemplate
    case deleteTemplate
    case templateName
    case fileExtension
    case enabled
    case save
    case cancel
    case resetDefaults
    case onboarding
    case openExtensionSettings
    case finishOnboarding
    case launchAtLogin
    case showGuide
    case quit
    case newFile
    case openTerminalHere
    case copyFolderPath
    case enterFileName
    case enterTemplateFileName
    case create
    case fileCreated
    case pathCopied
    case error
    case invalidFileName
    case fileAlreadyExistsFormat
    case missingOfficeTemplateFormat
    case unableToCreateFile
    case untitledFile
    case untitledText
    case untitledMarkdown
    case untitledWord
    case untitledExcel
    case untitledPowerPoint
    case onboardingTitle
    case onboardingBody
    case onboardingStepOne
    case onboardingStepTwo
    case onboardingStepThree
    case settingsIntro
    case loginItemError
    case commandUnavailable
    case templateUnavailable
}

enum L10n {
    static func t(_ key: L10nKey) -> String {
        let language = Locale.preferredLanguages.first ?? "en"
        if language.hasPrefix("zh") {
            return zh[key] ?? en[key] ?? key.rawValue
        }

        return en[key] ?? key.rawValue
    }

    private static let en: [L10nKey: String] = [
        .openSettings: "Open Settings",
        .settingsTitle: "FilePop Settings",
        .creationMode: "Creation Mode",
        .manualSuffixMode: "Manual Extension Mode",
        .manualSuffixModeDetail: "Right-click New File, then type a complete file name such as note.md.",
        .templatePickerMode: "Template Picker Mode",
        .templatePickerModeDetail: "Right-click New File, then choose a template such as Word or Excel.",
        .templates: "Templates",
        .addTemplate: "Add Template",
        .editTemplate: "Edit Template",
        .deleteTemplate: "Delete Template",
        .templateName: "Template Name",
        .fileExtension: "File Extension",
        .enabled: "Enabled",
        .save: "Save",
        .cancel: "Cancel",
        .resetDefaults: "Reset Defaults",
        .onboarding: "Onboarding",
        .openExtensionSettings: "Open Extension Settings",
        .finishOnboarding: "Finish",
        .launchAtLogin: "Launch at Login",
        .showGuide: "Show Guide",
        .quit: "Quit FilePop",
        .newFile: "New File",
        .openTerminalHere: "Open Terminal Here",
        .copyFolderPath: "Copy Folder Path",
        .enterFileName: "Enter a file name",
        .enterTemplateFileName: "Enter a name for %@",
        .create: "Create",
        .fileCreated: "File created.",
        .pathCopied: "Folder path copied.",
        .error: "Error",
        .invalidFileName: "Enter a valid file name.",
        .fileAlreadyExistsFormat: "A file named %@ already exists. Choose another name.",
        .missingOfficeTemplateFormat: "No built-in template is available for .%@.",
        .unableToCreateFile: "Unable to create the file.",
        .untitledFile: "Untitled",
        .untitledText: "Untitled Text",
        .untitledMarkdown: "Untitled Markdown",
        .untitledWord: "Untitled Word",
        .untitledExcel: "Untitled Excel",
        .untitledPowerPoint: "Untitled PowerPoint",
        .onboardingTitle: "Set Up FilePop",
        .onboardingBody: "Enable the Finder extension, choose whether FilePop starts at login, then use Finder background right-click menus.",
        .onboardingStepOne: "1. Enable FilePop in System Settings > Privacy & Security > Extensions > Finder Extensions.",
        .onboardingStepTwo: "2. Keep FilePop running from the menu bar.",
        .onboardingStepThree: "3. Right-click Finder background to create files, open Terminal, or copy the folder path.",
        .settingsIntro: "Configure how Finder creates new files and which templates appear in the right-click menu.",
        .loginItemError: "FilePop could not update the login item setting.",
        .commandUnavailable: "FilePop could not read the Finder command. Try again from Finder.",
        .templateUnavailable: "The selected template is no longer available."
    ]

    private static let zh: [L10nKey: String] = [
        .openSettings: "打开设置",
        .settingsTitle: "FilePop 设置",
        .creationMode: "创建模式",
        .manualSuffixMode: "手动后缀模式",
        .manualSuffixModeDetail: "右键点击新建文件后，输入完整文件名，例如 note.md。",
        .templatePickerMode: "模板选择模式",
        .templatePickerModeDetail: "右键点击新建文件后，从 Word、Excel 等模板中选择。",
        .templates: "模板",
        .addTemplate: "新增模板",
        .editTemplate: "编辑模板",
        .deleteTemplate: "删除模板",
        .templateName: "模板名称",
        .fileExtension: "文件后缀",
        .enabled: "启用",
        .save: "保存",
        .cancel: "取消",
        .resetDefaults: "恢复默认",
        .onboarding: "首次引导",
        .openExtensionSettings: "打开扩展设置",
        .finishOnboarding: "完成",
        .launchAtLogin: "开机启动",
        .showGuide: "查看引导",
        .quit: "退出 FilePop",
        .newFile: "新建文件",
        .openTerminalHere: "在终端中打开",
        .copyFolderPath: "复制目录路径",
        .enterFileName: "输入文件名",
        .enterTemplateFileName: "输入 %@ 的文件名",
        .create: "创建",
        .fileCreated: "文件已创建。",
        .pathCopied: "目录路径已复制。",
        .error: "错误",
        .invalidFileName: "请输入有效的文件名。",
        .fileAlreadyExistsFormat: "已存在名为 %@ 的文件，请换一个名称。",
        .missingOfficeTemplateFormat: "没有可用于 .%@ 的内置模板。",
        .unableToCreateFile: "无法创建文件。",
        .untitledFile: "未命名",
        .untitledText: "未命名文本",
        .untitledMarkdown: "未命名 Markdown",
        .untitledWord: "未命名 Word",
        .untitledExcel: "未命名 Excel",
        .untitledPowerPoint: "未命名 PowerPoint",
        .onboardingTitle: "设置 FilePop",
        .onboardingBody: "启用 Finder 扩展，选择是否开机启动，然后在 Finder 空白处右键使用功能。",
        .onboardingStepOne: "1. 在系统设置 > 隐私与安全性 > 扩展 > Finder 扩展中启用 FilePop。",
        .onboardingStepTwo: "2. 保持 FilePop 在顶部菜单栏运行。",
        .onboardingStepThree: "3. 在 Finder 空白处右键即可新建文件、打开终端或复制目录路径。",
        .settingsIntro: "配置 Finder 新建文件的方式，以及右键菜单中显示哪些模板。",
        .loginItemError: "FilePop 无法更新开机启动设置。",
        .commandUnavailable: "FilePop 无法读取 Finder 命令，请回到 Finder 重试。",
        .templateUnavailable: "选中的模板已不可用。"
    ]
}
