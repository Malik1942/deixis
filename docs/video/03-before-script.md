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

## Results (Sep 15, 2026, refined)

The measurement that counts is the third one. The first used a full-display screenshot (unfair; nobody pastes
that). The second used a ⌘⇧4 crop but ran on Fable at high effort with the earlier runner. The third, below, is
the one the video quotes: `claude-opus-5` at medium effort, no MCP server on either side, no project memory for
the working directory, a fresh session per run, Oryne reset between runs, the screenshot a ⌘⇧4 crop of the
Simulator window (912×1944). Six pairs; the screenshot side went first in pairs 1, 3, 5 and Locant first in 2, 4, 6.
When the agent stopped to ask which orb, the session was resumed once with `the Product Ideas orb, the big one at
the top left` and the two halves are summed (the human's answer time is not counted). Runner: `measure-v2.sh`,
`resume-v2.sh`; raw rows in `results-v2.tsv`.

| Pair | Order | Screenshot: to the edit | Asked which orb | Locant: to the edit | Asked |
|---|---|---|---|---|---|
| 1 | screenshot first | 48 s | no | 94 s | no |
| 2 | Locant first | 47 s | yes | 40 s | no |
| 3 | screenshot first | 80 s | yes | 47 s | no |
| 4 | Locant first | 51 s | yes | 39 s | no |
| 5 | screenshot first | 52 s | yes | 40 s | no |
| 6 | Locant first | 107 s | yes | 41 s | no |

| Medians of six | Screenshot, ⌘⇧4 crop | Locant |
|---|---|---|
| Stopped to ask which orb | 5 of 6 | 0 of 6 |
| Paste to first edit (answer time excluded) | 52 s | 41 s |
| Files the agent read | 4 | 4 |
| Session tokens | 532k | 514k |
| Cost reported by Claude Code | $0.70 | $0.59 |
| First edit in the right file (`SeedScreenshot.swift`) | 6 of 6 | 6 of 6 |

What the numbers support:

- **The question.** Five screenshot runs out of six stopped and asked which orb; every Locant run went to the file.
  That is the line the video says.
- **Time.** Locant's median is 41 s against 52 s, and the screenshot side's number already leaves out the seconds a
  person spends answering. Say "faster" if you like; do not say a ratio.
- **Tokens and cost.** Close (532k / $0.70 against 514k / $0.59). Do not claim them.
- Both sides found the right file every time.

The earlier measurements, for the record: full-display screenshot on Fable, medians 112 s / 485k versus Locant
52 s / 483k; ⌘⇧4 crop on Fable at high effort, 57 s / 984k. A hand-run pair in the Claude Code desktop app on
Opus 5 (memory and the Locant MCP available on both sides, `measure/app/`): 62 s with one question versus 61 s
with none, the Locant side costing more because it also rebuilt the app, installed it and resolved the capture.

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
