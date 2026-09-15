# Locant demo footage — Gap Audit (v3)

Delivered file: `~/Desktop/deixis-film/v3/locant-demo-reel.mp4` (2560×1440, 60 fps, 108.0 s, silent), stitched from
six scene files in the same folder: `sceneA-comp.mp4` (45.9 s, the loop and the Cursor agent), `sceneB-comp.mp4`
(25.5 s, Before & After), `sceneC-comp.mp4` (18.6 s, the ball), `sceneD-comp.mp4` (4.2 s, three hovers),
`sceneE1-comp.mp4` (6.8 s, the Codex paste), `sceneE2-comp.mp4` (7.5 s, the Claude Code paste). The v2 audit is kept as `07-demo-film-audit-v2.md`.

Shot on the LG UltraFine with Locant 0.7.1 on the Tahoe wallpaper, Cursor as the agent, under the v3 rules in
`06-film-script.md`: curved cursor moves, the camera at 2.6 to 3.4 following the cursor, one move per change.

## Audit of v3

Verdicts are from frames extracted from the delivered files.

| # | Script promise | What the delivered file shows | Verdict |
|---|---|---|---|
| 1 | Hotkey: the screen dims, a hint line names the gestures | Wide 1.0 for 4 s: the desktop dims and "⏎ picks · drag for a frame · ⌥ for the parent" sits along the bottom. Small at this scale on a 3008 pt display; legible on the 2560 canvas | MET |
| 2 | Hover: `button · oceanCurrent.product ideas`, then `.cooking` | One ease to 3.0 on the orb before the label; follow-pan to Cooking and back at 3.0; both labels readable | MET |
| 3 | Note: "What should change?", the note, toast `Copied · oceanCurrent.product ideas` | Placeholder, the note typing at 1.4×, the toast held 1.7 s at the end of the Locant half | MET |
| 4 | Paste into Cursor: `## Locant capture (fix)`, image first, the identifier | Whip-pan from the orb to Cursor's chat input at 3.0; the Markdown lands in the input and is readable: the heading, the Image path first, `button "Product Ideas" · id=oceanCurrent.product ideas`, the Path, the Note; Enter sends it. Re-shot with a text-only clipboard (the first take carried Locant's PNG too and Cursor showed an image chip) | MET |
| 5 | Agent finds it: grep, the file, the diff | Cursor's agent: "I'll pull the Locant capture and find how Product Ideas and Light And Color orbs are sized" and "Using Locant to inspect the Product Ideas orb" (it calls Locant's MCP server even with the text pasted), then the `SeedScreenshot.swift +29 −1` chip with green lines. Three jump cuts through a two-minute run | MET |
| 6 | Verify: menu bar, Show before & after, note, identifier line, both images, divider slide, Flip, diff line | 3.0 on the Locant menu, then 3.0 on the window: note, `com.inspireocean.app · button id=oceanCurrent.product ideas`, small orb and satellite orb, divider swept left then right, then Flip mode with "Before · click to flip", `1 file changed, 28 insertions(+), 1 deletion(−)`, `Oryne/App/SeedScreenshot.swift`, "All iterations (2)". Re-shot; the first v3 take's Flip click had not registered | MET |
| 7 | Ball: wake, hand, hold, ring, Color, magnifier, the pick, the toast | 3.0 at the top-right: docked disc, wake, hand, the ring with Snap / Cut / Text / Color; one ease following the magnifier to the Resurfacing card; `#1C1D21` in the magnifier, the pick, `Copied · #363638` held 1.7 s | MET |
| 8 | Any app: Calculator key, a CalmMouse control, the orb | `button · Eight` on Calculator, `slider · no identifier` on CalmMouse Settings, `button · oceanCurrent.product ideas` on the Simulator, 1.4 s each at 2.6. Re-shot; the first take's orb hover had missed the element | MET |
| 9 | Any agent: the same payload into Codex and Claude Code | Codex 0.154: the payload readable in the prompt, sent, the agent starts. Claude Code: re-shot after the dialog was gone; the payload lands with its sections readable, is sent, and the agent answers "I'll look at the capture, then find what determines orb size and satellites" | MET |

## The gulfs (ranked)

None. Every scene's promise is on screen and readable.

## Root causes

- Editing gaps: none left; every visible defect was framed or cut around.
- Capture gaps: none.

## Deviations carried on purpose

- The agent's change is seed data again (Oryne sizes orbs by member count).
- Scene 5 is three jump cuts through a two-minute agent run; the chat pane is static text between them.
- Locant's own clipboard carries the PNG as well as the Markdown. For this take the Markdown alone was placed on
  the clipboard (the same text Locant writes, rebuilt from the sidecar), so Cursor shows the text.
- Scene A's two halves come from two takes joined at a 3.0 punch on the orb with the overlay closed; the Simulator
  shows the small orb on both sides.
- No Zoom slider in Before & After; the composite zooms.

## Verification of the delivered reel (final pass)

Measured on `locant-demo-reel.mp4` itself with a 2 s contact sheet and frames at every transition, not on the scene
files. Timecodes are from the delivered file.

| Reel time | What is on screen | Checked |
|---|---|---|
| 0:00–0:04 | Wide desktop on the Tahoe wallpaper; the dim lands at 0:04 | dim visible |
| 0:04–0:06 | Hint line "⏎ picks · drag for a frame · ⌥ for the parent" along the bottom | legible on the canvas, small |
| 0:06–0:12 | 3.0 on the orb: `button · oceanCurrent.product ideas`, follow-pan to `button · oceanCurrent.cooking`, back | both labels read |
| 0:13–0:19 | Click ring, "What should change?", the note typing | reads |
| 0:20–0:23 | `Copied · oceanCurrent.product ideas`, held | reads |
| 0:23–0:30 | Whip to Cursor's Agent chat, click ring, the Markdown lands in the input | heading, Image path, `id=oceanCurrent.product ideas`, Note all read |
| 0:32–0:39 | Sent; "I'll pull the Locant capture…", "Using Locant to inspect the Product Ideas orb" | reads |
| 0:40–0:45 | `SeedScreenshot.swift +29 −1` with green lines | reads |
| 0:45.5 | Zoom-through into scene B | no ghost frame |
| 0:46–0:53 | 3.0 on the Locant menu; Show before & after | menu items read |
| 0:53–1:10 | The window: note, identifier line, divider swept left then right, Flip with "Before · click to flip", `1 file changed, 28 insertions(+), 1 deletion(−)`, `Oryne/App/SeedScreenshot.swift` | reads |
| 1:11–1:12 | Black breath | clean |
| 1:12–1:21 | 3.0 top-right: docked disc, wake, hand, the ring with Snap / Cut / Text / Color | ring labels read |
| 1:21–1:30 | One ease following the magnifier to the Resurfacing card; the pick; `Copied · #363638` held | reads |
| 1:30–1:34 | `button · Eight`, `slider · no identifier`, `button · oceanCurrent.product ideas` at 2.6 | all three read |
| 1:34–1:35 | Black breath | clean |
| 1:35–1:42 | Codex 0.154: the payload pasted and sent, "Working" | reads |
| 1:42–1:48 | Claude Code: the payload pasted and sent, the agent's first line | reads, no dialog |

One pointer contract throughout (real pointer, click rings). No black edges, no card, no cross-dissolve; two Z
zoom-throughs and two breaths. Total 1:48.

## Remaining gaps

- None.
