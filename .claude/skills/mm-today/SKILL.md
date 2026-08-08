---
name: mm-today
description: "Michael's daily work triage. Answers one question: if I were planning the whole day right now, what would be top of mind? Sweeps his open PRs, his review queue, #team-self-driving, and the promises he's made across Slack, then ranks them by whose court the ball is in. Biased toward reducing work in progress — landing stalled work beats starting new work — and grounds impact claims in real PostHog usage data rather than intuition. Specialises in getting shot-off drafts over the line: the real solutions sitting invisible because nobody was asked to review them. Gathers read-only and never posts, merges, or replies without a per-item yes. Use when asked what to work on, for a daily triage or standup, to go through the PR backlog or review queue, or to check what he's promised and not delivered."
---

# mm-today

The one question: **if I were planning the whole day right now, what would be top of mind?**

Not "what fits in the next 90 minutes." It doesn't matter whether he's running this at 8am or 4pm — the answer is always the full-day plan viewed from now. Never ask how much time he has, never mention the time of day, and never size the plan to a remaining-hours estimate. If he explicitly says "I've only got an hour," honour that; otherwise plan the day.

**The tiebreaker, whenever ranking is close: what reaches users and customers soonest.** A merged fix in a customer's hands beats a perfect refactor sitting in review.

**Hard rules.** Gathering is read-only. Never post a Slack message, never comment on or approve a PR, never merge, never mark ready for review, never close anything, and never push, until Michael says yes to that specific item. "Yes, merge #890" is permission to merge #890 and nothing else.

**Scope: the PostHog org only.** `org:PostHog` on every query.

## 1. Gather

Read `~/.claude/mm-today-state.json` first — briefly, just to know what's already been dismissed or settled. The full treatment is in step 9; don't dwell on it here.

Then four sweeps, **fired in parallel**, because the Slack searches dominate wall-clock:

```bash
D=~/.claude/skills/mm-today/references
$D/fetch-prs.sh 'is:pr is:open org:PostHog author:Twixes'            # his PRs (~28)
$D/fetch-prs.sh 'is:pr is:open org:PostHog review-requested:Twixes'  # his queue (~78)
```

Plus `#team-self-driving` (`C09SK2PAGKF`, last 2–3 days) and a promise sweep over the last 14 days.

**Also check what he's already in the middle of** — current branch, uncommitted changes, and the last few commits in whichever repo he's running from. It's cheap (`git status`, `git log --oneline -5`, `git branch --show-current`) and it changes the plan: an item that's a five-minute finish *because he's already in that repo with that branch checked out* ranks far above an identical item that costs a context switch. Say when something lines up with where he already is.

`fetch-prs.sh` paginates and returns `{prs, issueCount, fetched, truncated}`. **If `truncated` is true, say so in the report** — a silently short queue makes the whole run wrong. [references/queries.md](references/queries.md) has the Slack queries and every gotcha worth knowing.

## 2. Work out whose court the ball is in

**This is the core of the skill.** Everything else is presentation.

Michael's failure mode isn't writing code — it's that a PR solving a real problem stalls somewhere between "draft pushed" and "merged," and nothing moves it because the next action is his and nobody else can take it. Measured on a real run: **26 of his 28 open PRs had the ball in his court. Only 2 were genuinely awaiting review.**

So classify every one of his PRs by *what the next action is and who owns it*:

| State | Signal | Next action |
|---|---|---|
| **Draft, never raised** | `isDraft`, CI green | Mark ready + request reviewers. Nobody can even see it. |
| **Open but invisible** | `reviewRequests.totalCount == 0`, `reviewDecision: null` | Request a reviewer. It's open and nobody was asked. |
| **Comments waiting on him** | unresolved threads > 0 | Answer or resolve them. |
| **Conflicts** | `mergeStateStatus: DIRTY` | Rebase. |
| **Behind** | `mergeStateStatus: BEHIND` | One "update branch" click. |
| **Red CI** | rollup `FAILURE` — *verify it's real* | Fix it. |
| **Ready to merge** | `APPROVED` + green + 0 unresolved + `CLEAN` | Merge. |
| **Genuinely waiting on others** | requested, green, no unresolved | Nothing. Leave it alone. |

