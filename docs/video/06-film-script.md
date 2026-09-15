# Locant demo: film script (product-film pipeline), v3

Capture-and-edit contract for the footage the submission video uses, revised after the Locant rename and the v2 review.
The narration, section order, and timing live in `01-full-script.md`.

```
FILM: Locant demo footage   SURFACE: Locant 0.7.0 (macOS menu bar app) over the iOS Simulator (Oryne) + Cursor (the agent)
PLACEMENT: inside the 3-minute Palantir pitch video (sections 1, 2, 3); the loop take also becomes site/assets/demo.mp4
CANVAS: 2560x1440 @60   TARGET LENGTH: loop ~22 s, verify ~10 s, ball ~8 s, three 1 s hover cutaways, two 4 s any-agent cutaways
PATH: desktop, full-bleed (FILL=1), Screen-Studio grammar as revised below
POINTER: real pointer, baked in, moved on curved Fitts-timed paths with a soft settle (the `human` command in the input helper);
         the composite adds click rings only (CURSOR_STYLE=none)
VIBE: Quiet Mac: no music, the clips ship silent under the narrator
```

## What v2 got wrong, and the v3 rules

The v2 review (Sep 15) rejected four things. Each becomes a rule here.

1. **The cursor moved like a script.** Straight lines at constant easing. v3: every move is a curved path whose
   duration grows with distance, with a small overshoot and settle, and a beat of stillness before every click.
   Moves between nearby targets stay short; there are no long glides across the screen.
2. **The frame was too wide.** At 1.0 and 1.7 the viewer had no idea where to look. v3: the camera lives at 2.2 to
   3.0 and follows the cursor (a keyframe at every waypoint, Screen-Studio style). Wide (1.0) exists only for the
   dim in scene 1 and for the pull-back that reveals the Before & After window opening.
3. **Zooms without a reason.** v3: a camera move happens only when the subject changes: the cursor arrives at a
   new control, a payoff appears somewhere else, or a window opens. Nothing moves while the viewer is reading.
   Every move is a single ease, no chains of small corrections.
4. **The Terminal was ugly.** v3: the agent is Cursor. The payload lands in Cursor's Agent chat, the agent greps and
   edits, and the diff shows in the editor. Codex is a 4 s cutaway only.

## Stage

- Wallpaper: Tahoe (the site's captures use Tahoe Day, so the video and the site read as one thing). Desktop icons
  hidden or moved off the capture region.
- One display in use, the MacBook's 2056x1329 pt. Capture region 2056x1156 pt at (0, 0) for every take except the
  hotkey opener, which captures the full 2056x1329 so the hint line at y 1216 is in frame (the compositor's CROP
  brings it back to 16:9).
- Simulator, iPhone 17 Pro, Oryne on the Ocean screen at (11, 48) 456x972, Reduce Motion on so the orbs hold still.
- Cursor at (517, 101) 1418x863 on `~/Documents/inspire-ocean`, a fresh Agent chat open on the right, UI zoomed two
  steps, no toasts, no earlier chats in the pane.
- Locant 0.7.0 from /Applications, ball docked at the right edge, hint counts reset before the opener.
- Dia and the Claude app hidden. Pre-roll: a passive still of the region, checked, before every take.
- Oryne's tree committed; the agent's edit is reverted after Take B and the library reseeded.

## Scenes

| # | Scene | Interaction the viewer sees | Payoff to read | Camera |
|---|---|---|---|---|
| 1 | Hotkey | Two Control taps | The desktop dims; the hint line at the bottom names the gestures | Wide 1.0, still |
| 2 | Hover | Cursor onto the Product Ideas orb, to Cooking, back | `button · oceanCurrent.product ideas`, then `.cooking` | 2.4 on the orb; follow-pan to Cooking and back at 2.4 |
| 3 | Note | Click; type the note; Enter | Placeholder "What should change?", the note, toast `Copied · oceanCurrent.product ideas` | Hold at 2.4; the note field opens under the orb |
| 4 | Paste | Cursor moves to Cursor's chat; click; ⌘V; Enter | `## Locant capture (fix)`, `Image:` first, `id=oceanCurrent.product ideas` | One ease to 2.2 on the chat input as the cursor travels; still while the payload is read |
| 5 | Agent finds it | Nothing; the agent works | The grep for `oceanCurrent`, the file it opens, the diff in the editor | Still on the chat until the diff appears, then one ease to the editor |
| 6 | Verify | Menu bar hand; Show before & after; divider slide; Flip; click to flip | Note, identifier line, the bigger orb sweeping over the small one, `1 file changed`, the file name | 2.6 on the menu; pull to 1.0 as the window opens; 2.6 on the window; still through the slide and flips |
| 7 | Ball | Approach; wake; hand; hold; ring; release on Color; magnifier to the card; click | Ring with Snap / Cut / Text / Color; `#353537` in the magnifier; toast `Copied · #353537` | 3.0 on the ball; one ease following the magnifier to the card; still on the toast |
| 8 | Any app | Three hovers | `button · Eight` on Calculator; a labeled row in CalmMouse Settings; the orb | 2.6 on each label, one ease between |
| 9 | Any agent | The same payload pasted into the Codex CLI, then into Claude Code | The payload readable in each | 2.2 on the input, still |

## Words, Brand, Sound

Unchanged from v2: no cards inside the clips; SF Pro and the system accent; silent.


## v4 plan (Sep 15, after the v3 review)

Five critiques, five changes. Everything else from v3 stands.

| Critique | Cause in v3 | v4 rule |
|---|---|---|
| Zoomed shots are soft | Whole LG captured at 1.5×; a 3.0 punch upscaled 1504 source px to 2560 | Capture a compact 1920×1080 pt stage at 2× (3840×2160 px). Wide downscales; 1.35 is sharper than 1:1; nothing deeper than 1.5 |
| Too much camera | Follow-pans between orbs, whip-pans across the LG | One framing per subject, held still: punch once onto the Simulator and let the selection move; cut, never pan, between subjects |
| Laggy cursor | The helper posted about 28 events a second; a 60 fps capture showed a stepping pointer | 120 Hz minimum-jerk motion on a gentle arc, no jitter, no overshoot; the real pointer stays in the capture so Locant's frame is in sync |
| Agent window cropped | 3.0 on a chat pane | Cursor at 1380×880 and the terminals at the same size, framed whole at 1.2 |
| No trigger context | Hotkey off camera, ball never seen at the start | Every capture starts on the docked ball: approach, wake, click opens the overlay. The hotkey is named in narration; the ball is the visible trigger |

Stage (LG-local coordinates; global = LG-local + (−1038, −1692)):
- Capture region (1088, 0) 1920×1080: holds the menu bar, the right screen edge where the ball docks, the Simulator
  and Cursor. The Dock and the hint line fall outside.
- Simulator at (1120, 60), 456×972. Cursor at (1610, 60), 1380×880, fresh Agent chat. Terminals for the agent
  cutaways take Cursor's place at the same size.
- Framings: wide 1.0 for the ball and the dim; 1.35 on the upper Simulator for every hover, the note and the toast;
  1.2 on the whole Cursor window; 1.35 on the Locant menu and on the Before & After window; 1.5 on the ball for
  the ring; 1.2 on a whole terminal window.
- Clipboard: after Locant's toast the take script replaces the clipboard with the Markdown alone (rebuilt from the
  sidecar Locant just wrote), because Locant's own clipboard also carries the PNG and Cursor takes the PNG.

