import AppKit
import Carbon.HIToolbox
import UserNotifications

// Handles grabbing selected text via clipboard and pasting results back
@MainActor
final class TextGrabber {
    static let shared = TextGrabber()

    // Called when rewrite status changes (for menu bar feedback)
    var onStatusChange: ((RewriteStatus) -> Void)?

    enum RewriteStatus {
        case rewriting
        case done
        case error(String)
    }

    // Grab selected text, rewrite it, and paste back
    func grabRewriteAndPaste() {
        let pasteboard = NSPasteboard.general
        let changeCountBefore = pasteboard.changeCount

        // Save original clipboard contents to restore later
        let savedItems = saveClipboard(pasteboard)

        // Simulate Cmd+C to copy selection
        simulateKeyPress(keyCode: UInt16(kVK_ANSI_C), modifiers: .maskCommand)

        // Wait for Cmd+C to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // If changeCount didn't change, Cmd+C didn't copy anything
            guard pasteboard.changeCount != changeCountBefore else {
                self.restoreClipboard(pasteboard, items: savedItems)
                return
            }

            let selectedText = pasteboard.string(forType: .string) ?? ""
            guard !selectedText.isEmpty else {
                self.restoreClipboard(pasteboard, items: savedItems)
                return
            }

            self.onStatusChange?(.rewriting)

            // Call Claude API to rewrite
            Task {
                do {
                    let rewritten = try await ClaudeAPI.shared.rewrite(selectedText)

                    await MainActor.run {
                        pasteboard.clearContents()
                        pasteboard.setString(rewritten, forType: .string)

                        // Simulate Cmd+V to paste
                        self.simulateKeyPress(keyCode: UInt16(kVK_ANSI_V), modifiers: .maskCommand)

                        // Restore original clipboard after a short delay for paste to complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.restoreClipboard(pasteboard, items: savedItems)
                            self.onStatusChange?(.done)
                        }
                    }
                } catch {
                    NSLog("Rewrite error: \(error.localizedDescription)")
                    await MainActor.run {
                        self.restoreClipboard(pasteboard, items: savedItems)
                        self.onStatusChange?(.error(error.localizedDescription))
                        self.showErrorNotification(error.localizedDescription)
                    }
                }
            }
        }
    }

    // Save all clipboard items so we can restore them later
    private func saveClipboard(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        var saved: [NSPasteboardItem] = []
        for item in pasteboard.pasteboardItems ?? [] {
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            saved.append(copy)
        }
        return saved
    }

    // Restore previously saved clipboard contents
    private func restoreClipboard(_ pasteboard: NSPasteboard, items: [NSPasteboardItem]) {
        guard !items.isEmpty else { return }
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
    }

    // Show a macOS notification for errors
    private func showErrorNotification(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Rewrite"
        content.body = "Rewrite failed: \(message)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // Simulate a key press with modifiers using CGEvent
    private func simulateKeyPress(keyCode: UInt16, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = modifiers
        keyUp.flags = modifiers

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