Only that last row is out of his hands. Everything above it is a thing he can move today.

### Order by distance to done, not by age

This is what makes the bucket actionable. Two PRs in the same state can be thirty seconds apart or three hours apart:

- **Seconds** — request a reviewer on a green, clean PR. Click "update branch" on a `BEHIND` one. Merge an approved one.
- **Minutes** — mark a green draft ready. Resolve one or two comments. Fix a lint failure.
- **~30 min** — rebase a conflicted PR. Fix real test failures.
- **Hours** — twelve unresolved comments on a 1500-line PR. Conflicts on a 3600-line one.

**The single highest-leverage item in this whole skill is a finished, green PR that nobody has been asked to review.** It costs one click and converts stalled work into work someone else is now moving. Always surface these first, by name, however unglamorous they look.

### Stalling is a state, not an age

Do **not** use a 14-day threshold to decide what's stalled. On a real run the median idle time was 4 days and 20 of 28 PRs were under two weeks — an age-based rule would have missed almost everything that mattered. A PR that's been invisible for three days is already stalled.

Age is a modifier, not the signal. Use it to say how long something has been stuck and how much a rebase will now cost, and to flag genuinely abandoned work. **Flag old PRs as rotting with their revival cost; never suggest closing one.** That call is his.

## 3. Read the room

The PR list alone will mislead you — a tiny PR three people are waiting on outranks a big one nobody has asked about.

From `#team-self-driving`, extract **only what changes a priority**: someone blocked on Michael, work colliding with one of his open PRs, an unanswered question to him, and what the team is pushing this week. Skip standup noise and deploy chatter.

**Unanswered mentions** across all channels are the highest-yield dropped-ball signal in the run.

## 4. Find the promises, and be strict

Most of these never become a GitHub artifact, so nothing else here will catch them.

**A promise is:** first person, future action, a specific deliverable, and an audience who'd notice if it didn't happen. **A promise is not:** a joke ("I'll need to practice my Abba"), a hypothetical, a statement about the past, or something he said *someone else* would do.

Cast a wide net across phrasings, then filter hard — recall at the search step, judgment after. Expect to discard most hits.

**Then check whether each is already discharged.** A promise followed by a PR or a delivering message is *done* and must not be reported as outstanding.

Worked example: Aug 3, *"Hmm I'll see what I can do do have wizard support Replay Vision scanners"* → `wizard#1055` and `context-mill#313` opened the next day. That's **in flight**. And the real finding is sharper than the promise: `context-mill#313` was sitting green and clean with **no reviewer requested** — a customer commitment, invisible, one click from moving. That intersection of promise and stall is the most valuable thing this skill produces.

Sort into **outstanding** (nothing started), **in flight** (link the PR, and check whether *it* is stalled), or **discharged** (drop silently).

**Then drop anything nobody is waiting on, silently too.** A promise only earns a line if a named person is blocked on it or plainly expecting it. Something he mused about doing, that the audience moved on from, is not a dropped ball — reporting it as one is noise dressed up as diligence. Don't report it as a non-finding either ("loose thread, not a promise"); just cut it.

## 5. Bucket the review queue

His own PRs are handled by step 2. For the queue:

| Bucket | Detection |
|---|---|
| **Stamp now** | Small, green, no risky paths, he hasn't reviewed it yet |
| **Deep review** | Risky **file paths** — migrations, models, auth, billing, serializers, schema, infra |
| **Back in his court** | He reviewed it, the author has pushed since |
| **Someone else has it** | `reviewRequests.totalCount > 1` — lower priority; he isn't the only one who can |