## Capture log, v4 (Sep 15, 2026, compact 2× stage on the LG)

Raw takes in `~/Desktop/locant-film/v4/`: ScreenCaptureKit at 2× of a 1920×1080 pt region (3840×2160 px), 60 fps
verified by the gate's motion test, real pointer, 120 Hz minimum-jerk moves.

| Take | File | Length | What it holds |
|---|---|---|---|
| A | `takeA.mov` | 263.7 s | Ball wake and click, overlay, "Ocean", Resurfacing, the orb, note, toast, the text paste into Cursor, the agent's edit (+29 −1). `takeA-0-nooverlay.mov` is a false start whose keystrokes went astray |
| B | `takeB.mov` | 31.8 s | Menu, Show before & after, divider sweep, Flip and the flips |
| C | `takeC.mov` | 17.5 s | Ball wake, hand, ring, Color, magnifier to the Resurfacing card, pick `#2A2B2C`, toast |
| D | `takeD.mov` | 14.0 s | `button · Eight`, `slider · no identifier`, the orb |
| E1 | `takeE1.mov` | 16.9 s | The payload into a fresh Codex session, sent, the agent starts |
| E2 | `takeE2.mov` | 16.9 s | The payload into Claude Code, sent, the agent starts |
| D2 | `takeD2.mov` | 11.7 s | Scene 8, fourth hover: the site in Safari on the stage, `link "Download for Mac" · no identifier`, then `staticText · no identifier` on the How it works nav link. `takeD2-0-shifted.mov` hovered 80 pt low after Safari's default-browser banner was dismissed |
| F | `takeF-0-selfexcluded.mov` | 11.5 s | Locant over its own Settings window: unusable, see below |

Facts learned:
- A ball click opens the overlay only once the ball has woken; approach to within 70 pt and wait two seconds.
- A take script must never type unless the overlay is confirmed open (a layer-1000 Locant window); the first v4
  attempt typed the note into the frontmost app.
- The cursor helper's earlier moves posted about 28 events a second; the 120 Hz version reads smooth at 60 fps.
- The compact 2× stage is what makes the punches sharp: 1.5 on a 1920 pt region is exactly 2560 px.
- Safari on the stage: position the window with `tell application "Safari" to set bounds`, not System Events
  (access denied). Dismiss the default-browser banner before measuring targets; it shifts the page by 80 pt.
  Safari's accessibility tree exposes the nav links; Locant reads `link`/`staticText` with the text as label.
