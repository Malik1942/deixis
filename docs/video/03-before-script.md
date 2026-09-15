# Locant: the "life before" video

A split-screen comparison. The same fix, requested two ways. Left: a screenshot. Right: a Locant capture. Timers on
both sides. The point of the video is one table at the end with numbers you measured, not a dramatization.

Runtime in the full video: 18 seconds. Record the whole thing; the cut speeds up the left side.

## The fair-test rules

Change one variable: what gets pasted. Hold everything else.

- Same repo, same commit, same running app in the Simulator. Reset between runs:
  ```bash
  git checkout -- . && git clean -fd
  ```
  Only run that in the demo app's repo, never in the Locant repo, and only when its working tree is disposable.
- Same agent, same model, fresh session each run. Claude Code with the model you actually use.
- Same note, word for word: `make this rounded, match the other pills`.
- Same stopping rule: the run ends when the agent has made an edit that rounds the target button, or when it asks a
  question. If it asks, answer with the shortest true answer and keep the clock running.
- Three runs per side. Report the median. Keep the raw table.

## Measuring

**Time.** Stopwatch overlay in the recording, started on the paste, stopped on the edit. Also note the time the
human spent before the paste: taking the screenshot and writing a description, versus the Locant capture.

**Tokens.** After each run, in Claude Code:

```
/cost
```

It prints the session's total tokens and wall-clock duration. Screenshot it. The token total includes the image,
every file the agent read, and its own output, which is exactly the cost of "finding the button."

**Files opened.** Count the agent's Read and Grep calls in the transcript. This is the number that explains the
tokens, and it is the more honest headline than the tokens themselves.

## Left side: from a screenshot

| # | Action | Notes |
|---|---|---|
| 1 | Press ⌘⇧3 for a full-screen screenshot. | Or ⌘⇧4 and drag, if you want to be generous to the old way. Say which in the video. |
| 2 | Drag the PNG into Claude Code. Type the note. Enter. | The prompt has the image and the same note. Start the clock. |
| 3 | Wait. | The agent describes the screenshot, greps for words it saw ("Capture", "button"), opens candidate files. |
| 4 | If it asks which button, answer: `the capture button at the bottom`. | Keep the clock running. |
| 5 | Stop the clock at the edit. Run `/cost`. | Record tokens, duration, files opened, and whether the first edit touched the right file. |

## Right side: from Locant

| # | Action | Notes |
|---|---|---|
| 1 | Double-tap Control, hover, click the button, type the note, Enter. | Under three seconds. |
| 2 | Paste into Cursor. Enter. | Start the clock. |
| 3 | Wait. | The agent opens the PNG at the path, greps `captureButton`, opens the file. |
| 4 | Stop the clock at the edit. Run `/cost`. | Same columns. |

## As run (Sep 15, 2026)

The measurement was run headless so both sides are identical except for the pasted content: Claude Code 2.1.272 in
print mode (`claude -p … --output-format stream-json --verbose`, permission mode acceptEdits, no MCP servers on
either side so the Locant side cannot ask Locant for anything the screenshot side cannot), fresh session per run,
Oryne reset with `git checkout -- Oryne` between runs. Runner and transcripts: `~/Desktop/locant-film/v4/measure/`.

- Note, both sides: `make this orb bigger, with satellite nodes like Light And Color` (the demo's note; the first
  candidate, "give this orb a thin white outline", hit Oryne's do-not-touch rule for the Ocean field and the agent
  stopped, so it measured the rule, not the payload).
- Left: `Screenshot: <path to a ⌘⇧3-style capture of the whole LG display, 6016×3384>` and the note.
- Right: the Markdown Locant put on the clipboard for a real capture of the Product Ideas orb with that note.
- Stopping rule as above: if a run ends with no edit and a question, the session is resumed once with the shortest
  true answer (`the Product Ideas orb, the big one at the top left`) and the two invocations are summed.
- Tokens are the session totals from Claude Code's result event (input + output + cache writes + cache reads);
  "files opened" counts Read plus Grep/Glob calls, and greps run through Bash are listed separately.

