import AppKit

// Manages the menu bar icon and dropdown menu
@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private weak var appDelegate: AppDelegate?
    private var animationTimer: Timer?
    private var statusMenuItem: NSMenuItem?
    private var hasPermissionWarning = false

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            setDefaultIcon(button)
        }

        let menu = NSMenu()

        // Manual trigger — same as the keyboard shortcut
        let rewriteItem = NSMenuItem(title: "Rewrite Selected Text", action: #selector(triggerRewrite), keyEquivalent: "")
        rewriteItem.target = self
        menu.addItem(rewriteItem)

        menu.addItem(NSMenuItem.separator())

        // Status indicator
        let allPermissionsOK = AXIsProcessTrusted() && SettingsWindow.checkInputMonitoring()
        let statusTitle = allPermissionsOK ? "Status: Ready" : "Status: Missing Permissions"
        statusMenuItem = NSMenuItem(title: statusTitle, action: allPermissionsOK ? nil : #selector(AppDelegate.openSettings), keyEquivalent: "")
        statusMenuItem?.target = allPermissionsOK ? nil : appDelegate
        statusMenuItem?.isEnabled = !allPermissionsOK
        if !allPermissionsOK {
            statusMenuItem?.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning")
            statusMenuItem?.image?.isTemplate = true
        }
        menu.addItem(statusMenuItem!)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(appDelegate?.openSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem(
            title: "About Rewrite",
            action: #selector(appDelegate?.openAbout),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit Rewrite",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu

        // Show warning icon if permissions missing on launch
        if !allPermissionsOK {
            hasPermissionWarning = true
            if let button = statusItem?.button {
                setWarningIcon(button)
            }
        }

        // Listen for rewrite status changes
        TextGrabber.shared.onStatusChange = { [weak self] status in
            self?.handleStatus(status)
        }
    }

    func showPermissionWarning(_ show: Bool) {
        hasPermissionWarning = show
        guard let button = statusItem?.button else { return }

        if show {
            setWarningIcon(button)
            statusMenuItem?.title = "Status: Missing Permissions"
            statusMenuItem?.action = #selector(AppDelegate.openSettings)
            statusMenuItem?.target = appDelegate
            statusMenuItem?.isEnabled = true
            statusMenuItem?.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Warning")
            statusMenuItem?.image?.isTemplate = true
        } else {
            setDefaultIcon(button)
            statusMenuItem?.title = "Status: Ready"
            statusMenuItem?.action = nil
            statusMenuItem?.isEnabled = false
            statusMenuItem?.image = nil
        }
    }


    @objc private func triggerRewrite() {
        TextGrabber.shared.grabRewriteAndPaste()
    }

    private func setDefaultIcon(_ button: NSStatusBarButton) {
        if let image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Rewrite") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "R"
        }
    }

    private func setWarningIcon(_ button: NSStatusBarButton) {
        if let image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Rewrite — missing permissions") {
            image.isTemplate = true
            button.image = image
        }
    }

    private func handleStatus(_ status: TextGrabber.RewriteStatus) {
        guard let button = statusItem?.button else { return }

        switch status {
        case .rewriting:
            startAnimation(button)
        case .done:
            stopAnimation(button)
        case .error:
            stopAnimation(button)
            // Brief flash to red to indicate failure
            if let errorImage = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Error") {
                errorImage.isTemplate = true
                button.image = errorImage
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.setDefaultIcon(button)
                }
            }
        }
    }

    private func startAnimation(_ button: NSStatusBarButton) {
        // Cycle through ellipsis-style SF Symbols to show activity
        let frames = ["ellipsis", "ellipsis.circle", "ellipsis.circle.fill"]
        var frameIndex = 0

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            guard self != nil else { return }
            if let image = NSImage(systemSymbolName: frames[frameIndex % frames.count], accessibilityDescription: "Rewriting...") {
                image.isTemplate = true
                button.image = image
            }
            frameIndex += 1
        }
    }

    private func stopAnimation(_ button: NSStatusBarButton) {
        animationTimer?.invalidate()
        animationTimer = nil
        if hasPermissionWarning {
            setWarningIcon(button)
        } else {
            setDefaultIcon(button)
        }
    }
}
