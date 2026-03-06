import AppKit

// Manages the menu bar icon and dropdown menu
@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private weak var appDelegate: AppDelegate?
    private var animationTimer: Timer?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            setDefaultIcon(button)
        }

        let menu = NSMenu()

        // Show current shortcut in the menu
        let shortcutItem = NSMenuItem(title: "Rewrite Selected Text", action: nil, keyEquivalent: "")
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)

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

        // Listen for rewrite status changes
        TextGrabber.shared.onStatusChange = { [weak self] status in
            self?.handleStatus(status)
        }
    }

    private func setDefaultIcon(_ button: NSStatusBarButton) {
        if let image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Rewrite") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "R"
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
        setDefaultIcon(button)
    }
}
