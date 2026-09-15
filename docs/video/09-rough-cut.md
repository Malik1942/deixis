# Rough cut v1: voice-over cue sheet

`~/Desktop/locant-film/v4/rough/locant-pitch-roughcut-v1.mp4`, 2560×1440, 60 fps, silent, 2:58. Hard cuts, no music,
title card at 0:38 and end card at 2:55. Every segment is listed with the timecode it starts at and the line to say over it.
Record the narration against this file; the fine cut then moves cuts to the words, not the other way round.

Built by `rough/build.sh` from the scene files, the build clips, the site reveals, the results reveal and two cards.
Take G (`takeG.mov`, composing a prompt in Cursor and deleting it, sped 2.6×) is the one new take.

| Start | # | On screen | Say |
|---|---|---|---|
| 0:00 | 01 | desktop as it is (take A wide) (7.0 s) | *(hold; no words for the first two seconds)* I build my own apps alone. A coding agent does most of the typing. |
| 0:07 | 02 | composing the prompt in Cursor (take G) (17.0 s) | It was the moment after I saw something wrong that wore me down. A button that should be rounder. Then I'd sit there composing the prompt. Which screen. Which component. Where it sits in the tree. By the time I'd written it, I'd lost the thing I was actually going to say. |
| 0:24 | 03 | any app: Calculator, CalmMouse, the orb (4.2 s) | I wanted to point at one element in any app, |
| 0:28 | 04 | any app: a web page (3.0 s) |  |
| 0:31 | 05 | whichever agent: Codex (2.0 s) | and hand it to whichever agent I'm using. |
| 0:33 | 06 | whichever agent: Claude Code (2.0 s) |  |
| 0:35 | 07 | this button: the orb label (3.0 s) | I know what I mean by "this button." My agent doesn't. |
| 0:38 | 08 | TITLE Locant / Point, don't describe. (3.0 s) | Pointing is how people resolve "this." |
| 0:41 | 09 | canvas before code (timer 2:59:57) (4.0 s) | The smallest useful loop: hover, click, type what should change, paste. |
| 0:45 | 10 | three-hour time-lapse (8.0 s) | Four decisions.  One. The accessibility tree, not the pixels. A pixel is a guess; an identifier is something an agent can grep. |
| 0:53 | 11 | decision 1: the payload lands in Cursor (5.0 s) | It goes out as plain Markdown, image path first, so any agent can take it. |
| 0:58 | 12 | decision 1: the diff chip (2.8 s) |  |
| 1:01 | 13 | decision 2: the ladder (9.0 s) | Two. No identifier? It steps down a ladder: label and neighbors, a drawn frame, text, then the image alone. And it says which rung it reached. |
| 1:10 | 14 | decision 3: the four actions (5.0 s) | Three. It had to replace my screenshot tool, or I'd keep switching apps while polishing. |
| 1:15 | 15 | decision 3: Color pick (4.9 s) | So Snap, Text, Color, and Cut ride the same gesture. |
| 1:19 | 16 | decision 4: the ball wakes, click to point (6.0 s) | Four. The ball. A hotkey is invisible and the menu bar is far. So: a quiet disc that wakes when you reach for it. Click to point. |
| 1:25 | 17 | decision 4: hold, ring, release (9.5 s) | Hold, and a ring unfolds; release on an action. Round, so four directions open from one spot. |
| 1:35 | 18 | challenge 1: no element information (timer 1:42) (6.0 s) | Two things fought back. My own app's orbs were invisible to accessibility; the ladder came out of that. |
| 1:41 | 19 | challenge 2: Locant never sees itself (5.0 s) | And Locant must never see itself, so it filters its own windows out of every capture. |
| 1:46 | 20 | AI: PRD to v0.1 plan (4.0 s) | AI came in everywhere except the decisions. The overlay was drawn with Claude before any code. |
| 1:50 | 21 | AI: finish the product first, 45 tests (6.0 s) | One spec per version, written with Claude; the Swift by Claude Code. And I used Locant to build Locant. |
| 1:56 | 22 | time: v0.4, timer 0:12:54, diff chip (9.0 s) | Versions 0.1 to 0.4 were built inside the three-hour window, timer running. 0.5 came the next day. I'm the only author. |
| 2:05 | 23 | demo: dim, Ocean, Resurfacing, the orb (7.5 s) | *(three seconds of silence)* Double-tap Control. Hover; Locant says what it sees before I click. |
| 2:12 | 24 | demo: paste into Cursor (3.0 s) | Paste into Cursor. |
| 2:15 | 25 | demo: the right file (2.8 s) | It opens the right file. |
| 2:18 | 26 | demo: Show before & after (5.0 s) | After the rebuild, Locant finds the same element again on its own. Show before & after: |
| 2:23 | 27 | demo: divider (4.0 s) | both images, with the diff beneath. |
| 2:27 | 28 | demo: Flip (2.0 s) |  |
| 2:29 | 29 | results table (16.0 s) | Same fix, two ways, six runs each. From a screenshot, the agent stopped to ask me which orb, five times out of six. From Locant, it never asked: it grepped the identifier and opened the file. What Locant saves is the question. |
| 2:45 | 30 | next: the web page hover (9.0 s) | Next is the web: a small extension that adds the CSS selector, so pointing works the same on any page.  Point, don't describe. |
| 2:54 | 31 | END CARD (4.0 s) | *(end card, silent)* |

## What to check

- Section 1 has no footage for "the agent guessing from a screenshot"; that line was cut, so nothing is missing on screen.
- The two agent pastes (0:31, 0:33) are two seconds each: enough to see a different window, not to read.
- Section 2 shows the ball twice on purpose: decision 4 (1:20) and the demo (2:05). If it reads as a repeat, the demo can open on the dim instead.
- The results table rows appear every 2.2 s; the narration for section 4 is about 17 s, so the last row lands on "half the time".
- Cards are SF Pro on black to match the site, per the film contract's Brand block.
