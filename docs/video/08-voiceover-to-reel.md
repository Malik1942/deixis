# Voice-over against the reel

`~/Desktop/deixis-film/v3/locant-demo-reel.mp4` is silent, 1:48. It is footage, not the whole pitch: it serves
section 3 of `01-full-script.md` (the demo) and supplies the cutaways for sections 1 and 2. This page places the
narration from `04-voiceover.md` against the reel's own timecodes, in the order the reel plays, so the demo can
be narrated straight over the file. Timecodes are measured from the delivered reel.

## If you narrate the reel as it plays (a demo video on its own)

| Reel | On screen | Say | Words |
|---|---|---|---|
| 0:00–0:06 | The desktop dims; the hint line along the bottom | *(nothing for two seconds, then)* Double-tap Control. | 2 |
| 0:06–0:12 | The orb label, then Cooking, then back | Hover; Locant says what it sees before I click. | 9 |
| 0:13–0:23 | Click, the note, Enter, the toast | *(silence; the click, the note and Enter are shown, not narrated)* | 0 |
| 0:23–0:30 | The Markdown lands in Cursor's chat | Paste into Cursor. | 3 |
| 0:32–0:45 | The agent asks Locant, then the diff chip | It asks Locant for the element, and opens the right file, first try. | 13 |
| 0:46–0:53 | The Locant menu, Show before & after | After the rebuild, Locant finds the same element again on its own. | 12 |
| 0:53–1:10 | The window: divider sweep, Flip, the diff line | Show before & after: both images, with the diff beneath. | 10 |
| 1:12–1:21 | The ball wakes, the hand, the ring | One gesture, five actions. The ball is a quiet disc that wakes when you reach for it. Click to point. Hold it, a ring unfolds, release on the action you want. | 32 |
| 1:21–1:30 | The magnifier to the card, the pick, the toast | *(silence; the toast reads `Copied · #363638`)* | 0 |
| 1:30–1:34 | Three hovers: Calculator, CalmMouse, the orb | One element, in any app. | 5 |
| 1:35–1:48 | The same payload into Codex, then Claude Code | Handed to whichever agent I'm using. Point, don't describe. | 10 |

86 words over 1:48. That is a slow read with long silences, which is the intended feel: the picture leads, the
voice names what just happened.

Two lines above differ from `04-voiceover.md` on purpose, because the footage changed:
- Section 3's "Paste into Cursor. It opens the right file, first try." became "Paste into Cursor. It asks Locant
  for the element, and opens the right file, first try." The reel shows the agent calling Locant's MCP server
  before it edits; the line should claim what is on screen. If you keep the shorter line, it is still true.
- "One element, in any app" and "Handed to whichever agent I'm using" are section 1's universal-capture sentence,
  split across the two cutaways; in the pitch they play under section 1, not here.

## If you cut the reel into the pitch (the submission video)

| Pitch section | Narration line (from 04) | Reel segment to cut in |
|---|---|---|
| 1 Why, "any app" | I wanted to point at one element in any app | 1:30–1:34, the three hovers |
| 1 Why, "whichever agent" | and hand it to whichever agent I'm using | 1:35–1:48, Codex then Claude Code, one to two seconds each |
| 1 Why, "this button" | I know what I mean by "this button." My agent doesn't. | 0:06–0:09, the orb label snapping on |
| 2 How, decision one | It reads the accessibility tree, not the pixels… image path first | 0:26–0:30, the payload in Cursor's input |
| 2 How, decision four | One gesture, five actions… release on the action you want | 1:12–1:21, the ball and ring |
| 2 How, "I used Locant to build Locant" | *(no reel footage; use a capture over Locant's own Settings)* | none |
| 3 Demo | Double-tap Control. Hover; Locant says what it sees before I click. | 0:00–0:12 |
| 3 Demo | Paste into Cursor. It opens the right file, first try. | 0:23–0:45, trimmed to about 8 s |
| 3 Demo | After the rebuild, Locant finds the same element again on its own. Show before & after: both images, with the diff beneath. | 0:46–1:10, trimmed to about 10 s |

Section 3 in the pitch is budgeted at 22 s; the reel's scenes A and B run 70 s, so the trim is the job: keep the
hotkey and the label (6 s), the paste landing (3 s), the diff chip (3 s), the menu and the divider sweep (7 s),
and the Flip (3 s).
