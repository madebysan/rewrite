import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var onboardingWindow: OnboardingWindow?
    private var settingsWindow: SettingsWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check accessibility permission
        checkAccessibilityPermission()

        // Set up menu bar
        statusBarController = StatusBarController(appDelegate: self)
        statusBarController?.setup()

        // Register global hotkey
        HotkeyManager.shared.register()

        // Show onboarding if first launch
        if !UserSettings.shared.hasCompletedOnboarding {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        onboardingWindow = OnboardingWindow()
        onboardingWindow?.showWindow(nil)
        onboardingWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow()
        }
        settingsWindow?.showWindow(nil)
        settingsWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openAbout() {
        let alert = NSAlert()
        alert.messageText = "Rewrite"
        alert.informativeText = "Version 1.0.0\n\nFixes grammar and spelling in any selected text with one keystroke.\n\nMade by santiagoalonso.com"
        alert.alertStyle = .informational

        if let icon = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Rewrite") {
            let config = NSImage.SymbolConfiguration(pointSize: 48, weight: .light)
            alert.icon = icon.withSymbolConfiguration(config)
        }

        alert.runModal()
    }

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !trusted {
            NSLog("Rewrite: Accessibility permission not granted. The app needs this to simulate Cmd+C/Cmd+V.")
        }
    }
}