- Locant excludes its own windows from the hit test, so a hover over its Settings window reads the window
  behind it. "Locant to build Locant" comes from the build recording instead (`build/build-v04-timer.mp4`).
- Section 2 cutaways are cut from `~/Movies/2026-09-13 15-24-58.mov` into `v4/build/` (see `05`); the site's
  ladder and action cards are rendered from `site/index.html` with headless Chrome at 2× (`site-*.png`,
  `site-*-reveal.mp4`).

## Capture log, v3 (Sep 15, 2026, on the LG UltraFine)

Raw takes in `~/Desktop/deixis-film/v3/`: ScreenCaptureKit at 1.5x of the LG's 3008x1692 pt (4512x2538 px), 60 fps
verified by the roll gate's motion test, real pointer baked in, curved Fitts-timed moves. Locant 0.7.1, Tahoe wallpaper.

| Take | File | Length | What it holds |
|---|---|---|---|
| A | `takeA.mov` | 325.6 s | Locant half used: dim and hint line, orb label, Cooking label, note, toast. Its Cursor half is unusable: the stock recorder drops IDE windows |
| A2 | `takeA2.mov` | 124.5 s | The Cursor half, text-only clipboard: the Markdown lands in the chat input, the agent asks Locant through the MCP server and edits `SeedScreenshot.swift` (+29 −1). `takeA2-image.mov` (377.6 s) is the earlier take where Locant's own clipboard made Cursor attach the PNG instead |
| B | `takeB.mov` | 44.1 s | Menu bar on the LG, Show before & after, the window, divider slide left and right, Flip mode. `takeB-noflip.mov` is the first v3 take, where the Flip click did not register |
| C | `takeC.mov` | 21.6 s | Ball wake, hand, ring, Color, magnifier across Cursor to the Resurfacing card, pick `#363638`, toast |
| D | `takeD.mov` | 18.9 s | `button · Eight` on Calculator, `slider · no identifier` on CalmMouse Settings, `button · oceanCurrent.product ideas` on the orb. `takeD-2hovers.mov` is the first, whose orb hover missed |
| E1 | `takeE1.mov` | 22.7 s | The payload pasted into the Codex CLI (0.154) and sent; the agent starts. A macOS "Terminal wants access to control Codex Computer Use" dialog appears at about 10 s and the cut ends before it |
| E2 | `takeE2.mov` | 18.7 s | The payload pasted into Claude Code and sent; the agent starts. Re-shot after the dialog was gone; `takeE2-dialog.mov` is the first |

Facts learned:
- Locant's clipboard carries the Markdown and the PNG. Cursor's chat takes the PNG and drops the text, then the agent
  (with the Locant MCP server connected in Settings › Agents) calls `latest_capture` for the element and the note.
  Terminals take the text.
- Locant records the after-capture when the captured app comes forward (`NSWorkspace` launch and activate
  notifications), so after a simctl relaunch the Simulator must be brought to the front once.
- Cursor's agent applies edits without opening the file; the diff shows as a chip in the chat, not in the editor.
- The Color pick overwrites the clipboard; the payload must be restored before any later paste take.

## Capture log, v2 (Sep 14, 2026)

Raw takes in `~/Desktop/deixis-film/` (ScreenCaptureKit, 2056x1156 pt at 2x, real pointer baked in):

| Take | File | Length | What it holds |
|---|---|---|---|
| A | `takeA.mov` | 99.7 s | Scenes 1 to 5: hotkey, orb label, Cooking label, note typed, toast, paste into Cursor, the agent's grep and edit |
| A2 | `takeA2.mov` | 15.2 s | Scene 1 redo at full screen height: the dim and the hint line, then the orb label (hint counts reset first) |
| B | `takeB.mov` | 44.7 s | Scene 6: menu bar, Show before & after, divider slide left and right, Flip |
| C | `takeC.mov` | 29.5 s | Scene 7: ball docked, wake, hand, ring, Color, magnifier, a pick (`#353537`) |
| D | `takeD.mov` | 15.2 s | Scene 8: `button · Eight` on Calculator, Terminal text, the orb |
| E1 | `takeE1.mov` | 17.4 s | The same payload pasted into the Codex CLI (its model then errored; cut before) |
| E2 | `takeE2.mov` | 8.9 s | The same payload pasted into Cursor's chat |

Facts learned, for the next shoot:
- Locant 0.6.1 records the after-capture automatically when the app relaunches; the menu has no manual item.
- The Before & After window takes SwiftUI gestures only after Locant is activated (NSRunningApplication), and the
  image's accessibility frame goes stale after the Zoom slider moves. Zoom in the composite instead.
- The skill's `sckrecord` excludes IDE and chat windows by name; `bin/sckrecord-ide` keeps Cursor in frame.
- Unicode key events were dropped by a fresh Terminal window; the launch command went in through the clipboard.
- The agent's change was seed data (`SeedScreenshot.swift`), reverted after Take B; the simulator library was
  reseeded to the committed 10 fragments.
