# Locant: voice-over

Clean narration, in order, with timing. Print this page. Nothing here is on screen; the screen directions are in
`01-full-script.md`.

## Before you record

- **Pronunciation.** Locant: *LOH-kant*, stress on the first syllable. In chemistry the locant is the number that
  says exactly where a group sits, the 2 in 2-methylbutane. One number, one molecule.
- **Pace.** Read at 150 to 160 words a minute. The whole read is sized for the 3:00 cap with about ten seconds of
  silence and pauses; if a section runs more than three seconds over its target, cut a sentence, do not speed up.
- **Delivery.** Talk to one person who has never seen the app. Plain words, short sentences, full stops. Pause a
  full second at every blank line. Land on "Point, don't describe." and stop.
- **Section 1 is the pitch.** Slow down on the list "which screen, which component, where it sits." That list is
  the cognitive load; each item is a separate thought.
- **Takes.** Record each section as its own file, three takes each, then pick. Leave two seconds of room tone at
  the head and tail of every file.
- **Nothing left to confirm.** The time-window line is confirmed (Sep 15) and the section 4 numbers are measured
  (medians of three runs, `03-before-script.md`). The cuts below are already applied; the list is kept for a
  slower read.

---

## 1. Why · 96 words · 0:00 to 0:38

I build my own apps alone. A coding agent does most of the typing.

It was the moment after I saw something wrong that wore me down.
A button that should be rounder. Then I'd sit there composing the prompt.
Which screen. Which component. Where it sits in the tree.
By the time I'd written it, I'd lost the thing I was actually going to say.

I wanted to point at one element in any app, and hand it to whichever agent I'm using.

I know what I mean by "this button." My agent doesn't.
Pointing is how people resolve "this."

---

## 2. How · 233 words · 0:39 to 2:07

The smallest useful loop: hover, click, type what should change, paste.

Four decisions.

One. The accessibility tree, not the pixels. A pixel is a guess; an identifier is something an agent can grep.
It goes out as plain Markdown, image path first, so any agent can take it.

Two. No identifier? It steps down a ladder: label and neighbors, a drawn frame, text, then the image alone.
And it says which rung it reached.

Three. It had to replace my screenshot tool, or I'd keep switching apps while polishing. So Snap, Text, Color,
and Cut ride the same gesture.

Four. The ball. A hotkey is invisible and the menu bar is far. So: a quiet disc that wakes when you reach for it.
Click to point. Hold, and a ring unfolds; release on an action. Round, so four directions open from one spot.

Two things fought back. My own app's orbs were invisible to accessibility; the ladder came out of that.
And Locant must never see itself, so it filters its own windows out of every capture.

AI came in everywhere except the decisions. The overlay was drawn with Claude before any code.
One spec per version, written with Claude; the Swift by Claude Code.
And I used Locant to build Locant.

Versions 0.1 to 0.4 were built inside the three-hour window, timer running. 0.5 came the next day.
I'm the only author.

---

## 3. Demo · 41 words · 2:08 to 2:26

*(Three seconds of silence first. Let the hotkey and hover play with sound.)*

Double-tap Control. Hover; Locant says what it sees before I click.

Paste into Cursor. It opens the right file.

After the rebuild, Locant finds the same element again on its own. Show before & after: both images, with
the diff beneath.

---

## 4. Before and after · 45 words · 2:27 to 2:44

Same fix, two ways, six runs each. From a screenshot, the agent stopped to ask me which orb, five times out
of six. From Locant, it never asked: it grepped the identifier and opened the file.

What Locant saves is the question.

---

## 5. Next · 23 words · 2:45 to 2:57

Next is the web: a small extension that adds the CSS selector, so pointing works the same on any page.

Point, don't describe.

---

## Cut list

Applied on Sep 15 (the read was 3:24 at 160 words a minute): "Others send a whole window to one agent"; "Half a
second to see it"; "Or I'd paste a screenshot, and watch the agent guess"; "Browser tools fix this for the web";
"Three runs each"; "first try"; "No plugin, no lock-in"; "so the agent knows how much to trust it"; "Images keep a
file; text and colors keep nothing"; "The calls about scope were mine"; the loop sentence and the canvas sentence
shortened. About 70 words, 27 seconds.

If the stopwatch still says over 2:58, in this order:

1. Section 2: "Point at its Settings, and it names what's behind." (~3 s; keep the footage, drop the words)
2. Section 1: "What wore me down wasn't the code." (~2 s)
3. Section 4: "Same fix, same model, same repo." (~2 s; the table on screen says it)
4. Section 3: "Double-tap Control." (~1 s)

Never cut: "By the time I'd written it, I'd lost the thing I was actually going to say," the universal-capture
sentence ("one element in any app... whichever agent"), "Pointing is how people resolve this," "the accessibility
tree, not the pixels," "a pixel is a guess," the ladder, "replace my screenshot tool," "a hotkey is invisible and
the menu bar is far," "Round, so four directions open from one spot," both challenges, the time-window sentence,
the numbers, "I used Locant to build Locant," and the last line.
