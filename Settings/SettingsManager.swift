import Foundation
import Combine

final class SettingsManager: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var captureFormat: CaptureFormat {
        didSet { defaults.set(captureFormat.rawValue, forKey: "novacam.captureFormat") }
    }
    @Published var enableGrid: Bool {
        didSet { defaults.set(enableGrid, forKey: "novacam.enableGrid") }
    }
    @Published var enableHistogram: Bool {
        didSet { defaults.set(enableHistogram, forKey: "novacam.enableHistogram") }
    }
    @Published var enableFocusPeaking: Bool {
        didSet { defaults.set(enableFocusPeaking, forKey: "novacam.enableFocusPeaking") }
    }
    @Published var enableZebraExposure: Bool {
        didSet { defaults.set(enableZebraExposure, forKey: "novacam.enableZebraExposure") }
    }
    @Published var enableLevelIndicator: Bool {
        didSet { defaults.set(enableLevelIndicator, forKey: "novacam.enableLevelIndicator") }
    }
    @Published var gridType: GridType {
        didSet { defaults.set(gridType.rawValue, forKey: "novacam.gridType") }
    }
    @Published var enableAIAssistant: Bool {
        didSet { defaults.set(enableAIAssistant, forKey: "novacam.enableAIAssistant") }
    }
    @Published var enableAutoEnhancement: Bool {
        didSet { defaults.set(enableAutoEnhancement, forKey: "novacam.enableAutoEnhancement") }
    }
    @Published var preferredLanguage: SupportedLanguage {
        didSet { defaults.set(preferredLanguage.rawValue, forKey: "novacam.preferredLanguage") }
    }
    @Published var hapticFeedbackEnabled: Bool = true {
        didSet { defaults.set(hapticFeedbackEnabled, forKey: "novacam.hapticFeedback") }
    }
    @Published var colorTheme: ColorTheme = .dark {
        didSet { defaults.set(colorTheme.rawValue, forKey: "novacam.colorTheme") }
    }
    @Published var defaultCaptureMode: CaptureMode = .auto {
        didSet { defaults.set(defaultCaptureMode.rawValue, forKey: "novacam.defaultMode") }
    }
    @Published var saveLocation: Bool = true {
        didSet { defaults.set(saveLocation, forKey: "novacam.saveLocation") }
    }

    init() {
        captureFormat = SettingsManager.load("novacam.captureFormat", .heif)
        enableGrid = SettingsManager.loadBool("novacam.enableGrid", true)
        enableHistogram = SettingsManager.loadBool("novacam.enableHistogram", true)
        enableFocusPeaking = SettingsManager.loadBool("novacam.enableFocusPeaking", true)
        enableZebraExposure = SettingsManager.loadBool("novacam.enableZebraExposure", false)
        enableLevelIndicator = SettingsManager.loadBool("novacam.enableLevelIndicator", true)
        gridType = SettingsManager.load("novacam.gridType", .ruleOfThirds)
        enableAIAssistant = SettingsManager.loadBool("novacam.enableAIAssistant", true)
        enableAutoEnhancement = SettingsManager.loadBool("novacam.enableAutoEnhancement", true)
        preferredLanguage = SettingsManager.loadLang("novacam.preferredLanguage", .english)
        hapticFeedbackEnabled = SettingsManager.loadBool("novacam.hapticFeedback", true)
        colorTheme = SettingsManager.loadTheme("novacam.colorTheme", .dark)
        defaultCaptureMode = SettingsManager.loadMode("novacam.defaultMode", .auto)
        saveLocation = SettingsManager.loadBool("novacam.saveLocation", true)
    }

    private static func loadBool(_ key: String, _ def: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? def
    }
    private static func load(_ key: String, _ def: CaptureFormat) -> CaptureFormat {
        CaptureFormat(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? def
    }
    private static func load(_ key: String, _ def: GridType) -> GridType {
        GridType(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? def
    }
    private static func loadLang(_ key: String, _ def: SupportedLanguage) -> SupportedLanguage {
        SupportedLanguage(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? def
    }
    private static func loadTheme(_ key: String, _ def: ColorTheme) -> ColorTheme {
        ColorTheme(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? def
    }
    private static func loadMode(_ key: String, _ def: CaptureMode) -> CaptureMode {
        CaptureMode(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? def
    }

    func resetAll() {
        if let id = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: id)
        }
    }
}

enum ColorTheme: String, CaseIterable {
    case dark = "Dark"
    case system = "System"
    case highContrast = "High Contrast"

    var systemName: String {
        switch self {
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        case .highContrast: return "circle.hexagonpath.fill"
        }
    }
}
