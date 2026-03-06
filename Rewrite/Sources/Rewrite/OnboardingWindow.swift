import AppKit

// First-launch welcome screen with API key entry
final class OnboardingWindow: NSWindowController {
    private var apiKeyField: NSSecureTextField!
    private var getStartedButton: NSButton!
    private var statusLabel: NSTextField!
    private var validating = false

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Rewrite"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true

        // App icon
        let iconView = NSImageView(frame: .zero)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        if let image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Rewrite") {
            let config = NSImage.SymbolConfiguration(pointSize: 48, weight: .light)
            iconView.image = image.withSymbolConfiguration(config)
            iconView.contentTintColor = .controlAccentColor
        }
        contentView.addSubview(iconView)

        // Title
        let titleLabel = NSTextField(labelWithString: "Rewrite")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)

        // Description
        let descLabel = NSTextField(wrappingLabelWithString:
            "Rewrite fixes grammar and spelling in any selected text on your Mac.\n\n" +
            "Select text anywhere, press Cmd+Shift+R, and the corrected text replaces your selection instantly.\n\n" +
            "To get started, enter your Anthropic API key below."
        )
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.alignment = .center
        descLabel.textColor = .secondaryLabelColor
        contentView.addSubview(descLabel)

        // API key field
        apiKeyField = NSSecureTextField(frame: .zero)
        apiKeyField.translatesAutoresizingMaskIntoConstraints = false
        apiKeyField.placeholderString = "sk-ant-..."
        apiKeyField.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        apiKeyField.target = self
        apiKeyField.action = #selector(apiKeyChanged)
        contentView.addSubview(apiKeyField)

        // "Get an API key" link
        let linkButton = NSButton(title: "Get an API key →", target: self, action: #selector(openAPIKeyPage))
        linkButton.translatesAutoresizingMaskIntoConstraints = false
        linkButton.isBordered = false
        linkButton.contentTintColor = .linkColor
        linkButton.font = .systemFont(ofSize: 12)
        contentView.addSubview(linkButton)

        // Status label (for validation feedback)
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.alignment = .center
        contentView.addSubview(statusLabel)

        // Get Started button
        getStartedButton = NSButton(title: "Get Started", target: self, action: #selector(getStarted))
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.bezelStyle = .rounded
        getStartedButton.controlSize = .large
        getStartedButton.keyEquivalent = "\r"
        getStartedButton.isEnabled = false
        contentView.addSubview(getStartedButton)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),

            descLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            apiKeyField.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            apiKeyField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60),
            apiKeyField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60),

            linkButton.topAnchor.constraint(equalTo: apiKeyField.bottomAnchor, constant: 6),
            linkButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: linkButton.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),

            getStartedButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            getStartedButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            getStartedButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    @objc private func apiKeyChanged() {
        let key = apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        getStartedButton.isEnabled = !key.isEmpty
        statusLabel.stringValue = ""
    }

    @objc private func openAPIKeyPage() {
        if let url = URL(string: "https://console.anthropic.com/settings/keys") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func getStarted() {
        let key = apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        guard !validating else { return }

        validating = true
        getStartedButton.isEnabled = false
        statusLabel.stringValue = "Validating API key..."
        statusLabel.textColor = .secondaryLabelColor

        Task {
            let valid = await ClaudeAPI.shared.validateKey(key)
            await MainActor.run {
                self.validating = false
                if valid {
                    UserSettings.shared.apiKey = key
                    UserSettings.shared.hasCompletedOnboarding = true
                    self.statusLabel.stringValue = ""
                    self.close()
                } else {
                    self.statusLabel.stringValue = "Invalid API key. Please check and try again."
                    self.statusLabel.textColor = .systemRed
                    self.getStartedButton.isEnabled = true
                }
            }
        }
    }
}
