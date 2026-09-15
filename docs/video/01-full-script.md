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
desktop. On "any app": three quick hovers with the Locant highlight, over Calculator, over an Electron app, over
the Simulator (the site's overlay frames work here). On "whichever agent": the payload pasted into the Codex CLI,
then the same payload in Claude Code.

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
The PRD in a text editor, scrolled slowly. Then the specs folder: `v0.1.md` ... `v0.5.md`.

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
The fallback ladder from the site, five rungs, animating down one at a time.

**VOICE**
> Two. No identifier? It steps down a ladder: label and neighbors, a drawn frame, text, then the image alone.
> And it says which rung it reached.

**SCREEN**
The four action cards from the site (Snap, Text, Color, Cut) with their "keeps a file / keeps nothing" lines.
Then `~/Pictures/Locant/` in Finder with its tags, and the Retention row in Settings.

**VOICE**
> Three. It had to replace my screenshot tool, or I'd still be switching apps while polishing. So Snap, Text,
> Color, and Cut ride the same gesture. Images keep a file; text and colors keep nothing.

**SCREEN**
The ball, real footage, at 1:1: docked at the edge, waking as the cursor approaches, the hand appearing, then
press and hold, the ring unfolding with the four segments and their numbers, release on Color, the magnifier.
Let it play under the whole of decision four.

**VOICE**
> Four. One gesture, five actions. The ball is a quiet disc that wakes when you reach for it. Click to point.
> Hold it, a ring unfolds, release on the action you want. Round, so four directions can open from it.

**SCREEN**
The Oryne orb under the overlay: first with `No element information available`, then, after your fix, with the
highlight and `oceanCurrent` in the label.

**VOICE**
> The challenge was in the seams: my own app's orbs were invisible to accessibility.

**SCREEN**
Claude Code, a spec file on the left, a diff on the right. `xcodebuild test` finishing: 64 tests. Last, Locant's
own Settings window under the Locant overlay.

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
Split screen from `03-before-script.md`: the same fix from a screenshot on the left, from Locant on the right,
timers running. End on the results table.

**VOICE**
> Same fix, same model, same repo.
>
> From a screenshot, the agent read the whole screen and opened several files before it found the button.
> From Locant, it went straight there.
>
> `[NUMBERS]` ___ times fewer tokens. ___ seconds instead of ___.

**NOTE**
Fill `[NUMBERS]` from the measured table only. If the runs vary, say "in three runs, the median was." The
image-token line is the one part you can compute rather than measure; see `03`.

---

## 5. If I had more time (2:43 to 2:55)

**SCREEN**
The menu bar with the pointing hand. Simple.

**VOICE**
> Next is an MCP server, so the agent can ask Locant "what's under the cursor" itself.
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
| 4 Before and after | 0:16 | 41 | 0:16 | 0:15 |
| 5 Next | 0:12 | 24 | 0:09 | 0:09 |
| **Total** | **2:55** | **449** | **2:59** | **2:48** |

Add three seconds of silence at the top of the demo, the end card, and the pauses between sections: about ten
seconds. At 160 words a minute the video lands near 2:58, under the cap. At 150 it lands near 3:09,
so at that pace apply the first two cuts in the list at the end of `04-voiceover.md` (they save about six
seconds). Read the voice-over aloud with a stopwatch before recording anything.
