import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var onboardingWindow: OnboardingWindow?
    private var settingsWindow: SettingsWindow?
    private var aboutWindow: NSWindow?
    private var permissionTimer: Timer?
    private var wasPermissionsOK = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check accessibility permission
        checkAccessibilityPermission()

        // Set up menu bar
        statusBarController = StatusBarController(appDelegate: self)
        statusBarController?.setup()

        // Register global hotkey
        HotkeyManager.shared.register()

        // Start periodic permission monitoring
        wasPermissionsOK = AXIsProcessTrusted() && SettingsWindow.checkInputMonitoring()
        startPermissionMonitoring()

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
        if aboutWindow == nil {
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "About Rewrite"
            aboutWindow?.center()
            aboutWindow?.isReleasedWhenClosed = false

            let contentView = aboutWindow?.contentView ?? NSView()

            // Icon
            let iconView = NSImageView(frame: .zero)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            if let image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Rewrite") {
                let config = NSImage.SymbolConfiguration(pointSize: 36, weight: .light)
                iconView.image = image.withSymbolConfiguration(config)
                iconView.contentTintColor = .controlAccentColor
            }
            contentView.addSubview(iconView)

            // Title
            let titleLabel = NSTextField(labelWithString: "Rewrite")
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
            titleLabel.alignment = .center
            contentView.addSubview(titleLabel)

            // Version
            let versionLabel = NSTextField(labelWithString: "Version 1.2.0")
            versionLabel.translatesAutoresizingMaskIntoConstraints = false
            versionLabel.font = .systemFont(ofSize: 11)
            versionLabel.textColor = .secondaryLabelColor
            versionLabel.alignment = .center
            contentView.addSubview(versionLabel)

            // Description
            let descLabel = NSTextField(labelWithString: "Fix grammar and spelling with one keystroke.")
            descLabel.translatesAutoresizingMaskIntoConstraints = false
            descLabel.font = .systemFont(ofSize: 12)
            descLabel.textColor = .secondaryLabelColor
            descLabel.alignment = .center
            contentView.addSubview(descLabel)

            // "Made by santiagoalonso.com" clickable link
            let creditButton = NSButton(frame: .zero)
            creditButton.translatesAutoresizingMaskIntoConstraints = false
            creditButton.isBordered = false

            let madeBy = NSMutableAttributedString(
                string: "Made by ",
                attributes: [
                    .foregroundColor: NSColor.tertiaryLabelColor,
                    .font: NSFont.systemFont(ofSize: 11)
                ]
            )
            let link = NSAttributedString(
                string: "santiagoalonso.com",
                attributes: [
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .font: NSFont.systemFont(ofSize: 11)
                ]
            )
            madeBy.append(link)
            creditButton.attributedTitle = madeBy
            creditButton.target = self
            creditButton.action = #selector(openWebsite)
            contentView.addSubview(creditButton)

            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
                iconView.widthAnchor.constraint(equalToConstant: 48),
                iconView.heightAnchor.constraint(equalToConstant: 48),

                titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),

                versionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                versionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

                descLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                descLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 12),

                creditButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                creditButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8),
            ])
        }

        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openWebsite() {
        if let url = URL(string: "https://santiagoalonso.com") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !trusted {
            NSLog("Rewrite: Accessibility permission not granted. The app needs this to simulate Cmd+C/Cmd+V.")
        }
    }

    private func startPermissionMonitoring() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self else { return }
            let accessOK = AXIsProcessTrusted()
            let inputOK = SettingsWindow.checkInputMonitoring()
            let allOK = accessOK && inputOK

            if self.wasPermissionsOK && !allOK {
                // Permission was revoked
                DispatchQueue.main.async {
                    self.statusBarController?.showPermissionWarning(true)
                }
                self.showPermissionLostNotification(accessibility: !accessOK, inputMonitoring: !inputOK)
            } else if !self.wasPermissionsOK && allOK {
                // All permissions restored
                DispatchQueue.main.async {
                    self.statusBarController?.showPermissionWarning(false)
                }
            }

            self.wasPermissionsOK = allOK
        }
    }

    private func showPermissionLostNotification(accessibility: Bool, inputMonitoring: Bool) {
        var missing: [String] = []
        if accessibility { missing.append("Accessibility") }
        if inputMonitoring { missing.append("Input Monitoring") }

        let content = UNMutableNotificationContent()
        content.title = "Rewrite shortcut stopped working"
        content.body = "Missing permission: \(missing.joined(separator: " and ")). Open Rewrite settings or go to System Settings → Privacy & Security to fix."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "permission-lost",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
