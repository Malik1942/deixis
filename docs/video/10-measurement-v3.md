# Measurement v3: screenshot versus Locant, controlled

Question: for the same note, does handing the agent a Locant capture (identifier, label, frame, element crop)
instead of a screenshot change how the agent reaches the edit? Two conditions: the agent may not build, and the
agent must verify with a build.

## Method

- **Task.** Oryne (iOS, SwiftUI + SpriteKit), commit `0af9bf0`. The Product Ideas orb on the Ocean screen must get
  bigger with satellite dots, like Light And Color. In this app that is done by adding three seeded thoughts to the
  orb's theme in the screenshot seed. The note, identical on both sides, says so, so the only unknown left to the
  agent is *which* orb: "make this orb bigger, with satellite nodes like Light And Color, by adding three seeded
  thoughts to its theme (that is what drives orb size and satellites). Do not touch the layout engine."
- **Independent variable.** The payload. Screenshot side: a ⌘⇧4-style crop of the whole Simulator window
  (912×1944) plus the note. Locant side: the Markdown Locant put on the clipboard for a real capture of the orb
  (`button "Product Ideas" · id=oceanCurrent.product ideas`, frame, path, a 278×366 element crop, the note).
- **Held constant.** Claude Code 2.1.272, `claude-opus-5` at medium effort, print mode, no MCP servers on either
  side (`--strict-mcp-config` with an empty config), no project memory for the working directory (none exists),
  the same project instruction files, a fresh session per run, `git checkout -- Oryne` before and after every run,
  the Simulator on the original build (verified by screenshot before the Locant capture was taken).
- **Wrapper sentence**, identical on both sides. No-build: "Make this change in the code. Do not build or run the
  app." (permission mode acceptEdits). Build: "Make this change, then verify it compiles by running exactly:
  `xcodebuild … build -quiet`. Do not install or launch the app." (permissions skipped so the build can run on
  both sides).
- **Design.** Six pairs per condition, order alternated: screenshot first in pairs 1, 3, 5; Locant first in 2, 4, 6. Six more
  screenshot-side runs were added to the build condition afterwards (runs 7 to 12), so that cell has 12.
- **Clarifying questions.** When a run ended with no edit and a question, the session was resumed once with the
  shortest true answer, "the Product Ideas orb, the big one at the top left". Time to the edit then sums both
  invocations; the seconds a person would spend reading the question and answering are *not* counted, which
  favours the screenshot side.
- **Judging.** Automatic. Correct = the diff adds at least three `insert` blocks whose first theme is
  "product ideas" (a constant bound to that string counts) and touches only `Oryne/App/SeedScreenshot.swift`.
  Build succeeded = a new app binary was linked inside the run's time window (a watcher logged the binary's
  modification time; the first build ran before the watcher started and is marked from its clean build output).
- **Statistics.** Medians and means; exact two-sided Mann–Whitney on time to the edit; two-sided Fisher exact on
  the count of runs that asked. Six versus six: the smallest p either test can produce is 0.002.

## Results

## claude-opus-5 · build · 12 screenshot runs, 6 Locant runs

| run | screenshot: to edit | asked | correct | tokens | $ | Locant: to edit | asked | correct | tokens | $ |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 26 s | no | yes | 211k | 0.36 | 16 s | no | yes | 162k | 0.29 |
| 2 | 31 s | yes | yes | 286k | 0.41 | 16 s | no | yes | 161k | 0.28 |
| 3 | 39 s | yes | yes | 306k | 0.44 | 16 s | no | yes | 162k | 0.29 |
| 4 | 33 s | yes | yes | 253k | 0.39 | 16 s | no | yes | 163k | 0.29 |
| 5 | 34 s | yes | yes | 245k | 0.39 | 17 s | no | yes | 161k | 0.29 |
| 6 | 26 s | yes | yes | 214k | 0.36 | 17 s | no | yes | 162k | 0.28 |
| 7 | 36 s | yes | yes | 325k | 0.43 | — | — | — | — | — |
| 8 | 32 s | yes | yes | 288k | 0.42 | — | — | — | — | — |
| 9 | 32 s | yes | yes | 263k | 0.43 | — | — | — | — | — |
| 10 | 36 s | yes | yes | 316k | 0.43 | — | — | — | — | — |
| 11 | 30 s | yes | yes | 307k | 0.45 | — | — | — | — | — |
| 12 | 36 s | yes | yes | 338k | 0.47 | — | — | — | — | — |

