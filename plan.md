# Rewrite — macOS Text Rewriting App

## Overview

Rewrite is a macOS menu bar app that fixes grammar and spelling in any selected text, anywhere on your Mac. Select text, press a keyboard shortcut, and the corrected text replaces your selection instantly. No switching apps, no copy-pasting into ChatGPT or Claude — it just works in place.

**The problem it solves:** Today, fixing a paragraph means: copy text → open Claude → paste → ask it to fix grammar → wait → copy response → go back → paste. Rewrite collapses that into a single keystroke.

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| Language | Swift | Native macOS, no runtime dependencies |
| Framework | AppKit | Menu bar apps need AppKit (SwiftUI can't do `NSStatusItem` well) |
| AI | Claude API (claude-haiku-4-5-20251001) | Fast (~500ms), cheap (~$0.001/request), best grammar quality. Haiku is the right model for short text corrections — Opus would be overkill and slower |
| HTTP | URLSession | Built-in, no dependencies needed |
| Storage | UserDefaults | API key, prompt, shortcut — all simple key-value |
| Shortcut | HotKey (Swift package) | Clean wrapper around Carbon hotkey API. Avoids raw CGEvent tap complexity |
| Build | Xcode + Swift Package Manager | Standard macOS toolchain |

**Zero external dependencies** beyond the HotKey Swift package. No Electron, no localhost server, no npm.

## How It Works (User Flow)

```
1. User writes text in any app (Mail, Slack, Notes, VS Code, etc.)
2. User selects the text they want to fix
3. User presses Cmd+Shift+R
4. Rewrite:
   a. Simulates Cmd+C to copy selected text to clipboard
   b. Reads the clipboard contents
   c. Sends text to Claude API with the configured prompt
   d. Receives corrected text
   e. Writes corrected text to clipboard
   f. Simulates Cmd+V to paste it back, replacing the selection
5. User sees corrected text in place (~1-2 seconds total)
```

## Features (v0)

### F1: Menu Bar Presence
- `NSStatusItem` with a small icon (pencil or text icon, SF Symbol)
- Menu items: Settings, About, Quit
- No Dock icon (`LSUIElement = true` in Info.plist)
- Launch at login option in Settings

### F2: Global Keyboard Shortcut
- Default: Cmd+Shift+R
- Customizable in Settings (shortcut recorder)
- Uses the `HotKey` Swift package (https://github.com/soffes/HotKey)
- Must work when app is in background (global hotkey)

### F3: Text Grab + Replace
- On shortcut press:
  1. Save current clipboard contents (to restore later)
  2. Simulate Cmd+C via `CGEvent` to copy selection
  3. Read `NSPasteboard.general` for the selected text
  4. After API response, write result to pasteboard
  5. Simulate Cmd+V via `CGEvent` to paste
  6. Restore original clipboard contents
- Edge cases:
  - No text selected → do nothing (check if pasteboard changed after Cmd+C)
  - Empty response from API → don't paste, keep original
  - API error → don't paste, keep original (silent fail for v0)

### F4: Claude API Integration
- Direct HTTP call via URLSession (no SDK needed)
- Endpoint: `https://api.anthropic.com/v1/messages`
- Model: `claude-haiku-4-5-20251001`
- System prompt: the user's configured rewriting prompt
- User message: the selected text
- Max tokens: 4096 (generous for paragraph-level rewrites)
- Headers: `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`
- Parse response JSON for `content[0].text`

### F5: Onboarding Welcome Screen
- Shown on first launch (track with UserDefaults flag)
- Single window with:
  - App name + icon
  - Brief explanation: "Rewrite fixes grammar and spelling in any selected text. Press Cmd+Shift+R anywhere on your Mac."
  - API key input field (password-style, with paste support)
  - "Get an API key" link → opens https://console.anthropic.com/settings/keys
  - "Get Started" button (disabled until key is entered)
- Validates the API key with a test request before proceeding
- Stores key in UserDefaults (acceptable for personal use; Keychain for v1)

### F6: Settings Window
- Accessible from menu bar → Settings
- Three sections:
  1. **API Key** — text field to view/change the key (masked by default, reveal toggle)
  2. **Prompt** — text area with the rewriting prompt, editable
     - Default: "Rewrite the following text, fixing any grammar, spelling, or punctuation errors. Keep the same tone and meaning. Only return the corrected text, nothing else."
  3. **Shortcut** — shortcut recorder to change the hotkey (using HotKey's recorder or a simple key capture)
  4. **Launch at Login** — checkbox (uses `SMAppService` on macOS 13+)
- Changes save immediately (no Save button needed)

## File Structure

```
rewrite/
  rewrite.xcodeproj/
  rewrite/
    App.swift                  # App entry point, NSApplication setup
    AppDelegate.swift          # Menu bar setup, hotkey registration
    StatusBarController.swift  # NSStatusItem management, menu construction
    HotkeyManager.swift        # Global shortcut registration + handler
    TextGrabber.swift           # Clipboard read/write + CGEvent simulation
    ClaudeAPI.swift             # API client for Claude messages endpoint
    OnboardingWindow.swift      # First-launch welcome + API key entry
    SettingsWindow.swift        # Settings panel (API key, prompt, shortcut)
    UserSettings.swift          # UserDefaults wrapper for all stored values
    Assets.xcassets/            # App icon, menu bar icon
    Info.plist                  # LSUIElement, bundle ID, etc.
  Package.swift                # Swift Package Manager (HotKey dependency)
```

## Accessibility Permissions

**Critical:** The app needs **Accessibility permission** to simulate keystrokes (Cmd+C / Cmd+V via CGEvent). On first use:
- macOS will prompt the user to grant access in System Settings → Privacy & Security → Accessibility
- The app should detect if permission is missing and show a helpful message pointing to the right settings panel
- Without this permission, the app cannot function — it's the #1 setup friction point

## Default Prompt

```
Rewrite the following text, fixing any grammar, spelling, and punctuation errors. Preserve the original tone, style, and meaning. Do not add or remove information. Only return the corrected text with no preamble, explanation, or quotes.
```

This prompt is stored in UserDefaults and fully editable in Settings. The key design decision: the prompt is the **system message**, and the selected text is the **user message**. This keeps the API call clean and the prompt reusable.

## Implementation Order

Build in this sequence — each step produces something testable:

### Phase 1: Skeleton (get it running)
1. Create Xcode project, configure as menu bar app (LSUIElement)
2. Add HotKey package via SPM
3. Build `AppDelegate` + `StatusBarController` — menu bar icon appears with Quit
4. Register global hotkey (Cmd+Shift+R), log when triggered
5. **Test:** App appears in menu bar, hotkey logs to console

### Phase 2: Core Loop (the main feature)
6. Build `TextGrabber` — clipboard save/restore + CGEvent Cmd+C/Cmd+V simulation
7. Build `ClaudeAPI` — send text, get corrected text back
8. Wire hotkey → TextGrabber.grab() → ClaudeAPI.rewrite() → TextGrabber.paste()
9. **Test:** Select text in TextEdit, press shortcut, text gets corrected

### Phase 3: Settings + Onboarding
10. Build `UserSettings` wrapper (API key, prompt, shortcut, first-launch flag)
11. Build `SettingsWindow` with all fields
12. Build `OnboardingWindow` with API key entry + validation
13. Wire onboarding to show on first launch
14. **Test:** Fresh launch shows onboarding, settings persist across restarts

### Phase 4: Polish
15. Add accessibility permission detection + prompt
16. Handle edge cases (no selection, API errors, empty responses)
17. Add "Launch at Login" toggle
18. App icon (SF Symbol or programmatic)
19. **Test:** Full flow works end-to-end in multiple apps

## Out of Scope (v0)

These are explicitly deferred to v1+:
- **Multiple prompts / prompt switching** — v0 has one prompt
- **Visual feedback** (HUD, spinner, menu bar animation) — v0 is silent
- **Undo support** — if the rewrite is wrong, user uses Cmd+Z in the source app (which should work since we simulated a paste)
- **Text length limits / warnings** — v0 sends whatever is selected
- **Keychain storage** for API key — UserDefaults is fine for personal use
- **Offline / local LLM fallback** — Claude API only
- **History / log of rewrites** — no persistence of past corrections
- **Multiple AI providers** — Claude only
- **Distribution / signing / notarization** — personal use, run from Xcode or unsigned .app
- **Customizable model selection** — hardcoded to Haiku

## v1 Ideas (Future)

- Multiple prompts with a picker (radial menu on hotkey hold?)
- Floating HUD showing "Rewriting..." with progress
- Prompt library (community prompts, import/export)
- Keychain storage for API key
- Model picker (Haiku for speed, Sonnet for quality)
- History sidebar showing before/after for each rewrite
- Local LLM option (MLX) for offline use
- Signed + notarized .app with DMG distribution
- "Undo last rewrite" hotkey that restores the original text

## Risks & Considerations

| Risk | Mitigation |
|------|------------|
| Accessibility permission confusion | Clear onboarding message + deep link to System Settings |
| Clipboard race condition (Cmd+C hasn't completed before we read) | Small delay (100-200ms) after simulating Cmd+C before reading pasteboard |
| Some apps don't support Cmd+C/Cmd+V for text selection | Known limitation — works in 95%+ of apps. Terminal and some custom editors may not work |
| API latency makes it feel slow | Haiku is fast (~500ms-1s). Could add visual feedback in v1 |
| User accidentally triggers on non-text content | Check pasteboard type — only proceed if it contains string data |
| API key stored in plaintext (UserDefaults) | Acceptable for personal use. Keychain for v1 if distributing |

## Cost Estimate

At Claude Haiku pricing ($0.25/MTok input, $1.25/MTok output):
- Average paragraph: ~100 tokens in, ~100 tokens out
- Cost per rewrite: ~$0.00015
- 50 rewrites/day = ~$0.0075/day = ~$0.23/month

Effectively free.