**Judge risk from file paths, never from titles.** On a real run, 26 of 78 queue PRs touched risky paths, and titles hid most of them — `chore(hogai): return frozen dataclasses instead of tuples` touches auth, billing, and serializers. Conversely, **48 of 78 had him as the sole reviewer**: those genuinely cannot proceed without him, and that outranks almost everything else in the queue.

Budget one, maybe two deep reviews per day. They can't be batched.

**Account for the whole queue.** Eighty-odd PRs go in and a dozen come out — the other seventy must not vanish silently, or he can't tell whether the skill triaged them or just lost them. Close the tail with one line: how many weren't surfaced and why, bucketed (other reviewers assigned, draft, author inactive, already approved by someone else). A silent drop reads as "covered everything" when it isn't, and that's the failure mode that quietly erodes trust in the whole report.

## 6. Rank

**Impact**, highest first:

1. **Unblocks a person who is waiting** — a teammate, a customer, a promise with a name on it. Being sole reviewer counts.
2. **Reaches users or customers** — shipped behaviour, a bug fix on a path people hit.
3. **Unblocks his own downstream work.**
4. **Internal quality.**
5. **Speculative** — drafts nobody is waiting on.

Order by impact, then cheapest-first within a tier. Three overrides:

- **Anything that unblocks a person goes first**, even if it's low impact otherwise.
- **Sub-five-minute items get cleared first regardless of tier.** Requesting a reviewer, merging a green PR, answering a two-day-old question. These buy focus for the expensive work.
- **Finishing beats starting.** See below — this is the one that most often changes the plan.

### Reducing work in progress is a goal, not a side effect

**Michael cares about this a lot, and the skill should be openly biased toward it.** Twenty-eight open PRs is not twenty-eight units of progress — it's twenty-eight things accruing rebase cost, splitting his attention, and going stale. Every one of them is work already paid for that hasn't been collected.

So, concretely:

- **Landing something beats advancing something.** A PR that gets to merged today is worth more than two that each move halfway. When ranking is close, pick the one that *ends*.
- **Put the WIP count in the header and let it be uncomfortable.** If it went up since the last run, say so. If it went down, say that too — that's the win condition.
- **Prefer the finishing move over the interesting one.** The plan should rarely suggest opening new work while this many things are half-done. If something genuinely new needs to start, say plainly what it's displacing.
- **A day that closes four PRs and starts none is an excellent day.** Say so when it happens.

**Rotting work is under-served by a single tail line.** For anything stalled long enough to have gone cold, work out which of these it is and say which:

- **Worth picking back up** — the problem is still real and someone would benefit. Give the revival cost honestly (a rebase is 20 minutes; a 6000-line PR with cascading CI failures is a day, not an hour) and what it'd take to make it land.
- **Superseded** — someone else shipped it, or the surrounding code moved on. Say what replaced it.
- **Nobody's waiting** — no reviewer ever requested, no customer, no teammate. State that plainly, with the age.

**Give him the facts, not the verdict.** Don't tell him to close things. Age, revival cost, and who's waiting are enough for him to make the call himself in about two seconds — and that's his call to make.

**Look for overlap, in both directions.** The cheapest way to reduce WIP isn't finishing faster, it's noticing that two things are the same thing:

- **His own PRs that overlap each other.** Several PRs circling one feature can often land as one, or stack in a deliberate order instead of competing. Say so when you see it — same product area, same files, same problem stated twice.
- **His work overlapping a teammate's.** If someone in `#team-self-driving` is building something his open PR already does, that's worth knowing *today*, before either of them builds more. This is the single most expensive thing to discover late.
- **A queue PR that supersedes one of his.** If someone else shipped it, his can close and that's WIP down for free.

### Ground the impact claim in PostHog data

**This matters and it's the difference between a real ranking and a plausible-sounding one.** Name *who* is waiting, *which* customer asked, *what* breaks. If you can't name the beneficiary, it isn't top-tier — rank it lower and say why.

