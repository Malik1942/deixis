# Locant: full script

Runtime target **2:55**. Hard cap 3:00. The brief says less is more, so cut before you pad.

Framing: this is a pitch told as a path. Frustration, approach, proof, next. The demo is evidence for the pitch,
not the point of the video. Every section ends on one sentence the viewer can repeat.

Format: **VOICE** is what you say. **SCREEN** is what is shown. **NOTE** is production direction. Times are targets.

---

## 1. Why this was worth solving for me (0:00 to 0:52)

**SCREEN**
No title card. Open on your desktop as it really is when you work: the iOS Simulator with your app on the left,
Cursor on the right, the cursor resting on a button that is not quite right. Hold two seconds, then start
talking. If you want to be on camera, this is the only section for it.

**VOICE**
> I build my own apps alone. A coding agent does most of the typing.
>
> What wore me down wasn't the code. It was the moment after I saw something wrong.
> A button that should be rounder. Half a second to see it. Then I'd sit there composing the prompt.
> Which screen. Which component. Where it sits in the tree.
> By the time I'd written it, I'd lost the thing I was actually going to say.
>
> Or I'd paste a screenshot, and watch the agent guess.

**SCREEN**
Cutaways, two seconds each: you typing a long description into Cursor and deleting half of it; a
full-screen screenshot pasted into the prompt; the agent's reply asking which button, or opening the wrong file
(both from the before-video takes).

**VOICE**
> Browser tools fix this for the web. Others send a whole window to one agent.
> I wanted to point at one element in any app, and hand it to whichever agent I'm using.

**SCREEN**
One second each, no more: the Agentation or Stagewise page; a Codex Appshots window capture. Then back to your
desktop. On "any app": four quick hovers with the Locant highlight, over Calculator, over CalmMouse, over the
Simulator (reel 1:19 to 1:23), then over a web page in the browser (`sceneD2-comp.mp4`). On "whichever agent": the
payload pasted into the Codex CLI, then the same payload in Claude Code (reel 1:24 to 1:44).

**VOICE**
> I know what I mean by "this button." My agent doesn't.
> Pointing is how people resolve "this."

**SCREEN**
On "this button": the Locant highlight snaps onto the button with the label `button · captureButton`. Title fades
in under it: **Locant**, and smaller, *Point, don't describe.*

**NOTE**
This section carries the whole pitch. Say it slowly, to one person. The list "which screen, which component,
where it sits" is the cognitive load made audible; let each item land as a separate thought. The universal
sentence ("one element in any app... whichever agent") is the positioning against every tool you name; it earns
the name-drops.

---

## 2. How I approached it (0:52 to 2:05)

**SCREEN**
`build-canvas.mp4`: the overlay states drawn on the Claude Design canvas before any code, timer at 2:59:57. Then
`build-timelapse-3h.mp4` under the next two decisions: the whole three-hour window in twenty seconds, the timer
counting down in the menu bar.

**VOICE**
> The smallest loop that could be useful: hotkey, hover, click, type what should change, Enter, paste.
>
> Four decisions shaped it.

**SCREEN**
The overlay label `button · captureButton` over the Simulator, then the payload full screen in monospace.
Highlight `id=captureButton`, then `Image:` on the first line. On "grep for": a terminal running
`grep -rn captureButton` and returning one file.

**VOICE**
> One. It reads the accessibility tree, not the pixels. The identifier is the one thing an agent can grep for,
> and it goes out as plain Markdown, image path first, so every agent can take it.

**SCREEN**
The fallback ladder from the site, five rungs, one per second (`site-ladder-reveal.mp4`; still: `site-ladder.png`).

**VOICE**
> Two. No identifier? It steps down a ladder: label and neighbors, a drawn frame, text, then the image alone.
> And it says which rung it reached.

**SCREEN**
The four action cards from the site, one per second (`site-actions-reveal.mp4`; still: `site-actions.png`), with
their "keeps a file / keeps nothing" lines. Then the ring footage from the reel (1:05 to 1:19) carries into decision four.

**VOICE**
> Three. It had to replace my screenshot tool, or I'd still be switching apps while polishing. So Snap, Text,
> Color, and Cut ride the same gesture. Images keep a file; text and colors keep nothing.

**SCREEN**
The ball, real footage (`sceneC-comp.mp4`, reel 1:05 to 1:19): docked at the edge, waking as the cursor approaches,
the hand appearing, then press and hold, the ring unfolding with the four segments and their numbers, release on
Color, the magnifier. Let it play under the whole of decision four.

**VOICE**
> Four. One gesture, five actions. The ball is a quiet disc that wakes when you reach for it. Click to point.
> Hold it, a ring unfolds, release on the action you want. Round, so four directions can open from it.

