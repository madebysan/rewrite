import Foundation

// Wraps UserDefaults for all app settings
final class UserSettings {
    static let shared = UserSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let apiKey = "apiKey"
        static let prompt = "rewritePrompt"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let launchAtLogin = "launchAtLogin"
        static let shortcutKeyCode = "shortcutKeyCode"
        static let shortcutModifiers = "shortcutModifiers"
    }

    // Default prompt for rewriting text
    static let defaultPrompt = """
        Rewrite the following text, fixing any grammar, spelling, and punctuation errors. \
        Preserve the original tone, style, and meaning. Do not add or remove information. \
        Only return the corrected text with no preamble, explanation, or quotes.
        """

    var apiKey: String {
        get { defaults.string(forKey: Keys.apiKey) ?? "" }
        set { defaults.set(newValue, forKey: Keys.apiKey) }
    }

    var prompt: String {
        get { defaults.string(forKey: Keys.prompt) ?? Self.defaultPrompt }
        set { defaults.set(newValue, forKey: Keys.prompt) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }

    // Store custom shortcut key code (nil = use default Cmd+Shift+R)
    var shortcutKeyCode: UInt32? {
        get {
            let val = defaults.integer(forKey: Keys.shortcutKeyCode)
            return val == 0 && !defaults.bool(forKey: "hasCustomShortcut") ? nil : UInt32(val)
        }
        set {
            if let newValue {
                defaults.set(Int(newValue), forKey: Keys.shortcutKeyCode)
                defaults.set(true, forKey: "hasCustomShortcut")
            } else {
                defaults.removeObject(forKey: Keys.shortcutKeyCode)
                defaults.set(false, forKey: "hasCustomShortcut")
            }
        }
    }

    var shortcutModifiers: UInt? {
        get {
            let val = defaults.integer(forKey: Keys.shortcutModifiers)
            return val == 0 && !defaults.bool(forKey: "hasCustomShortcut") ? nil : UInt(val)
        }
        set {
            if let newValue {
                defaults.set(Int(newValue), forKey: Keys.shortcutModifiers)
            } else {
                defaults.removeObject(forKey: Keys.shortcutModifiers)
            }
        }
    }
}
