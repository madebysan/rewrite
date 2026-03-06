import AppKit
import Carbon.HIToolbox

// Handles grabbing selected text via clipboard and pasting results back
@MainActor
final class TextGrabber {
    static let shared = TextGrabber()

    // Grab selected text, rewrite it, and paste back
    func grabRewriteAndPaste() {
        let pasteboard = NSPasteboard.general
        let changeCountBefore = pasteboard.changeCount

        // Simulate Cmd+C to copy selection
        simulateKeyPress(keyCode: UInt16(kVK_ANSI_C), modifiers: .maskCommand)

        // Wait for Cmd+C to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // If changeCount didn't change, Cmd+C didn't copy anything
            guard pasteboard.changeCount != changeCountBefore else { return }

            let selectedText = pasteboard.string(forType: .string) ?? ""
            guard !selectedText.isEmpty else { return }

            // Call Claude API to rewrite
            Task {
                do {
                    let rewritten = try await ClaudeAPI.shared.rewrite(selectedText)

                    await MainActor.run {
                        pasteboard.clearContents()
                        pasteboard.setString(rewritten, forType: .string)

                        // Simulate Cmd+V to paste
                        self.simulateKeyPress(keyCode: UInt16(kVK_ANSI_V), modifiers: .maskCommand)
                    }
                } catch {
                    NSLog("Rewrite error: \(error.localizedDescription)")
                }
            }
        }
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
