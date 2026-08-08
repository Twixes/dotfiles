---
name: focus-time-blocking
description: Help the user carve focused work blocks onto their calendar from a list of tasks they want to get done. Triggers whenever the user describes feeling overwhelmed, has a queue of things to do (PR reviews, RFCs, analysis, admin tasks), and wants help planning a day, half-day, or stretch of time before they're out. Use this whenever the user says things like "block my calendar", "block out time for", "I have too much to do today and not enough time", "I'm a bottleneck", "plan my day", "I need to fit X and Y and Z before Friday", or describes priorities + time estimates and asks for help scheduling. Also use this when the user lists work items in a conversational dump (RFC, reviews, dashboards to look at, DB checks) — they want a calendar plan even if they didn't explicitly say "make calendar events". Especially useful for team leads juggling IC work, reviews, and high-impact strategic work.
allowed-tools: Bash(*), Read, Write
---

# Focus time blocking

This skill helps someone offload "what should I do when" onto Claude. The user has a stack of work to do and a finite window. Help them turn a messy verbal task dump into a clean, realistic calendar plan they can trust.

The user is usually pressed for time when they ask for this, so move efficiently. Don't gather more than needed; don't propose more than necessary before getting their input on the key choices.

## Workflow

### 1. Capture the inventory

From what the user already said, build a working list of tasks with:

- A short label
- Estimated time
- Priority / impact (their words — "high impact", "don't want to block teammate", "operational")
- Any constraints (deadline, depends on another person, energy level required)

If the user gave time estimates in ranges ("30 min at least"), record the lower bound but budget closer to the upper bound when slotting. PR reviews of large diffs almost always run long.

If they didn't give a time estimate for something, take a guess based on the kind of task and tell them what you assumed. Don't ask them to estimate every item — that's the exact friction this skill exists to remove.

### 2. Inventory GitHub PRs and triage with the user

Before settling the work list, **always check GitHub directly** rather than relying on what the user verbally remembered. A real PR queue beats a recalled one — drafts get forgotten, reviewer assignments pile up unnoticed, stale work hides in plain sight. Use whatever's available, in order of preference:

1. A GitHub MCP connector (search the registry if unsure — keywords like "github", "pull request"). Best option: handles auth, private repos, field selection, and write actions (closing PRs).
2. The `gh` CLI in the shell sandbox — note it's often not installed and the sandbox usually has no root to `apt-get` it, and it needs an auth token anyway.
3. **The public GitHub REST API via the web-fetch tool** — this works with no auth for public repos and is the reliable fallback. Details below.

If none work for what you need (e.g. private repos with no MCP), say so plainly — don't guess at the queue. Suggest the user install a GitHub MCP and proceed with whatever inventory they gave you verbally, flagged as incomplete.

#### Using the public REST API via web-fetch (the proven fallback)

Hit the search endpoint, e.g. `https://api.github.com/search/issues?q=is:pr+is:open+author:USERNAME+repo:OWNER/REPO&sort=updated&order=desc&per_page=5`. Two hard-won lessons:

- **The JSON includes full PR bodies, which are huge for agent-authored PRs and overflow the tool's token limit.** Keep `per_page` small (≈5) and paginate with `&page=N`. A single overflowing response gets saved to a host temp file you usually can't reach from the sandbox, so prevention (small pages) beats trying to read it back.
- **Don't bother with the HTML PR-list pages** (`github.com/OWNER/REPO/pulls?q=...`) — they're JavaScript-rendered, so web-fetch gets an empty shell. The API is the way.
- Useful queries: `author:USERNAME` (their own PRs), `review-requested:USERNAME` (their reviewer queue — this is the authoritative "what's waiting on me"), and the same per teammate. The `stale` label and `created_at`/`updated_at` tell you what's aging.
- **Verify usernames** — a one-character typo returns an empty result that looks like "no PRs" rather than an error. If a teammate's query comes back empty, suspect the handle before concluding they have nothing open.

