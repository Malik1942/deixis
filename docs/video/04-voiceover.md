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
- **One line to confirm before the mic.** The time-window line in section 2 is still marked `[CONFIRM]`. The
  section 4 numbers are measured (medians of three runs, `03-before-script.md`).

---

## 1. Why · 136 words · 0:00 to 0:52

I build my own apps alone. A coding agent does most of the typing.

What wore me down wasn't the code. It was the moment after I saw something wrong.
A button that should be rounder. Half a second to see it. Then I'd sit there composing the prompt.
Which screen. Which component. Where it sits in the tree.
By the time I'd written it, I'd lost the thing I was actually going to say.

Or I'd paste a screenshot, and watch the agent guess.

Browser tools fix this for the web. Others send a whole window to one agent.
I wanted to point at one element in any app, and hand it to whichever agent I'm using.

I know what I mean by "this button." My agent doesn't.
Pointing is how people resolve "this."

---

## 2. How · 206 words · 0:52 to 2:05

The smallest loop that could be useful: hotkey, hover, click, type what should change, Enter, paste.

Four decisions shaped it.

One. It reads the accessibility tree, not the pixels. The identifier is the one thing an agent can grep for, and
it goes out as plain Markdown, image path first, so every agent can take it.

Two. No identifier? It steps down a ladder: label and neighbors, a drawn frame, text, then the image alone.
And it says which rung it reached.

Three. It had to replace my screenshot tool, or I'd still be switching apps while polishing. So Snap, Text,
Color, and Cut ride the same gesture. Images keep a file; text and colors keep nothing.

Four. One gesture, five actions. The ball is a quiet disc that wakes when you reach for it. Click to point.
Hold it, a ring unfolds, release on the action you want. Round, so four directions can open from it.

The challenge was in the seams: my own app's orbs were invisible to accessibility.

AI came in everywhere except the decisions: specs with Claude, Swift by Claude Code. And I used Locant to build
Locant.

[CONFIRM] Versions 0.1 to 0.4 were built inside the three-hour window, timer running. 0.5 came the next day.
I'm the only author.

---

## 3. Demo · 42 words · 2:05 to 2:27

*(Three seconds of silence first. Let the hotkey and hover play with sound.)*

Double-tap Control. Hover; Locant says what it sees before I click.

Paste into Cursor. It opens the right file, first try.

After the rebuild, Locant finds the same element again on its own. Show before & after: both images, with
the diff beneath.

---

## 4. Before and after · 55 words · 2:27 to 2:47

Same fix, same model, same repo.

From a screenshot, the agent read the whole screen and opened several files before it found the button.
From Locant, it went straight there.

Three runs each. From paste to the edit: fifty-two seconds with Locant, a hundred and twelve from a screenshot.
Same tokens, half the time.

---

## 5. Next · 21 words · 2:47 to 2:57

Next is the web: a small extension that adds the CSS selector, so pointing works the same on any page.

Point, don't describe.

---

## Cut list, in order, if the read runs long

1. Section 2: "Images keep a file; text and colors keep nothing." (saves ~3 s)
2. Section 2: "Round, so four directions can open from it." (~3 s)
3. Section 3: "first try." (~1 s)
4. Section 1: "Or I'd paste a screenshot, and watch the agent guess." Only if the before video is dropped. (~3 s)

Never cut: "By the time I'd written it, I'd lost the thing I was actually going to say," the universal-capture
sentence ("one element in any app... whichever agent"), "Pointing is how people resolve this," "the accessibility tree, not the pixels," the ladder,
"replace my screenshot tool," "one gesture, five actions," the time-window sentence, the numbers, "I used Locant
to build Locant," and the last line.
