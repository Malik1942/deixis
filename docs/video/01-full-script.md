# Locant: full script

Runtime target **2:55** (measured from the word counts below). Hard cap 3:00. The brief says less is more, so cut before you pad.

Framing: this is a pitch told as a path. Frustration, approach, proof, next. The demo is evidence for the pitch,
not the point of the video. Every section ends on one sentence the viewer can repeat.

Format: **VOICE** is what you say. **SCREEN** is what is shown. **NOTE** is production direction. Times are targets.

---

## 1. Why this was worth solving for me (0:00 to 0:38)

**SCREEN**
No title card. Open on your desktop as it really is when you work: the iOS Simulator with your app on the left,
Cursor on the right, the cursor resting on a button that is not quite right. Hold two seconds, then start
talking. If you want to be on camera, this is the only section for it.

**VOICE**
> I build my own apps alone. A coding agent does most of the typing.
>
> It was the moment after I saw something wrong that wore me down.
> A button that should be rounder. Then I'd sit there composing the prompt.
> Which screen. Which component. Where it sits in the tree.
> By the time I'd written it, I'd lost the thing I was actually going to say.

**SCREEN**
Cutaways, two seconds each: you typing a long description into Cursor and deleting half of it; a
full-screen screenshot pasted into the prompt; the agent's reply asking which button, or opening the wrong file
(both from the before-video takes).

**VOICE**
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

## 2. How I approached it (0:39 to 2:07)

The brief weighs this section most: decisions, challenges, what is worth highlighting, where AI came in. Each
decision is told as a tension and a choice, so the viewer hears why, not just what.

**SCREEN**
`build-canvas.mp4`: the overlay states drawn on the Claude Design canvas before any code, timer at 2:59:57. Then
`build-timelapse-3h.mp4` under the first two decisions: the whole three-hour window in twenty seconds, the timer
counting down in the menu bar.

**VOICE**
> The smallest useful loop: hover, click, type what should change, paste.
>
> Four decisions.

**SCREEN**
The payload in Cursor's input (reel 0:26 to 0:30) with `id=oceanCurrent.product ideas` readable, then the agent's
"Using Locant to pull the capture" and the diff chip (reel 0:31 to 0:43).

**VOICE**
> One. The accessibility tree, not the pixels. A pixel is a guess; an identifier is something an agent can grep.
> It goes out as plain Markdown, image path first, so any agent can take it.

**SCREEN**
The fallback ladder from the site, five rungs, one per second (`site-ladder-reveal.mp4`).

**VOICE**
> Two. No identifier? It steps down a ladder: label and neighbors, a drawn frame, text, then the image alone.
> And it says which rung it reached.

**SCREEN**
The four action cards, one per second (`site-actions-reveal.mp4`), then the Color pick from the reel (1:12 to 1:19).

**VOICE**
> Three. It had to replace my screenshot tool, or I'd keep switching apps while polishing. So Snap, Text, Color,
> and Cut ride the same gesture.

**SCREEN**
The ball, real footage (reel 1:05 to 1:12): docked, waking, the hand, the hold, the ring unfolding.

**VOICE**
> Four. The ball. A hotkey is invisible and the menu bar is far. So: a quiet disc that wakes when you reach for
> it. Click to point. Hold, and a ring unfolds; release on an action. Round, so four directions open from one spot.

**SCREEN**
`build-null-element.mp4` at 1×: the first capture on the Oryne orb reads `No element information available (app
exposes no accessibility tree)`, timer at 1:42. Then `sceneF-comp.mp4`: the overlay over Locant's own Settings
window, and the label names a button in the Cursor window behind it.

**VOICE**
> Two things fought back. My own app's orbs were invisible to accessibility; the ladder came out of that.
> And Locant must never see itself, so it filters its own windows out of every capture.

**SCREEN**
`build-scaffold.mp4` (the PRD becoming a v0.1 plan), `build-decision.mp4` (your "finish the product first, MCP
later" message, 45 tests passing), `build-v04-timer.mp4` (the diff chip `+381 −40`, the agent reading a capture
of Locant's own frame overlay, timer 0:12:54).

**VOICE**
> AI came in everywhere except the decisions. The overlay was drawn with Claude before any code.
> One spec per version, written with Claude; the Swift by Claude Code.
> And I used Locant to build Locant.

**SCREEN**
`build-v04-timer.mp4` holds through this line: the timer reads 0:12:54.

**VOICE**
> Versions 0.1 to 0.4 were built inside the three-hour window, timer running. 0.5 came the next day.
> I'm the only author.

**NOTE**
Confirmed Sep 15. The site ribbon says "v0.4 built in 3 hours"; the video says the same thing in more words, and
the timer on screen is the proof. The brief's sole-author call-out is the last sentence.

---

## 3. Demo (2:08 to 2:26)

**SCREEN**
Take A from `02-demo-script.md`, cut to length. Three seconds with no narration; let the hotkey, hover, and
click play with sound. The agent on screen is Cursor: the payload lands in its Agent chat and the diff shows in the editor.

**VOICE**
> Double-tap Control. Hover; Locant says what it sees before I click.
>
> Paste into Cursor. It opens the right file.
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

## 4. Before and after (2:27 to 2:44)

**SCREEN**
The results table from `03-before-script.md`, rendered at `~/Desktop/locant-film/v4/measure/results-table.png`,
rows appearing one at a time, time first. The runs were headless (no split-screen footage); if you want the
split screen, re-run one pair on camera with `03`'s interactive steps and cut it under the same line.

**VOICE**
> From a screenshot, the agent read the whole screen and opened several files before it found the button.
> From Locant, it went straight there.
>
> > From paste to the edit: fifty-two seconds with Locant, a hundred and twelve from a screenshot.
> Same tokens, half the time.

**NOTE**
The numbers are the medians of three headless runs per side (`03`, "Results"). The token claim is deliberately
"same": the session totals came out equal. Do not say "fewer tokens" on camera.

---

## 5. If I had more time (2:45 to 2:57)

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

Word counts are from `04-voiceover.md` after the Sep 15 cuts. Silence is budgeted at 11 seconds: two at the open,
three before the demo, three on the end card, three of pauses between sections.

| Section | Target | Words | Read at 160 wpm | Read at 150 wpm |
|---|---|---|---|---|
| 1 Why | 0:38 | 96 | 0:36 | 0:38 |
| 2 How | 1:28 | 233 | 1:27 | 1:33 |
| 3 Demo | 0:18 | 41 | 0:15 | 0:16 |
| 4 Before and after | 0:17 | 45 | 0:17 | 0:18 |
| 5 Next | 0:12 | 23 | 0:09 | 0:09 |
| Silence | 0:11 | | 0:11 | 0:11 |
| **Total** | **2:55** | **438** | **2:55** | **3:05** |

Read at 160 words a minute and the video lands at 2:55. At 150 it lands at 3:05, so at that pace apply the
remaining cuts in `04-voiceover.md` (they save about eight seconds) or trim the silence. Read aloud with a
stopwatch before recording anything; do not speed up to fit.