| | Screenshot | Locant |
|---|---|---|
| Asked which orb | 11 of 12 | 0 of 6 |
| Correct edit | 12 of 12 | 6 of 6 |
| Build succeeded | 12 of 12 | 6 of 6 |
| Time to the edit, median (mean) | 33 s (32) | 16 s (16) |
| Turns, median | 14 | 8 |
| Files read, median | 2 | 1 |
| Session tokens, median | 287k | 162k |
| Cost, median | $0.42 | $0.29 |

Mann–Whitney on time to the edit (exact, two-sided): U = 72, p = 0.0001. Fisher exact on asked: p = 0.0004.

## claude-opus-5 · nobuild · 6 screenshot runs, 6 Locant runs

| run | screenshot: to edit | asked | correct | tokens | $ | Locant: to edit | asked | correct | tokens | $ |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 90 s | yes | yes | 332k | 0.77 | 22 s | no | yes | 253k | 0.34 |
| 2 | 92 s | yes | yes | 325k | 0.80 | 22 s | no | yes | 252k | 0.33 |
| 3 | 32 s | yes | yes | 281k | 0.40 | 22 s | no | yes | 222k | 0.32 |
| 4 | 33 s | yes | yes | 280k | 0.40 | 24 s | no | yes | 253k | 0.34 |
| 5 | 35 s | yes | yes | 298k | 0.44 | 22 s | no | yes | 253k | 0.34 |
| 6 | 42 s | yes | yes | 398k | 0.52 | 22 s | no | yes | 253k | 0.34 |

| | Screenshot | Locant |
|---|---|---|
| Asked which orb | 6 of 6 | 0 of 6 |
| Correct edit | 6 of 6 | 6 of 6 |
| Time to the edit, median (mean) | 39 s (54) | 22 s (22) |
| Turns, median | 16 | 11 |
| Files read, median | 2 | 1 |
| Session tokens, median | 312k | 253k |
| Cost, median | $0.48 | $0.34 |

Mann–Whitney on time to the edit (exact, two-sided): U = 36, p = 0.0022. Fisher exact on asked: p = 0.0022.


## Reading it

- **The question is the effect.** With a screenshot the agent stopped to ask which orb in 17 of 18 runs; with a
  Locant capture it asked in 0 of 12. The one screenshot run that did not ask (build condition, pair 1) guessed
  Product Ideas and happened to be right.
- **Time.** Locant reached the edit in a tight band, 22 s without a build and 16 s with one, versus 39 s and 33 s
  medians for the screenshot side even after excluding the human's answer time. The differences are at p = 0.002 (no build) and p < 0.001 (build).
- **Build verification changes nothing about the comparison.** Both sides built successfully every time; the
  gap in time, turns and tokens is the same shape. Absolute times are lower in the build condition because
  permission checks were skipped there for both sides, so do not compare seconds across conditions.
- **Tokens and cost.** Locant used fewer on every pair in both conditions (medians 253k against 312k, 162k against
  287k). The saving is the turns spent looking and asking, not the image.
- **Correctness.** 18 of 18 screenshot runs and 12 of 12 Locant runs once the question was answered. The tool does not make the agent
  smarter; it removes the one thing the agent could not know from pixels.

## Threats to validity, stated

- One task, one app, one model. Generalise with care.
- The note names the mechanism. The earlier, vaguer note ("make this orb bigger, with satellite nodes like Light
  And Color") measured two unknowns at once (which orb, and how) and both sides spent turns on the second; the
  effect was smaller and noisier (see `../results-v2.tsv`).
- Locant's payload includes the element crop *and* the identifier. This measurement does not separate the two.
- Answer time is excluded. Including any realistic value (five to fifteen seconds) widens the gap.
- Earlier measurements in this folder used a full-display screenshot (unfair to the screenshot side) or a model
  at high effort; they are kept for the record and superseded by this one.

Figures (16:9, 2560×1440): `figures/1-comparison.png`, `figures/2-all-runs.png`, `figures/3-outcome.png`,
rendered by `gen_figs.py` from the tsv files.

Raw data: `results-claude-opus-5-nobuild.tsv`, `results-claude-opus-5-build.tsv`, one `.jsonl` transcript and
one `.diff` per run, `run.sh`, `check.py`, `rejudge.py`, `stats.py`, `binary-mtime.log`.
