import AppKit

// Manages the menu bar icon and dropdown menu
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Use SF Symbol for the menu bar icon
            if let image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Rewrite") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "R"
            }
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
    }
}
