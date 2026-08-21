---
name: mm-time-blocking
description: Turns Michael's ranked work into calendar blocks. Takes the triage from mm-today — what's over the line, whose court the ball is in, what he promised — reads the real calendar, and lays focus blocks into the gaps. Offers a few competing plan philosophies before committing, and always shows a table of proposed changes before touching the calendar. Use when he says "block my calendar", "plan my day", "I have too much to do today", "I'm a bottleneck", "I need to fit X and Y before Friday", or dumps a list of work and wants it scheduled. For deciding *what* matters, use mm-today; this skill decides *when*.
allowed-tools: Bash(*), Read, Write
---

# mm-time-blocking

Turn a ranked pile of work into a calendar plan he can trust.

He is usually pressed for time when he asks for this, so move efficiently. Don't gather more than needed, and don't propose more than necessary before getting his input on the real forks.

## 1. Get the inventory from mm-today

**Do not re-derive the work list.** [[mm-today]] already sweeps his open PRs, his review queue, team Slack at Zeta Labs, and the promises he has made, then ranks them by whose court the ball is in. It knows things this skill should not have to: which handles are his teammates, that asking for a stamp in Slack is not the same as requesting a reviewer, that landing stalled work beats starting new work.

So:

- **If mm-today already ran in this session**, use its report as the inventory. Don't run it again.
- **Otherwise run it**, then plan from its output.
- **If he has dumped a task list conversationally instead**, take him at his word and use that — but still glance at `~/.claude/mm-today-state.json` for his `wip` trend and `principles`, because a plan that ignores a growing WIP count is planning the wrong day.

What comes back maps onto blocks directly:

| mm-today section | What it means for the calendar |
|---|---|
| **OVER THE LINE** | Finished work that is stalled. Schedule first, and early — these are minutes of his time that unstall someone else's days. |
| **THE DAY** | The main ranked work. This is the body of the plan. |
| **PROMISES** | Things he said he would do. Small, usually. Good end-of-day filler, unless someone is blocked. |
| **FROM TEAM SLACK** | Context, not tasks. Usually a followup for a sync, not a block. |

Add time estimates it doesn't carry. If an item has no estimate, guess from its shape and say what you assumed — don't make him estimate every line, that is the exact friction this skill exists to remove. Where he gave a range, record the lower bound but budget nearer the upper one. Reviews of large diffs almost always run long.

## 2. Look at the calendar before proposing anything