**SCREEN**
`build-null-element.mp4`, at 1×: the first capture on the Oryne orb reads `No element information available (app
exposes no accessibility tree)`, timer at 1:42. Then the reel at 0:12, the same orb with `oceanCurrent` in its label.

**VOICE**
> The challenge was in the seams: my own app's orbs were invisible to accessibility.

**SCREEN**
From the build recording (`~/Desktop/locant-film/v4/build/`): `build-scaffold.mp4`, Claude taking the PRD to a
v0.1 plan; `build-v04-timer.mp4`, the diff chip `+381 −40` with the timer at 0:12:54; the line "45 tests pass" in
`build-decision.mp4`. On "Locant to build Locant": `build-v04-timer.mp4` again, where the agent reads a capture of
Locant's own frame overlay (`300 × 200 pt · ⏎ capture · esc cancel`). A live hover over Locant's Settings cannot be
shot: Locant excludes its own windows from the hit test, so the overlay reads the window behind it.

**VOICE**
> AI came in everywhere except the decisions: specs with Claude, Swift by Claude Code. And I used Locant to
> build Locant.

**NOTE**
`[CONFIRM]` Say the time honestly here, in one sentence. Suggested: *"Versions 0.1 to 0.4 were built inside the
three-hour window, timer running; 0.5 came the next day. I'm the only author."* Rewrite to match what you want to stand behind. The brief requires an existing
project to be called out explicitly, and the site ribbon already says "v0.4 built in 3 hours," so the video and
the site must agree.

---

## 3. Demo (2:05 to 2:27)

**SCREEN**
Take A from `02-demo-script.md`, cut to length. Three seconds with no narration; let the hotkey, hover, and
click play with sound. The agent on screen is Cursor: the payload lands in its Agent chat and the diff shows in the editor.

**VOICE**
> Double-tap Control. Hover; Locant says what it sees before I click.
>
> Paste into Cursor. It opens the right file, first try.
>
> After the rebuild, Locant finds the same element again on its own. Show before & after: both images, with
> the diff beneath.

**SCREEN**
Take B: the menu bar, Show before & after, the window. Drag the slider once, Flip. Hold on the file list.

**NOTE**
Keep every cut on a beat of the action: the label appearing, the toast `Copied · captureButton`, the agent's
first tool call opening the file, the Before & After window opening. The click, the note, and Enter are shown,
not narrated.

---

## 4. Before and after (2:27 to 2:43)

**SCREEN**
The results table from `03-before-script.md`, rendered at `~/Desktop/locant-film/v4/measure/results-table.png`,
rows appearing one at a time, time first. The runs were headless (no split-screen footage); if you want the
split screen, re-run one pair on camera with `03`'s interactive steps and cut it under the same line.

**VOICE**
> Same fix, same model, same repo.
>
> From a screenshot, the agent read the whole screen and opened several files before it found the button.
> From Locant, it went straight there.
>
> > Three runs each. From paste to the edit: fifty-two seconds with Locant, a hundred and twelve from a screenshot.
> Same tokens, half the time.

**NOTE**
The numbers are the medians of three headless runs per side (`03`, "Results"). The token claim is deliberately
"same": the session totals came out equal. Do not say "fewer tokens" on camera.

---

## 5. If I had more time (2:43 to 2:55)

**SCREEN**
The Locant highlight over one element on a web page in a browser (scene 8's fourth hover, `sceneD2-comp.mp4`),
its label reading a role and a name but no identifier. Simple. The MCP server shipped in 0.7.1 and is already on
screen in the demo (Cursor asks Locant for the element), so it is no longer "next".

**VOICE**
> Next is the web: a small extension that adds the CSS selector, so pointing works the same on any page.
>
> Point, don't describe.

**SCREEN**
End card: icon, **Locant**, the dictionary line from the site ("lo·cant, noun: the number in a chemical name that says
exactly where a group is attached"), the site URL, the repo URL. Three seconds, then out.

---

## Timing budget

| Section | Target | Words | Read at 150 wpm | Read at 160 wpm |
|---|---|---|---|---|
| 1 Why | 0:52 | 136 | 0:54 | 0:51 |
| 2 How | 1:14 | 206 | 1:22 | 1:17 |
| 3 Demo | 0:20 | 42 | 0:16 | 0:15 |
| 4 Before and after | 0:20 | 55 | 0:22 | 0:21 |
| 5 Next | 0:12 | 21 | 0:08 | 0:08 |
| **Total** | **2:59** | **460** | **3:04** | **2:53** |

Add three seconds of silence at the top of the demo, the end card, and the pauses between sections: about ten
seconds. At 160 words a minute the video lands near 3:03, so apply the first two cuts in the list at the end of
`04-voiceover.md` (they save about six seconds) at any pace; at 150 apply the third as well. Read the voice-over aloud with a stopwatch before recording anything.
