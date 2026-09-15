# Deixis demo footage — Gap Audit (v2)

Delivered file: `~/Desktop/deixis-film/deixis-demo-reel.mp4` (2560×1440, 60 fps, 96 s, silent), plus the six
scene files `sceneA-comp.mp4` … `sceneE2-comp.mp4` it is stitched from. The reel is a review assembly; the
pitch video cuts the scene files under the narration in `04-voiceover.md`.

## Audit of v2

Verdicts are from frames extracted from the delivered files, not from the plan.

| # | Script promise (06-film-script.md) | What the delivered file shows | Verdict |
|---|---|---|---|
| 1 | Hotkey: the screen dims, a hint line names the gestures | Re-shot after resetting the hint counts (Take A2, full-screen region): wide shot, two Control taps, the desktop dims, and the line "⏎ picks · drag for a frame · ⌥ for the parent" sits along the bottom for 3.5 s. The insert joins the original take at a 4.0 punch on the orb label, chosen so the Terminal, whose header text differs between the two sessions, is out of frame at the cut. | MET |
| 2 | Hover: blue frame and `button · oceanCurrent.product ideas`; label changes on Cooking | Punch 1.7 on the orb, label readable; follow-pan to Cooking with `button · oceanCurrent.cooking`; back to the orb. In transit the overlay shows `no element info · image only` over empty ocean. | MET |
| 3 | Note: placeholder "What should change?", the typed note, toast `Copied · oceanCurrent.product ideas` | Note field opens under the orb with the placeholder, the note types in (1.5×), toast reads `Copied · oceanCurrent.product ideas` | MET |
| 4 | Paste: `## Deixis capture (fix)`, `Image:` first, `id=oceanCurrent.product ideas` | Punch 1.45 on the Terminal; the payload is readable: heading, Image path first, `button "Product Ideas" · id=oceanCurrent.product ideas`, Path, Note | MET |
| 5 | Agent finds it: grep for `oceanCurrent`, Read of the scene file, edit summary | The agent's reply and tool lines are readable: it reads the screenshot, greps, concludes the orb size is seed-driven, edits `SeedScreenshot.swift`, reports "Build passes." The 26 s wait is condensed 8× | MET (deviates in content: the edit is seed data, not a layout change; recorded below) |
| 6 | Verify: menu bar, Show before & after, note above, identifier line, both images, divider slid once, Flip, `1 file changed`, file name | Menu opens with Show before & after highlighted; window at 2.0 then 2.4: note, `com.inspireocean.app · button id=oceanCurrent.product ideas`, divider slides left then right over the bigger orb, Flip mode with "Before · click to flip", then After (orb with satellites) alternating; `1 file changed, 28 insertions(+), 1 deletion(-)` and `Oryne/App/SeedScreenshot.swift` readable | MET |
| 7 | Ball: docked, wakes, hand, hold, ring unfolds, release on Color, magnifier, hex in the toast, Esc | Docked half-disc at the edge, wake and glide in, hand, ring with Snap / Cut / Text / Color and their hotkeys, release on Color, magnifier crosses the Terminal (2×) and settles on the Resurfacing card reading `#353537`, click, toast `Copied · #353537` held 1.7 s at a 2.2 punch. The first cut had ended before the pick; the take runs 29.5 s, not 20.5 | MET |
| 8 | Any app: three labels, a Calculator key, a CalmMouse row, the orb | `button · Eight` on Calculator (readable), a hover on Terminal text (no label legible in the frame), the orb with its label. CalmMouse was replaced by Terminal because its Settings window was hidden off screen | DEVIATES |
| 9 | (Added by direction) The same payload pasted into another agent | Codex CLI: the payload lands in the prompt, readable; the scene ends on the paste, before Enter, because Codex prints a model warning the instant a prompt is sent. Cursor: the payload lands in the chat pane; a leftover earlier chat and a "launch Cursor from the command line" toast share the frame | MET, with the blemishes noted |

## The gulfs (ranked)

1. **Scene 8's second hover carries no readable label.** Editing gap: punch 2.4 on that hover, or re-shoot the
   middle hover over Dia.
2. **Scene 9 blemishes.** Codex ends on the paste because its model warning prints on send; Cursor's pane carries an
   older chat and a toast.

## Root causes

- Editing gaps: 1 (scene 8 label). Fixable from existing footage.
- Capture gaps: 2 (Codex needs an update to run; Cursor needs a clean pane), 8 (CalmMouse Settings hidden; the take
  substituted Terminal). Each needs one short re-shoot on the same stage.

## Deviations carried on purpose

- The agent's edit is seed data (`SeedScreenshot.swift`), because Oryne sizes orbs by member count. The narration
  says "opens the right file, first try" and the frames support that; it does not claim a layout edit.
- Deixis 0.6.1 records the after-capture on relaunch. The menu item "See what changed" was removed by the
  author; the scripts were updated to Show before & after before the take.
- The Zoom slider in Before & After is not touched; the composite zooms instead.
- Scene 5's wait is condensed 8× and the typing in scene 3 runs at 1.5×; both are marked in the cut list in
  `06-film-script.md`'s capture log.

## Resolutions applied in v2

- Scene E1 ends on the pasted payload (4.9 s). Codex prints "Model metadata for gpt-6-astra not found" the instant a
  prompt is sent, so the send is not shown. Updating Codex would let a re-shoot show the send.
- Scene C re-composited at 2.6 on the ball so the ring segments read.
- Scene C re-cut through the pick (the first cut stopped at 20.5 s of a 29.5 s take) with a condense hold on the
  toast and a 2.2 punch on it.
- Scene 1 re-shot as Take A2 with the hint counts reset and a full-screen capture region (the hint line sits at
  y 1216, below the 1156-tall region used for the other takes); the compositor's CROP trims it back to 16:9 with
  the hint line in frame. Joined to the original take at a 4.0 punch on the label.

## Verification

Frames were extracted from every scene file at each beat and from the reel at every transition (Z at 40.9 s,
breath at 67.6 s, Z at 82.5 s, breath at 86.6 s, Z at 92 s). No black edges, no card, one pointer contract
(real pointer plus click rings) in every scene.

## Remaining gaps

- Scene 8 label: re-composite tighter, or re-shoot the middle hover over Dia.
- Scene 9 Codex: run `npm install -g @openai/codex` (your call) and re-shoot 12 s to show Codex reading the image.
- Scene 9 Cursor blemishes: clear the earlier chat and dismiss the toast, re-shoot 8 s with `bin/sckrecord-ide`.
