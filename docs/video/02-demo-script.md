# Locant: demo script

Recording script for the product flow. Two takes: **Take A**, the loop (hotkey to paste), and **Take B**, the
verification (Show before & after; the after capture is automatic when the app relaunches). The full script uses about 35 seconds of this; the site's demo slot uses 10 to 15
seconds of Take A. Record generously and cut later.

Everything in this script is a real feature at v0.5. Where a name or identifier is from the README example
(`captureButton`, `com.example.myapp`), substitute your own.

## Preparation

1. Quit every Locant except `/Applications/Locant.app`. Confirm the pointing hand is in the menu bar.
2. Reset the first-run hints so the hint toasts show once in the take (they are useful footage):
   ```bash
   defaults delete com.malikzhang.deixis hintCounts
   ```
   Run this while Locant is quit, then relaunch it.
3. Open the iOS Simulator with your app on a screen that has a clearly labeled, identifier-bearing button.
   The button should be visibly not-quite-right so the note is credible ("make this rounded, match the other pills").
4. Open Cursor on the app's project folder, a fresh Agent chat on the right (⌘L), the editor empty. Zoom the UI two
   steps (⌘=) so the chat is readable on video.
5. Arrange: Simulator on the left third, Cursor on the right two thirds. Nothing else visible. The ball rests
   at the lower right.
6. Empty the clipboard so the paste in step 9 cannot be a stale one.
7. Start the recorder. Count two seconds of stillness before every take.

## Take A: the loop

| # | Action | What the viewer sees | Hold |
|---|---|---|---|
| 1 | Rest hands. | The Simulator and terminal, the ball docked at the edge. | 2 s |
| 2 | Move the cursor toward the ball. | The ball wakes and glides out. Do not click it; this is just to show it exists. | 1 s |
| 3 | Double-tap Control. | The screen dims, the overlay is up. A hint line at the bottom names the gestures. | 1 s |
| 4 | Hover the target button. | Blue highlight, label `button · captureButton`. | 1.5 s |
| 5 | Hover a neighbor, then back. | The highlight and label follow. Shows it is live, not a screenshot. | 1.5 s |
| 6 | Press Option once. | Highlight steps to the parent, label changes to the group. Press again to come back, or hover the button again. | 1.5 s |
| 7 | Click the button. | The note field appears next to the element. | 0.5 s |
| 8 | Type: `make this rounded, match the other pills` then Enter. | Text appears; on Enter the overlay drops and the toast reads `Copied · captureButton`. | 1.5 s |
| 9 | Click into Cursor's chat, paste (⌘V), press Enter. | The Markdown payload lands in the chat. Image path first. | 2 s |
| 10 | Wait. | The agent reads the PNG, greps `captureButton`, and opens the one file that contains it; Cursor shows the diff inline. Let the grep and the diff show; the grep is the proof of decision one. | 4 to 8 s |
| 11 | Let it finish the edit. | The diff in the editor, the summary in the chat. | 2 s |
| 12 | Stop. | | |

Optional beats for a longer cut (record after step 12, same setup):

- **Drag.** Double-tap Control, drag a frame around a group of controls, type a note, Enter. The payload lists
  every element inside the frame. Ten seconds.
- **The ring.** Press and hold the ball for half a second, release on Color. The magnifier appears; click a pixel,
  the toast shows the hex value. Ten seconds. Shows the four other actions without narrating them.
- **Esc.** Double-tap Control, hover, press Esc. Nothing happens, the clipboard is untouched. Three seconds. It is
  the safety line in the narration ("nothing is written until Enter").

## Take B: Show before & after

Start right after Take A's agent edit, in the same session.

| # | Action | What the viewer sees | Hold |
|---|---|---|---|
| 1 | Rebuild and run the app in the Simulator (⌘R in Xcode, or your usual command). | The app relaunches with the rounded button. | as needed, cut later |
| 2 | Click the pointing hand in the menu bar. | The menu: Capture, Show before & after, Snap, Text, Color, Cut, Open capture folder, Settings… | 1.5 s |
| 3 | Choose **Show before & after**. | The iteration was recorded when the app relaunched (0.6.1 verifies on its own). The Before & After window opens: your note above, the two images side by side, one zoom, the diff stat and the files touched below. | 3 s |
| 4 | Drag the slide divider once, left to right. | The after image sweeps over the before. | 2 s |
| 5 | Click **Flip** twice. | Before, after, before. | 2 s |
| 6 | Hover the file list. | The changed files, the insertions and deletions. | 2 s |
| 7 | Stop. | | |

## After recording

- Check `~/Pictures/Locant/` for the capture PNG and its JSON sidecar. If you show the folder in the video, this is
  the moment: Finder tags `Locant`, the app name, `fix`, and the project.
- Do not re-record for a slow first hover on the Simulator. The tree is built lazily; up to 600 ms is by design and
  the narration can absorb it. Re-record only if the label is wrong.
- If the agent asks a clarifying question instead of opening the file, keep the take. Paste the capture again with
  "the identifier is in the payload" and let it continue, then cut the question out. Note the run for `03`.