**Where the claim is about user reach, use PostHog itself rather than reasoning harder.** He works at PostHog, on PostHog, and the data is right there — an impact claim made without checking it is a guess dressed up as analysis.

**This is a floor, not a nice-to-have.** Earlier versions of this skill phrased it as "reach for it when the call is close," and in practice that read as permission to skip it entirely — two full runs went by without a single query. So:

> **At least two items in the plan must carry a real number from PostHog, or the report must say explicitly why none could.** "I didn't query anything" is not an acceptable silent outcome.

Pick the two where a number would actually change the order — usually the ones you're about to rank top-tier on intuition alone. Good angles:

- **Does anyone actually use the surface this touches?** Event volume on the path, over a sensible window.
- **Is the bug it fixes actually firing?** Error tracking — issue volume and people affected beats any argument from reading the diff.
- **How exposed is it?** Feature flag rollout and exposure counts.
- **Who does it affect?** Paid plans or free, one customer or everyone.

The `posthog` MCP tools and the `querying-posthog-data`, `investigating-error-issue`, and `inbox-exploration` skills are the way in. Keep each query cheap and targeted — this is two or three queries, not an analytics project. Put the number in the finding *with a link to it*: "this path gets 40 events a week across 3 orgs" settles an argument that no amount of reasoning about the code would.

A number that *deflates* an item is just as valuable as one that promotes it — finding that a "high impact" fix touches a path nobody hits saves him half a day. Report those; they're often the most useful line in the whole run.

When a query genuinely can't be run, say which one and why, and rank conservatively. "I couldn't measure who hits this, so I'm not calling it top-tier" is honest and useful.

Don't pad. If four things genuinely matter today, the plan has four things.

## 7. Report

Terminal only. Plan first; the tail is for skimming.

**Bold the things he scans for** — every item title, every section header, the WIP
count, and the key noun in a tail line. He reads this fast and in a terminal;
bolding is what makes it navigable rather than a wall. Don't bold whole
sentences, which defeats the point — bold the handful of words he'd search for.

```
**TODAY** — <date>
**<n> open · <n> in queue · <n> with the ball in your court** · WIP <n> <(up|down) n since <date>>

## **OVER THE LINE** — finished work that's stalled, do these first

**1. <what to do>** · <how long, honestly>
   <Why it matters: who's waiting / what ships. Name the beneficiary.>
   [<repo#number>](<pr url>)

## **THE DAY**

**2. <same shape>**

## **PROMISES**
- **Outstanding:** <what he said, who's waiting, how old> · [said here](<slack permalink>)
- **In flight:** <what he said> → [<repo#num>](<url>) <and whether that PR is itself stalled>

## **FROM #team-self-driving**
- <only what changes a priority> · [thread](<slack permalink>)

---- the tail, skim it ----

**STAMP NOW**       [<repo#num>](<url>) · +x-y · author · what it is
**DEEP REVIEW**     one line each, the honest time cost, and why it's risky
**WAITING ON ME**   one line each: the next action and how long it takes
**WAITING ON OTHERS** one line each, so he knows it's genuinely not his problem

**ROTTING** — <n> PRs, <total> lines of work already paid for
  **Worth picking up:** [<repo#num>](<url>) · <age> · <revival cost> · <what it'd take to land>
  **Superseded:**      [<repo#num>](<url>) · <age> · <what replaced it>
  **Nobody waiting:**  [<repo#num>](<url>) · <age> · <no reviewer ever requested>

**THE REST OF THE QUEUE** — <n> not surfaced: <n> have other reviewers, <n> draft, <n> <reason>
```

Every `<repo#num>` above is shorthand for a **linked** one. The template writes
them out long-form once; do it everywhere.

Drop empty sections. One line per tail item. Split `ROTTING` into those three
groups only when there's something in more than one — otherwise a flat list is
fine.

### Always link. Everything, every time