Pull these views, across **every repo the user works in** (ask if unsure — for a PostHog eng lead that's `PostHog/posthog` and `PostHog/code`):

- **The user's own open PRs** — both ready and draft
- **PRs where the user is a requested reviewer** — what's blocking on them
- **Teammates' open PRs** — drafts + ready, for each known teammate

After pulling, **triage with the user** using AskUserQuestion. Show a compact list — title, draft/ready state, age, link — and ask:

- **Priority** for each ready PR: critical / normal / can-wait. This feeds directly into the calendar plan.
- **Stale items to close**: any draft over ~4 weeks old or ready PR over ~2 weeks with no activity. The user explicitly wants their queue clean — drafts that won't ship are noise, and asking "want to close this?" gives them an easy out without nagging.
- For teammates' queues: are they working on the right things? Anyone with too many plates spinning, or plates they shouldn't have right now? This is the team-lead awareness pass — the goal isn't to micromanage, it's to spot anyone over-committed or off-mission before the week deepens.

#### Known teammates to triage by default

These GitHub usernames should be included in the teammate queue check unless the user says otherwise:

- `sortafreel` (note the spelling — not "sortrafreel")
- `andrewm4894` — this is "Andy Maguire"; if the user refers to "Andy", it's this handle
- `oliverb123` — Oliver Browne

Add others as the user mentions them; remove anyone the user says is no longer relevant.

#### What counts as "ready"

Treat a PR as **fully ready for review only when it is (a) not a draft AND (b) has at least one requested reviewer.** A non-draft PR with no reviewer isn't actually waiting on anyone — it's an oversight (the author forgot to request review), so flag it as "needs a reviewer assigned" rather than counting it as review-ready. Drafts are never review-ready regardless of reviewers. The search API doesn't return requested-reviewers in its results, so to apply this rule precisely you need either a GitHub MCP or a per-PR fetch — note the limitation rather than silently assuming.

#### Output of this step

A refined PR list with explicit priorities — feeds directly into the calendar-block sizing in later steps. And a separate "team lead followups" list — things the user should bring up in a 1-on-1 or sync, not things to put on their own calendar.

### 3. Look at the calendar before proposing anything

Call `list_events` (or whatever the connector's equivalent is) on the relevant window — today through the user's stated end-of-availability. Note:

- Hard commitments (meetings they accepted, ones they're organizer of)
- Soft commitments (optional, tentative, declined) — flag these and offer to skip them
- All-day OOO / "meeting free" markers (often `transparency: transparent`) — these are signals, not blockers
- The user's typical working hours and timezone (infer from the calendar's timezone field if not stated)

This step matters because proposing a plan that conflicts with their existing calendar wastes the whole interaction. Inventory first, propose second.

### 4. Compare time budget to task budget

Sum the task estimates. Compare to free time in the window. Be honest if it doesn't fit — say so up front and ask what to drop or push.

When budgets are close, mention the slack ("7 hours of focus time against ~6.5–7 hours of work — tight but fits"). The user wants to feel in control, not surprised later.

### 5. Order the blocks with energy and dependencies in mind

A few rules of thumb that work well:

- **Deep, high-impact work in the morning.** RFCs, writing, design — anything where focus matters most. The user's freshest hours go to the work that benefits most from focus.
- **Reviews and analysis in the post-deep-work slot.** They need attention but not invention. Often good for late morning / early afternoon.
- **Light operational tasks (inbox, notifications check, quick DB query, dashboard review) at end of day** when energy dips but the tasks don't demand it.
- **Unblock teammates before their day ends, when possible.** If reviewing PR #1 today unblocks someone overnight, that's worth more than reviewing it tomorrow.
- **Leave a small buffer** between deep work and reviews (15–30 min) — context switch tax is real.

These are defaults, not commandments. If the user signals different preferences, follow the user.

### 6. Propose, don't impose

**On the first iteration, always offer a few distinct *takes* on the plan — not a single schedule.** The same task list can be sequenced by different philosophies, and which one is right depends on what the user is optimizing for that week — something they often only realize when they see the options side by side. Offer 2–3 named strategies with genuinely different priorities, for example:

- **Unblock-others-first** — front-load reviews so teammates aren't waiting, deep work second.
- **Deep-work-first** — protect a big uninterrupted block for the highest-impact item, fit everything else around it.
- **Clean-the-decks** — attack the user's own WIP sprawl / stale pile first (good when they describe themselves as a bottleneck), reviews and deep work balanced after.

For each, give the rough shape (which day gets what) and the **tradeoff in one line** — what it's good for and what it sacrifices. Keep them comparable: same fixed meetings, same total work, different ordering. Let the user pick a philosophy *before* you build out exact times — then produce the detailed schedule as a table and follow the confirmation rule below. Don't skip straight to one fully-detailed plan on the first pass; you'll usually guess the wrong philosophy and waste the iteration.

**Always show a table of proposed calendar changes before writing them, no exceptions.** This applies to:

- The initial day/week plan
- Any follow-up edit, even small ones (color tweaks, time shifts, renames, single-event moves, lunch adjustments, downstream cascades from another change)
- Bulk operations across multiple events

The format is a markdown table with columns for **When**, **Block**, and (when relevant) **Change** — show old → new for edits so the diff is unambiguous. Then wait for explicit confirmation before calling any create / update / delete event tool. Don't bundle the table into the same message that already invokes the calendar tools.

The reason this matters: the user's calendar is a shared, persistent surface. Surprise mutations — even well-intentioned ones — erode trust and make it hard to audit what changed. A table preview takes 10 seconds to write and gives them a clean "yes" / "swap this" / "no" before anything ships. Don't optimize for speed by skipping this step.

After the table, ask for input on the choices that genuinely vary by person — don't ask everything in one wall of questions. Common things worth confirming:

- **Optional meetings during focus windows:** skip, attend, or split the block?
- **Overflow tasks:** push to next available day, or squeeze in by dropping something else?
- **Visibility:** private (busy, no title) vs. default (title visible to coworkers)? Team leads often want private for sensitive review topics or RFC names.
- **Show as Busy vs. Free:** worth asking. Some people want focus blocks to look busy to discourage scheduling; others want to stay bookable.

Use the AskUserQuestion tool for these — short, multi-option, one round.

### 7. Create the events

Only after the user confirms the plan. Notes that matter:

- **Use real newlines in descriptions, not HTML entities.** `\n` in the JSON string becomes a real line break. Writing `&#10;` literally stores the entity text and renders as gibberish. (Yes, the field accepts HTML — `<br>` works too — but plain `\n` is simpler and renders cleanly.)
- **Color-code by work type, consistently.**
  - **Deep work** (RFCs, writing, design — anything where focus is the whole point): **Tomato**, `colorId: "11"`. This is the high-priority visual anchor of the day.
  - **Every other focus block** (reviews, analysis, ops, inbox checks, DB queries): **Tangerine**, `colorId: "6"`. Distinct from the calendar default so blocks read as intentional time, not generic meetings, but visibly secondary to the Tomato deep-work block.
  - Don't introduce more colors than this. The point of color is fast at-a-glance distinction; a rainbow defeats it.
- **Use clear, scannable titles.** `Focus: <thing>` for deep work, `Review: <thing>` for reviews. The user will see these in their calendar app and should know immediately what each block is for.
- **Set visibility to `private` when the user asks** — but check whether the connector exposes the *transparency* field (free vs. busy). Many calendar MCPs expose `visibility` but not `transparency`. If you can't set it via the API, tell the user honestly and explain how to flip it manually rather than pretending it worked.

### 8. Close the loop with what's outstanding

End by surfacing:

- Anything you couldn't do via the connector (e.g., free/busy toggle, missing GitHub MCP for pulling actual PR list)
- Anything that got pushed to a later day
- Anything you assumed they'd want help with later (e.g., "your first focus block starts in 0 minutes — want me to help with the SQL when you're in it?")

This is the team-lead-overwhelm version of "did I miss anything?" — make the leftover surface area visible so the user can decide what to do about it.

## Things that have gone wrong before

- **HTML-entity newlines in descriptions.** Use real `\n`. Verify by reading back one event after creation if you're unsure the connector handled it right.
- **Setting events to "busy" when the user wanted "free".** If the connector doesn't expose `transparency` (or whatever the field is called), do not silently leave them as busy and claim success. Tell the user, give them the manual fix in one sentence.
- **Over-questioning.** If the user gave you a detailed task list with priorities and estimates, you don't need to ask "what's important to you?" — they told you. Save questions for the genuine forks (optional meetings, visibility, overflow).
- **Treating "I usually work 9am to 6pm" too literally.** It's a soft signal. If the user has a 7:30 PM personal event the same day, don't schedule past it. If they're OOO from 2 PM tomorrow, the morning block ends at 2 PM, not 6 PM.
- **Forgetting carryover.** If not all the work fits, explicitly note what's deferred and to when. The user came here precisely because they're overloaded — closing the loop with "this will be Monday morning" beats leaving them to figure out where PR #4 went.

## What you don't need to do

- Don't write a script. The work is shaped by the user's specific tasks and connector, and the value is in the workflow, not the automation.
- Don't try to be clever about meeting times you can move. The user didn't ask for that. Stay in the lane of blocking *their own* time.
- Don't add scheduled tasks or artifacts unless the user asks. This is a one-shot planning workflow, not a recurring system.

## User's recurring commitments

These are the user's known recurring weekly anchors. Treat them as fixed — never schedule focus blocks over them. They may already appear on the calendar as recurring events, but list them here as a backup so the plan stays correct even if the query window misses them.

- **Mon / Wed / Fri morning** — team sync
- **Mondays, 5:30 PM** — company all-hands
- **Tuesdays, 10:00 PM** — gym (1 hour). Block 9:45 PM–11:15 PM total to account for 15 min buffer on each side.
- **Fridays, 5:00 PM** — gym (1 hour). Block 4:45 PM–6:15 PM total to account for 15 min buffer on each side. *(Confirm with user — original input was "first days" which is most likely Fridays via voice transcription.)*
- **Lunch — every day, 45 minutes.** Mon–Thu: usually between 1:00 PM and 4:00 PM, exact time depends on what fits best around meetings and focus blocks. **Fridays: always 2:00 PM (2:00–2:45 PM).** Don't skip lunch in plans unless the user explicitly opts to ("pack it with work today"). If a half-day plan ends before 1:00 PM, lunch isn't needed.

When proposing a Mon / Wed / Fri morning plan, leave the team-sync slot blank and start blocks afterward. When proposing late-day work, end deep work at least 15 min before the gym buffer starts. When slotting lunch, prefer 1:00 PM or later unless the day's schedule forces it earlier — and on Fridays, anchor lunch at 2:00 PM and plan around it rather than fitting it in.

## When this skill is wrong for the task

- The user wants to schedule a *meeting with someone else* — that's a different shape (suggest_time, attendees, etc.).
- The user wants a recurring system ("plan my day every morning") — combine with the scheduling tool, but the planning workflow itself stays the same.
- The user just wants a to-do list, not calendar blocks — drop the calendar tools, keep the prioritization logic.
