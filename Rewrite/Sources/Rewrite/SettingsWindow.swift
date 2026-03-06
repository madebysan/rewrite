import AppKit
import Carbon.HIToolbox
import ServiceManagement

// Settings window with API key, prompt, shortcut, and launch at login
final class SettingsWindow: NSWindowController, NSWindowDelegate {
    private var apiKeyField: NSSecureTextField!
    private var showKeyButton: NSButton!
    private var visibleApiKeyField: NSTextField!
    private var isKeyVisible = false
    private var promptField: NSTextView!
    private var launchAtLoginCheckbox: NSButton!
    private var shortcutLabel: NSTextField!

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Rewrite Settings"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
        ])

        // --- API Key ---
        let apiLabel = makeLabel("API Key")
        stackView.addArrangedSubview(apiLabel)

        let apiKeyContainer = NSStackView()
        apiKeyContainer.orientation = .horizontal
        apiKeyContainer.spacing = 8

        apiKeyField = NSSecureTextField(frame: .zero)
        apiKeyField.stringValue = UserSettings.shared.apiKey
        apiKeyField.placeholderString = "sk-ant-..."
        apiKeyField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        apiKeyField.target = self
        apiKeyField.action = #selector(apiKeyChanged)

        visibleApiKeyField = NSTextField(frame: .zero)
        visibleApiKeyField.stringValue = UserSettings.shared.apiKey
        visibleApiKeyField.placeholderString = "sk-ant-..."
        visibleApiKeyField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        visibleApiKeyField.isHidden = true
        visibleApiKeyField.target = self
        visibleApiKeyField.action = #selector(visibleApiKeyChanged)

        showKeyButton = NSButton(title: "Show", target: self, action: #selector(toggleKeyVisibility))
        showKeyButton.bezelStyle = .rounded
        showKeyButton.controlSize = .small
        showKeyButton.setContentHuggingPriority(.required, for: .horizontal)

        apiKeyContainer.addArrangedSubview(apiKeyField)
        apiKeyContainer.addArrangedSubview(visibleApiKeyField)
        apiKeyContainer.addArrangedSubview(showKeyButton)

        // Make the text fields expand
        apiKeyField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        visibleApiKeyField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stackView.addArrangedSubview(apiKeyContainer)
        apiKeyContainer.translatesAutoresizingMaskIntoConstraints = false
        apiKeyContainer.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        // --- Prompt ---
        let promptLabel = makeLabel("Rewriting Prompt")
        stackView.addArrangedSubview(promptLabel)

        let scrollView = NSScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        promptField = NSTextView(frame: .zero)
        promptField.string = UserSettings.shared.prompt
        promptField.font = .systemFont(ofSize: 13)
        promptField.isRichText = false
        promptField.isAutomaticQuoteSubstitutionEnabled = false
        promptField.isAutomaticDashSubstitutionEnabled = false
        promptField.textContainerInset = NSSize(width: 8, height: 8)
        promptField.isVerticallyResizable = true
        promptField.isHorizontallyResizable = false
        promptField.textContainer?.widthTracksTextView = true
        promptField.delegate = self

        scrollView.documentView = promptField
        stackView.addArrangedSubview(scrollView)

        scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        scrollView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        let resetPromptButton = NSButton(title: "Reset to Default", target: self, action: #selector(resetPrompt))
        resetPromptButton.bezelStyle = .rounded
        resetPromptButton.controlSize = .small
        stackView.addArrangedSubview(resetPromptButton)

        // --- Shortcut ---
        let shortcutSectionLabel = makeLabel("Keyboard Shortcut")
        stackView.addArrangedSubview(shortcutSectionLabel)

        let shortcutContainer = NSStackView()
        shortcutContainer.orientation = .horizontal
        shortcutContainer.spacing = 8

        shortcutLabel = NSTextField(labelWithString: "Cmd + Shift + R")
        shortcutLabel.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        shortcutContainer.addArrangedSubview(shortcutLabel)

        let recordButton = NSButton(title: "Change...", target: self, action: #selector(recordShortcut))
        recordButton.bezelStyle = .rounded
        recordButton.controlSize = .small
        shortcutContainer.addArrangedSubview(recordButton)

        let resetShortcutButton = NSButton(title: "Reset", target: self, action: #selector(resetShortcut))
        resetShortcutButton.bezelStyle = .rounded
        resetShortcutButton.controlSize = .small
        shortcutContainer.addArrangedSubview(resetShortcutButton)

        stackView.addArrangedSubview(shortcutContainer)

        // --- Launch at Login ---
        let separator = NSBox()
        separator.boxType = .separator
        stackView.addArrangedSubview(separator)
        separator.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true

        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(toggleLaunchAtLogin))
        launchAtLoginCheckbox.state = UserSettings.shared.launchAtLogin ? .on : .off
        stackView.addArrangedSubview(launchAtLoginCheckbox)
    }

    private func makeLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        return label
    }

    @objc private func apiKeyChanged() {
        let key = apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        UserSettings.shared.apiKey = key
        visibleApiKeyField.stringValue = key
    }

    @objc private func visibleApiKeyChanged() {
        let key = visibleApiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        UserSettings.shared.apiKey = key
        apiKeyField.stringValue = key
    }

    @objc private func toggleKeyVisibility() {
        isKeyVisible.toggle()
        apiKeyField.isHidden = isKeyVisible
        visibleApiKeyField.isHidden = !isKeyVisible
        showKeyButton.title = isKeyVisible ? "Hide" : "Show"
    }

    @objc private func resetPrompt() {
        promptField.string = UserSettings.defaultPrompt
        UserSettings.shared.prompt = UserSettings.defaultPrompt
    }

    @objc private func recordShortcut() {
        shortcutLabel.stringValue = "Press shortcut..."
        shortcutLabel.textColor = .systemOrange

        // Listen for the next key press
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            // Require at least one modifier
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !mods.isEmpty else { return event }

            let keyCode = UInt32(event.keyCode)
            HotkeyManager.shared.updateShortcut(keyCode: keyCode, modifiers: mods)

            self.shortcutLabel.stringValue = self.formatShortcut(modifiers: mods, keyCode: event.keyCode)
            self.shortcutLabel.textColor = .labelColor

            // Remove this monitor (one-shot)
            return nil
        }
    }

    @objc private func resetShortcut() {
        HotkeyManager.shared.resetToDefault()
        shortcutLabel.stringValue = "Cmd + Shift + R"
        shortcutLabel.textColor = .labelColor
    }

    @objc private func toggleLaunchAtLogin() {
        let enabled = launchAtLoginCheckbox.state == .on
        UserSettings.shared.launchAtLogin = enabled

        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Failed to update launch at login: \(error)")
            }
        }
    }

    // Format modifier flags + key code into a readable string
    private func formatShortcut(modifiers: NSEvent.ModifierFlags, keyCode: UInt16) -> String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("Ctrl") }
        if modifiers.contains(.option) { parts.append("Opt") }
        if modifiers.contains(.shift) { parts.append("Shift") }
        if modifiers.contains(.command) { parts.append("Cmd") }

        // Map common key codes to readable names
        let keyName: String
        switch Int(keyCode) {
        case kVK_ANSI_A: keyName = "A"
        case kVK_ANSI_B: keyName = "B"
        case kVK_ANSI_C: keyName = "C"
        case kVK_ANSI_D: keyName = "D"
        case kVK_ANSI_E: keyName = "E"
        case kVK_ANSI_F: keyName = "F"
        case kVK_ANSI_G: keyName = "G"
        case kVK_ANSI_H: keyName = "H"
        case kVK_ANSI_I: keyName = "I"
        case kVK_ANSI_J: keyName = "J"
        case kVK_ANSI_K: keyName = "K"
        case kVK_ANSI_L: keyName = "L"
        case kVK_ANSI_M: keyName = "M"
        case kVK_ANSI_N: keyName = "N"
        case kVK_ANSI_O: keyName = "O"
        case kVK_ANSI_P: keyName = "P"
        case kVK_ANSI_Q: keyName = "Q"
        case kVK_ANSI_R: keyName = "R"
        case kVK_ANSI_S: keyName = "S"
        case kVK_ANSI_T: keyName = "T"
        case kVK_ANSI_U: keyName = "U"
        case kVK_ANSI_V: keyName = "V"
        case kVK_ANSI_W: keyName = "W"
        case kVK_ANSI_X: keyName = "X"
        case kVK_ANSI_Y: keyName = "Y"
        case kVK_ANSI_Z: keyName = "Z"
        default: keyName = "Key(\(keyCode))"
        }

        parts.append(keyName)
        return parts.joined(separator: " + ")
    }

    func windowWillClose(_ notification: Notification) {
        // Save prompt when window closes
        UserSettings.shared.prompt = promptField.string
    }
}

extension SettingsWindow: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        UserSettings.shared.prompt = promptField.string
    }
}
