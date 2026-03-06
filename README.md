<p align="center">
  <img src="assets/app-icon.png" width="128" height="128" alt="Rewrite app icon">
</p>
<h1 align="center">Rewrite</h1>
<p align="center">Fix grammar and spelling in any selected text with one keystroke.<br>
A lightweight macOS menu bar app powered by Claude.</p>
<p align="center"><strong>Version 1.0.0</strong> · macOS 13+ · Apple Silicon & Intel</p>
<p align="center"><a href="https://github.com/madebysan/rewrite/releases/latest"><strong>Download Rewrite</strong></a></p>

---

## How It Works

1. Select text anywhere on your Mac (Notes, Mail, Slack, VS Code, etc.)
2. Press **Cmd + Shift + R**
3. The text is corrected in place — grammar, spelling, and punctuation fixed instantly

No app switching. No copy-pasting. Just select, press, done.

## Setup

1. **Download** the DMG from [Releases](https://github.com/madebysan/rewrite/releases/latest)
2. **Drag** Rewrite.app to Applications
3. **Launch** Rewrite — it will appear in your menu bar
4. **Enter your API key** — you'll need an [Anthropic API key](https://console.anthropic.com/settings/keys)
5. **Grant Accessibility permission** — macOS will prompt you (System Settings → Privacy & Security → Accessibility)

## Features

- **Global shortcut** — works in any app, even when Rewrite is in the background
- **Customizable prompt** — edit the rewriting instructions in Settings
- **Customizable shortcut** — change the hotkey in Settings
- **Launch at login** — optional, toggle in Settings
- **Fast** — uses Claude Haiku for ~500ms response times
- **Cheap** — costs ~$0.0002 per rewrite (pennies per month)

## Requirements

- macOS 13 (Ventura) or later
- An [Anthropic API key](https://console.anthropic.com/settings/keys)
- Accessibility permission (required to simulate copy/paste)

## Tech Stack

- Swift + AppKit
- Claude API (Haiku)
- [HotKey](https://github.com/soffes/HotKey) for global shortcuts
- Zero other dependencies

## License

[MIT](LICENSE)