Call `list_events` (or the connector's equivalent) over today through the end of his stated availability. Note:

- Hard commitments — accepted meetings, anything he organises
- Soft commitments — optional, tentative, declined. Flag these and offer to skip them
- All-day OOO or "meeting free" markers, often `transparency: transparent`. Signals, not blockers
- His working hours and timezone — infer from the calendar's timezone field if unstated

Proposing a plan that collides with his existing calendar wastes the whole interaction. Inventory first, propose second.

## 3. Compare the time budget to the task budget

Sum the estimates against free time in the window. Be honest immediately if it does not fit, and ask what to drop or push.

When it is close, say so out loud — "seven hours of focus time against about six and a half of work, tight but it fits". He wants to feel in control, not ambushed at 4 PM.

## 4. Order by energy and dependency

Rules of thumb that hold up:

- **Deep work in the morning.** RFCs, writing, design — anything where focus is the point. His freshest hours go to work that benefits most from them.
- **Reviews and analysis after that.** They need attention but not invention. Late morning, early afternoon.
- **Light operational work at the end of day** — inbox, a dashboard, a quick query. Energy dips; these don't mind.
- **Unblock people before their day ends.** A review that frees someone overnight is worth more today than tomorrow. This is why OVER THE LINE goes early.
- **Leave 15–30 minutes between deep work and reviews.** Context-switch tax is real.

Defaults, not commandments. If he signals otherwise, follow him.

## 5. Propose, don't impose

**On the first pass, offer two or three distinct takes — never a single schedule.** The same list sequences differently depending on what he is optimising for that week, and he often only works out which when he sees them side by side:

- **Unblock-others-first** — front-load reviews and OVER THE LINE items, deep work second.
- **Deep-work-first** — protect one large uninterrupted block for the highest-impact item, fit the rest around it.
- **Clean-the-decks** — attack his own WIP sprawl first. Right when the `wip` trend in mm-today's state is climbing, or when he calls himself a bottleneck.

Give each a rough shape and the tradeoff in one line. Keep them comparable: same fixed meetings, same total work, different order. Let him pick a philosophy *before* you build exact times. Skipping to one detailed plan usually guesses wrong and burns the iteration.

**Always show a table of proposed calendar changes before writing them. No exceptions.** That covers the initial plan, any follow-up edit however small — colour tweaks, time shifts, renames, single moves, lunch adjustments, cascades from another change — and bulk operations.

Columns: **When**, **Block**, and **Change** where relevant, showing old → new so the diff is unambiguous. Then wait for an explicit yes before calling any create, update, or delete. Don't put the table in the same message that invokes the tools.

This matters because his calendar is a shared, persistent surface. Surprise mutations erode trust and are hard to audit. The table costs ten seconds and buys a clean "yes" / "swap this" / "no".

Then ask about the forks that genuinely vary — not everything at once, and use AskUserQuestion:

- **Optional meetings inside a focus window** — skip, attend, or split the block?
- **Overflow** — push to the next day, or drop something to squeeze it in?
- **Visibility** — private (busy, no title) or default? He often wants private for sensitive review topics or RFC names.
- **Busy vs. Free** — some people want focus blocks to deter scheduling, others want to stay bookable.

## 6. Create the events

Only after he confirms.

- **Real newlines in descriptions, not HTML entities.** `\n` in the JSON string becomes a line break. `&#10;` stores the literal entity and renders as gibberish. The field does accept HTML, but `\n` is simpler.
- **Colour by work type, and only these two.** Deep work — RFCs, writing, design — is **Tomato**, `colorId: "11"`, the visual anchor of the day. Every other focus block — reviews, analysis, ops, inbox — is **Tangerine**, `colorId: "6"`. Distinct from the default so blocks read as intentional, visibly secondary to the deep-work block. More colours defeat the point.
- **Scannable titles.** `Focus: <thing>` for deep work, `Review: <thing>` for reviews.
- **Set `visibility: private` when he asks** — but check whether the connector exposes *transparency* (free vs. busy). Many calendar MCPs expose `visibility` and not `transparency`. If you cannot set it, say so and explain the manual fix rather than pretending it worked.

## 7. Close the loop

End by surfacing what is left over:

- Anything the connector could not do — the free/busy toggle being the usual one
- Anything pushed to a later day
- Anything he will plausibly want help with next ("your first block starts in ten minutes — want me to pick up the SQL when you're in it?")

Make the leftover surface area visible so he can decide about it.

## His recurring commitments

Fixed. Never schedule focus blocks over them. They usually appear on the calendar as recurring events, but they are listed here so a plan stays correct even when the query window misses them.

- **Mon / Wed / Fri morning** — team sync
- **Mondays, 5:30 PM** — company all-hands
- **Tuesdays, 10:00 PM** — gym, 1 hour. Block 9:45–11:15 PM for 15 minutes either side.
- **Fridays, 5:00 PM** — gym, 1 hour. Block 4:45–6:15 PM.
- **Lunch, every day, 45 minutes.** Mon–Thu somewhere between 1:00 and 4:00 PM, wherever it fits around meetings. **Fridays always 2:00 PM.** Don't skip it unless he explicitly says to pack the day. A half-day plan ending before 1:00 PM doesn't need it.

On Mon / Wed / Fri leave the team-sync slot blank and start after it. For late-day work, end deep work at least 15 minutes before the gym buffer. Prefer lunch at 1:00 PM or later, and on Fridays anchor at 2:00 PM and plan around it.

## Things that have gone wrong before

- **HTML-entity newlines in descriptions.** Use real `\n`. Read one event back if unsure the connector handled it.
- **Events set busy when he wanted free.** If the connector doesn't expose transparency, do not silently leave them busy and claim success. Say so, and give the one-sentence manual fix.
- **Over-questioning.** If mm-today already ranked the work, don't ask what matters — it answered that. Save questions for real forks: optional meetings, visibility, overflow.
- **Taking "I usually work 9 to 6" literally.** A soft signal. A 7:30 PM personal event ends the day earlier; OOO from 2 PM means the morning block ends at 2 PM.
- **Forgetting carryover.** If it doesn't all fit, say what moved and to when. He came here overloaded; "this is Monday morning" beats leaving him to find where PR #4 went.
- **Re-deriving the PR queue.** Older versions of this skill fetched GitHub directly and kept their own list of teammate handles, which drifted from mm-today's. There is one triage, and it lives there.

## What not to do

- Don't write a script. The value is the workflow, not automation.
- Don't get clever about moving other people's meetings. Stay in the lane of blocking his own time.
- Don't add scheduled tasks or artifacts unless asked. This is one-shot planning.

## When this skill is the wrong one

- He wants to know *what* to work on, not when — that's [[mm-today]] alone.
- He wants to schedule a meeting with someone else — different shape entirely: suggest_time, attendees.
- He wants a recurring system — combine with the scheduling tool; the planning workflow itself is unchanged.
- He wants a to-do list without calendar blocks — drop the calendar tools, keep the ordering logic.
