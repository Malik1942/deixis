# The build recordings: what is where

The product was called Deixis when these recordings were made (Sep 13 and 14, 2026); it is Locant now. The names on screen in the build recordings are historical.

Two screen recordings in `~/Movies`, both with the Simulator (Oryne) on the left and Claude on the right, on the
purple wallpaper. A "Design Challenge" countdown runs in the menu bar of the Sep 13 recording, which is the
on-screen proof for the three-hour claim: use it. Every cutaway for section 2 ("How I approached it") comes from
these two files; nothing needs to be re-staged.

| File | Length | Size | What it is |
|---|---|---|---|
| `2026-09-13 15-24-58.mov` | 3 h 25 min, 1824×1180 | 1.0 GB | The three-hour window, timer in the menu bar, then 25 min of overrun |
| `2026-09-14 12-51-34.mov` | 41 min, 1920×1080 | 198 MB | The next day: v0.5 (Help window, hints, Return as click) |

## Sep 13, by timer

Times are offsets into the file; the timer value is what the menu bar shows at that moment.

| Offset | Timer | What is on screen | Use it for |
|---|---|---|---|
| 0:03 | 2:59:57 | Claude Design canvas "Deixis Overlay States": the overlay frames (hover, note) drawn before any code, with the critique "graphite accent reads faintly against the purple wallpaper" | Section 2 opening: design first, then code. Two seconds. |
| 0:25 | 2:37:54 | Claude Code "New project scaffold": the "My judgment on what to change before go" pass over the PRD, then "build out v0.1 slot by slot". macOS permission alert in front. | "I wrote the requirements and a spec per version with Claude." |
| 0:50 | 2:12:54 | v0.1 merged: R0 + PRD design language, the mode classifier, Markdown builder, hotkey, overlay. "Slot 0 passed: per-app and system-wide hit tests return the same element on the Simulator." The timer menu is open. | The loop exists at 47 minutes. Show the timer. |
| 1:20 | 1:42:54 | The first Deixis capture on the Oryne orb: `No element information available (app exposes no accessibility tree)`. Malik: "when I'm catching some elements that I build myself... it shows no element information available." Claude: "The orb itself simply isn't present in the tree, so I'll report no element with a suggestion to add an identifier in the source." | "My own app's orbs were invisible to accessibility." This is the exact moment. Hold three seconds. |
| 1:50 | 1:12:54 | Region path working (drag a frame, elements inside listed), 45 tests pass, `v0.2-region` tagged. Malik: "next session what I want to do is the setting window and the orb design rather than the MCP connection. Finish all the features of the product first." | "I made the calls." A decision on screen, in your words. |
| 2:20 | 0:42:54 | v0.3 planning: "Let's build the things in v0.3, except the MCP. Snap, Text, Color, Cut, the ring, and the 30-day lifecycle. Starting with the ball." Then the first ball bug: "I can only drag to screenshot with context in Deixis, not in any other apps." | Decision three and four (scope, the ball) were made here. |
| 2:50 | 0:12:54 | v0.4: "Capture after in the menu bar finds that element again", Verify built and tagged, Settings window matches System Settings layout. The frame overlay with eight handles on screen. | "Version 0.4 in the three-hour window." Show the timer at 0:12. |
| 3:15 | over | Fixing the ball's docking: "the Dock is covering the tucked half of the disc; dock against the visible frame instead." | Optional: the seams. |

## Sep 14

Frames every two minutes are in the scratch contact sheet; map it the same way when you cut section 2. It holds
the Help window, the hint lines, and the Return-as-click work, none of which the narration names, so it is
b-roll only.

## How to cut section 2 from this

- Play the recording at 8× to 12× under decision one and two, with the timer legible in the top right. The
  timer counting down is the visual for "three hours" and needs no caption.
- Freeze on 1:20 (the null element on the orb) for the "invisible to accessibility" line, at 1×.
- Freeze on 1:50 (your "finish the product first" message) for "AI came in everywhere except the decisions."
- Land on 2:50 with the timer at 0:12:54 for the [CONFIRM] sentence. Suggested wording, now that the timer is
  on screen: *"Versions 0.1 to 0.4 were built inside the three-hour window, timer running. Version 0.5 came the
  next day. I'm the only author."*