**Every artifact you name gets a link, no exceptions.** This report is a jumping-off
point — its job is to get him from "that one matters" to the actual thing in one
click, wherever it lives. A bare `posthog#76967` makes him go find it, and that
friction is the whole reason a backlog stays a backlog.

- **PRs and issues** — `url` is already in the GraphQL response. Use it:
  `[posthog#76967](https://github.com/PostHog/posthog/pull/76967)`.
- **Slack messages, threads, and promises** — the search results carry
  `Permalink`. Link the exact message, not the channel.
- **Anything else you cite** — a CI run, a failing job, an error-tracking issue, a
  PostHog insight, a dashboard, an RFC, a doc. If you looked at it to form the
  claim, he should be able to look at it too.
- **A quoted promise links to where he said it.** Quoting Slack without a
  permalink makes him search for his own words.
- **Even in the tail.** Especially in the tail — that's the part he skims for
  something to click.

The only thing that doesn't need a link is a claim about the data as a whole
("nothing was truncated"). If you're unsure whether something warrants one, link
it.

### Write it like you're explaining it to a bright colleague over coffee

That's the benchmark — not "plain English," which sets the bar too low and reads
like a form. Someone sharp is sitting across from you, hasn't looked at any of
this yet, and wants to know what's worth doing today. Talk to them like that.

- **Say the thing, then anchor it.** The prose should land on its own; keep
  `repo#number` on its own line underneath. If he reads only the first line of
  each item, he should already know whether he cares.
- **Short sentences. Contractions are fine.** "It's been invisible for three
  days" beats "this pull request has remained without an assigned reviewer".
- **No throat-clearing.** Skip "it's worth noting that", "one thing to consider",
  "interestingly".
- **Name the consequence in human terms.** "Andrew's blocked until this lands"
  lands. "High impact" doesn't. "Nobody has been asked to look at it" beats
  "reviewRequests is zero".
- **Don't restate PR titles.** He wrote them. Say why they matter instead.
- **No hedge padding.** Either you checked it or you didn't — and if you didn't,
  say so plainly at the end rather than sprinkling "potentially" through the
  report to look careful.

## 8. Offer to act — per item, never in bulk

Offer as a short numbered list he can answer with numbers. Don't re-explain the PRs; he just read the report.

- **Request reviewers / mark ready** — the cheapest, highest-leverage moves. Suggest who, based on who's active in that area.
- **Merge** — only `APPROVED` + green + `CLEAN`. If `BEHIND`, offer to update the branch first. Never merge `DIRTY`.
- **Rebase** — for `DIRTY` and `BEHIND`.
- **Draft a Slack reply** — for an outstanding promise or unanswered mention. Show the text; send only on approval.
- **Run [mm-review](../mm-review/SKILL.md)** — on a stamp or deep-review candidate. It's read-only and never posts, so he still stamps.

## 9. Write state back — and keep it small

The state file exists so a daily skill doesn't re-nag him with the same five things every day. But a file that grows unbounded across months quietly eats the context window and defeats itself. **Keeping it small is a feature of this skill, not housekeeping.**

Three tiers, only one of which is ever read in full:

- **Principles** — durable, distilled learnings about how to rank *his* work. Always loaded. Hard cap ~20 lines. This is the part that's supposed to survive months.
- **Suppressions** — "stop showing me that," with an expiry. Loaded as bare keys, matched against today's items; the notes are read only on a hit.
- **Discharged** — promises confirmed delivered. Keys only, pruned aggressively.

**Distil rather than append.** When the same correction shows up three times, collapse it into one principle and delete the raw entries. A principle earns its place by changing a ranking decision; if it never fires, drop it. The test at the end of every run: *would this file still be readable in six months?*

Only ever write a suppression when he says so — never off your own judgment.

Corrections are the only part that compounds. When he pushes back on a ranking, that's the whole reason tomorrow's run is better than today's. See [references/state.md](references/state.md) for the schema and the compaction rules.
