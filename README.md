# Deixis

Agents don't understand *this*. Deixis does.

Deixis is a macOS menu bar tool. Press a hotkey, click one element in any app, type a note, press Enter. The clipboard now holds a Markdown payload with the element's role, label, accessibility identifier, frame, and ancestry, plus a cropped PNG, so a coding agent can find the right file on the first try. Appshots gives your agent the window; Deixis gives it the element.

![demo](docs/demo.gif)

## Install

1. Download the dmg from Releases and drag Deixis to Applications. (Until then, build from source below.)
2. Launch Deixis. It has no Dock icon; look for the pointing hand in the menu bar.
3. Grant the permissions it asks for, in this order:
   - **Accessibility**: reads what is under your cursor and listens for the hotkey. Without it nothing works.
   - **Screen Recording**: captures the pixels of the element. Asked on first launch; macOS applies a fresh grant after a relaunch.
   - There is no third prompt in v0.1. Nothing leaves the machine: no network, no telemetry, no accounts.

## Use

- **⌃⌃** (double-tap Control within 350 ms) opens the overlay. Hover to see the highlight and the label `role · identifier`. The label tells you before you click whether the element has a declared identifier, only a label, a symbol name, or no accessibility tree at all.
- **Click** the element, type what should change, **Enter**. **Esc** at any point cancels; nothing is written and the clipboard is untouched.
- **Paste** into your agent. Each capture also lands in `~/Pictures/Deixis/` as a PNG and a JSON sidecar that validates against `schema/capture.schema.json`.

Example payload:

```
## Deixis capture (fix)
Image: /Users/you/Pictures/Deixis/deixis-simulator-20260913-153012-k7q2.png
App: Simulator (com.example.myapp) · Window: iPhone 17 Pro
Captured: 2026-09-13 15:30 · Image region: 450×130 pt @2x (element + 40 pt)

### Target element
button · id=captureButton
Frame: x=43 y=894 w=370 h=50
Path: application > window > group > group > button#captureButton

### Note
make this rounded, match the other pills
```

## Settings and the ball

- **Settings** (⌘, from the menu bar): the hotkey, recorded by pressing it, either a key with modifiers or a double-tap of one modifier; the capture folder and how it is organized; the floating ball toggle; and My Apps.
- **Fix or reference is inferred.** Anything in the iOS Simulator, anything built on this Mac (found through DerivedData or a folder with an Xcode project or Package.swift), and anything signed with your own Team ID counts as yours. My Apps is only for what inference misses. When a project folder is found, the payload carries a `Project:` line.
- **Captures are tagged in Finder** with Deixis, the app, fix or reference, and the project. Optionally sorted into subfolders by app, project, or month.
- **The floating ball** rests as a faint disc, docks to the nearest edge when ignored, wakes as the cursor approaches, and starts a capture on click. Drag it to move it. Turn it off in Settings; the hotkey works either way.
- **Drawn frames and text.** Drag on the overlay to capture a frame and every element inside it. When nothing has an identifier, the text in the image is recognized and listed, and the nearest labeled elements are named.

## Agent compatibility

| Agent | Paste | Image | Status |
|---|---|---|---|
| Claude Code | Markdown text | reads the PNG from the `Image:` path | expected to work; not yet verified end to end |
| Cursor | Markdown text | reads the path | untested |
| Codex CLI | Markdown text | `view_image` on the path | untested |
| Gemini CLI / Antigravity | Markdown text | untested | untested |

The image path comes first in the payload because terminal agents receive only the text representation on paste.

## Known limitations

- Element quality depends on the target app's accessibility implementation. SwiftUI, AppKit, and the iOS Simulator work well. Electron and Chromium apps (Claude, VS Code, Slack, Chrome) build their tree only when asked; Deixis asks on first contact, and the first hover over such an app can take about half a second to sharpen. Figma, games, and custom-drawn UIs often expose little; Deixis then records `element: null`, says so in the payload, and still gives the agent the image and your note.
- Hover picks the smallest real control near the cursor and sticks to it across padding; a whole-window group appears only in blank areas. Press Option to step to the parent.
- iOS Simulator: the per-app hit test reaches the simulated app's tree through public API, and the system-wide hit test returns the same element (confirmed Sep 13, 2026 on Xcode 26.6, iPhone 17 Pro, iOS 26.5). The tree is built lazily on first access; Deixis retries for up to 600 ms before giving up.
- Which app the Simulator is showing is inferred from the most recently launched simulated process. With two apps launched in one device, the newer one is assumed.
- Safari and Chrome tab URLs are not read in v0.1, so `url` is always null and the localhost rule for fix mode is dormant.
- Menus and popovers stay open under the overlay, but an element inside a menu of another app may not resolve.
- One hotkey, one capture folder, no Settings. Both are constants in v0.1.

## Build from source

Requires Xcode 26 and macOS 15 or later.

```bash
xcodebuild -project Deixis.xcodeproj -scheme Deixis -configuration Release build
```

The project signs with the developer's Apple Development identity. To build on another machine, set your own team in Signing & Capabilities, or sign ad hoc with `CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual` on the command line. Note that ad hoc signatures change on every build, so macOS asks for Accessibility and Screen Recording again after each rebuild; a real signing identity avoids that.

Tests:

```bash
xcodebuild -project Deixis.xcodeproj -scheme Deixis test
```