## Results (Sep 15, 2026, Claude Code 2.1.272, model claude-fable-5-1, three runs per side)

| | Screenshot (median of 3) | Locant (median of 3) |
|---|---|---|
| Human time before the paste | not timed (headless) | not timed (headless) |
| Agent time, paste to first edit | 112 s | 52 s |
| Files the agent read | 7 | 4 |
| Shell greps and finds | 20 | 17 |
| Clarifying questions | 0 | 0 |
| Session tokens (input + output + cache) | 485k | 483k |
| Tokens not served from cache | 28.4k | 24.0k |
| Cost reported by Claude Code | $1.22 | $0.95 |
| First edit in the right file (`SeedScreenshot.swift`) | 3 of 3 | 3 of 3 |

Raw runs, paste to first edit: screenshot 83.5 s, 112.1 s, 128.3 s; Locant 26.0 s, 51.7 s, 114.3 s. Every run
ended with the seed edit made and then a blocked `xcodebuild` (the sandbox refuses builds on both sides alike), so
wall time past the edit is not comparable and is not reported.

What the numbers support, and what they do not:

- **Time.** Locant halved the median time to the edit. Say "half the time", not a ratio to two decimals; the spread
  is wide (one Locant run took 114 s, one screenshot run 84 s).
- **Tokens.** No difference to claim. The session totals are dominated by cache reads, which scale with turns, not
  with the image; the screenshot's image is larger (575 KB of base64 in the transcript versus 117 KB for the crop)
  but current models cap image tokens, so the pasted image is not where the cost lives. Do not say "fewer tokens".
- **Files.** Both sides found the right file first; the screenshot side searched longer (more reads, more greps)
  before editing. "It went straight there" is fair as a relative statement, not an absolute one.
- **Caveat.** One screenshot run and one Locant run spawned a subagent whose tokens are not in the parent's total.
  The agents on both sides grepped for the words in the note ("Light And Color", "Product Ideas") before the
  identifier, because in this app the identifier is derived from the same label.

## The one number you can compute

Image tokens scale with pixel area, roughly one token per 28×28 pixel patch on current Claude models, capped at
the model's maximum image size (2576 px on the long edge for Opus 4.7 and later, about 4,800 tokens).

| Image | Pixels | Approx. image tokens |
|---|---|---|
| Full-screen screenshot, 2056×1329 pt at 2× | 4112×2658, downscaled to 2576×1665 | ~4,800 (at the cap) |
| Locant element crop from the README example, 450×130 pt at 2× | 900×260 | ~300 |

That is roughly 16× fewer image tokens before the agent reads a single file. Say it as "about sixteen times" and
attribute it to the image alone. The measured session totals are the headline; this line is the explanation.

Verify the ratio before you say it on camera. From the demo app's folder, with the API key in the environment:

```bash
python3 - <<'PY'
import anthropic, base64, pathlib
c = anthropic.Anthropic()
for p in ["screenshot.png", "deixis-crop.png"]:
    data = base64.b64encode(pathlib.Path(p).read_bytes()).decode()
    n = c.messages.count_tokens(model="claude-opus-5", messages=[{"role": "user", "content": [
        {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": data}}]}])
    print(p, n.input_tokens)
PY
```

Put the two PNGs next to the script first: the ⌘⇧3 capture and the newest file in `~/Pictures/Locant/`.

## How the split screen is cut

- Both sides start on the paste, synchronized. The right side finishes; freeze it on the diff. The left side keeps
  running; speed it up 4× with the timer visible, so the viewer sees files scrolling by.
- When the left side finishes, both timers stop. Cut to the results table, one row appearing at a time, tokens last.
- No music change, no red versus green. The numbers do the work.

## What not to claim

- Do not say the screenshot path "fails." It usually succeeds, slowly. Say it searches.
- Do not generalize beyond what you ran: one task, one app, one model, three runs.
- If a Locant run also asked a question or opened the wrong file, keep it in the table. The honesty note on the
  site applies to the video too.
