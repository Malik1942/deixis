# Deixis

Agents don't understand *this*. Deixis does.

Deixis is a macOS menu bar tool. Press a hotkey, click one element in any app, type a note, press Enter. The clipboard now holds a Markdown payload with the element's role, label, accessibility identifier, frame, and ancestry, plus a cropped PNG, so a coding agent can find the right file on the first try. Appshots gives your agent the window; Deixis gives it the element.

![demo](docs/demo.gif)

## Install

1. [Download Deixis.dmg](https://github.com/Malik1942/deixis/releases/latest/download/Deixis.dmg) and drag Deixis to Applications. To update, do the same over the old copy; the permissions carry over.
2. Launch Deixis. It has no Dock icon; look for the pointing hand in the menu bar.
3. Grant the permissions it asks for, in this order:
   - **Accessibility**: reads what is under your cursor and listens for the hotkey. Without it nothing works.
   - **Screen Recording**: captures the pixels of the element. Asked on first launch; macOS applies a fresh grant after a relaunch, and offers to do that itself.
   - There is no third prompt. Nothing leaves the machine: no telemetry, no accounts. The one request Deixis makes is a daily check for a newer release on GitHub, which tells you when there is one; turn it off in Settings › General.
4. A one-page guide opens: every action, its hotkey, and the gestures on the overlay. Close it; reopen it any time from Settings › General (Deixis Help). It also says how long images are kept. The first three times each action opens, a line at the bottom of the screen names its gestures, then fades by itself.

## Use

- **⌃⌃** (double-tap Control within 350 ms) opens the overlay. Hover to see the highlight and the label `role · identifier`. The label tells you before you click whether the element has a declared identifier, only a label, a symbol name, or no accessibility tree at all.
- **Click** the element, or press **Return** while it is highlighted, type what should change, **Enter**. **Esc** at any point cancels; nothing is written and the clipboard is untouched.
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

## The other actions

Point is the primary action. Four one-shot actions share its gesture and sit on the ball's ring (hold the ball for half a second; a shorter press is a click, which is Point) and in the menu bar. Actions that make an image keep a file for the retention period; actions that make text or a value keep nothing.

- **Snap**: drag a region or click a window. PNG to the clipboard and the folder; hold ⌥ at release for clipboard only.
- **Text**: drag a region or click an element. Recognized lines to the clipboard, nothing on disk.
- **Color**: a magnifier follows the cursor; arrows nudge by a pixel, click copies the value. Hex, rgb, hsl, or SwiftUI, in sRGB or Display P3, chosen in Settings.
- **Cut**: drag or click; the subject is cut onto a transparent background, PNG to the clipboard and the folder.
- **Retention**: images older than the setting (30 days by default) move to the Trash on launch and daily. Captures an agent marked resolved stay.
- **Return is a click** in every action: it takes the highlighted window, element, or pixel where the cursor is. Esc cancels everywhere.
- Each action has a hotkey: ⌃⌥ and its number in the menu, ⌃⌥1 Point through ⌃⌥5 Cut. The ring shows the numbers. Re-record or clear any of them in Settings, which warns when a chord is also a macOS shortcut.

## See what changed

After a capture of your own app and an agent's edit, run the app again. Each time that app launches or comes to the front within a day, Deixis finds the same element by its identifier (then by role and label, then by the nearest frame), captures it, and when it looks different records the git facts and adds an iteration under the original capture. **Show before & after** in the menu opens the newest one: the images side by side with one zoom, the diff stat and the files touched beneath, your note above, every iteration in a strip. The switch is **Collect iterations** in Settings › Captures.

Git facts need a project folder. Deixis finds it for Xcode builds, including apps running in the Simulator, through DerivedData; the sidecar records the commit at capture time, and the diff runs against it, or against the working tree when nothing was committed. Deixis never commits, never installs hooks, never talks to the network for this.

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
- The desktop and the menu bar are targets too. Desktop icons resolve through Finder, desktop widgets through Notification Center (the payload names the widget's window, for example `Month`), menu titles through the app that owns the menu bar, status items through Control Center or the app that placed them (`menuExtra · id=com.apple.menuextra.wifi`), and Dock items through the Dock. A normal window in front of any of these wins, since that is what is visible. Snap and Cut on a click still take a normal window only.
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
