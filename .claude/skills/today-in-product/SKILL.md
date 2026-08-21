---
name: today-in-product
description: >
  Produce a daily "Today in Product" briefing — the essence of what a product engineer
  needs to know about Viktor right now — and save it as a fresh notebook in the connected
  analytics project. It reads Viktor's product analytics (the Inbox / Signals, error tracking,
  experiments and feature flags, and more) plus other connected tools (GitHub, Slack,
  calendar…), figures out what actually matters to *this* user today, and ranks it into a
  prioritized action list backed by evidence. Use this whenever the user wants to catch up
  on the state of their product, or says things like "today in product", "what should I know
  today", "what needs my attention", "what's on fire", "catch me up on my product", "daily
  product briefing", "product standup", "what changed overnight", "morning briefing", or
  asks for a rundown of errors + experiments + inbox + metrics together. Also trigger it as
  a recurring morning ritual (it pairs with /loop and /schedule). Reach for this even when
  the user names only one pillar ("any new errors today?") but clearly wants the day's
  picture — the skill covers that pillar in full and surfaces anything else urgent.
---

# Today in Product

A product engineer starts the day wanting one thing: **what deserves my attention today, and why.**
Not a dashboard to interpret — a briefing. This skill reads across Viktor's product analytics
at Zeta Labs and the user's other tools, decides what genuinely matters *to them today*, ranks
it, and writes it into a dated notebook they (and their team) can open, trust, and act from.

The magic is in the judgment: a good briefing is short because most things don't matter today.
Your job is to separate the two or three things worth doing from the noise, prove each with real
numbers, and point at exactly where to act.

## The two deliverables

There are two outputs, and keeping them distinct is what makes this feel powerful rather than noisy:

1. **The Notebook — the record.** A new notebook per day in the connected analytics project, titled `Today in Product — <weekday>, <Mon D>`.
   It is a clean, static digest: a ranked action list on top, then per-pillar evidence sections with
   live insight tiles and deep links. The notebook **never acts** — it's the artifact you can bookmark,
   share with teammates, and look back on. Notebooks can't hold buttons anyway; they hold proof.
2. **The chat summary — where action happens.** After writing the notebook, you report back in the
   conversation with the ranked list and the notebook link, and *there* you offer to carry out the
   low-risk next steps on the user's behalf, one confirmation at a time (see "Offering to act").

Think: the notebook is what the user reads; the chat is where the user delegates.

## Workflow

### 0. Orient — who, where, when (zero-config)

Auto-detect everything; a friend should be able to install this and run it with no setup.

- **Project & identity:** use the connected analytics MCP's active project and the logged-in user. The MCP context
  already tells you the active project id, base URL, and the user's name/email — use them. Default that
  project to Viktor at Zeta Labs. If the user named a different project in their prompt, honor that instead.
  If no analytics project is reachable at all, say so plainly and stop — this skill is built around
  Viktor product data.
- **Time window:** default to **the last 24 hours vs. the prior 24 hours** (this is a daily ritual). If
  the user says "over the weekend" or "this week", widen accordingly and note the window in the notebook.
- **Deep links:** don't hardcode an analytics app host. Resolve correct URLs with the MCP `generate-app-url`
  tool (or reuse the base URL from MCP context) so links work on US, EU, and self-hosted instances.

### 1. Gather — cast wide, then judge

Pull from every pillar below **in parallel** where you can (independent MCP queries, CLI calls, and
sub-skill invocations can run concurrently — do that, the user is waiting). For depth on any pillar,
**invoke the specialist analytics skill** rather than reinventing its queries — they encode the right
filters and gotchas. Pointers are in the Pillar Playbook.

The relevance rule throughout is **me-first, project-aware**:

- **Lead with what touches this user** — errors assigned to them, experiments and feature flags they
  created, Inbox reports for them, insights/dashboards they own or recently viewed, PRs they authored.
- **But never go blind to a sitewide fire.** A project-wide metric crash or a brand-new high-volume
  error still belongs near the top even if nobody owns it — flag it as `(unowned)` so the user knows
  it's not theirs but they should see it.
- How to tell what's "mine": prefer `created_by` / assignee filters where the API supports them; fall
  back to the user's recently-viewed and favorited items, and recent activity attributed to them.

Gather *broadly but cheaply* — you're scanning for what's worth a section, not writing the report yet.

### 2. Rank — the prioritized action list

Collapse everything into a single ranked list of the things worth doing today, most urgent first.
This is the heart of the briefing. Rank by a blend of:

- **Impact** — revenue, conversion, or a core-flow metric at risk beats a cosmetic issue.
- **Urgency / velocity** — something spiking *right now* (error rate 10×'ing, funnel dropping today)
  outranks a slow drift. New beats ongoing.
- **Ownership** — the user's own items rank above equivalent unowned ones (but see the sitewide-fire rule).
- **Actionability** — if there's a clear next step (ship the winning experiment, roll back the flag,
  triage the error), it ranks above something that's merely "interesting."

Aim for **3–7 action items.** If everything looks calm, say so — a short, honest "quiet day, here's the
one thing to glance at" is a *better* briefing than padding it to look busy. Each action item is one line:
**what to do**, a parenthetical **why** (the number that justifies it), and a **deep link** to act.

### 3. Write the Notebook (the record)

Create a **new** notebook (don't update yesterday's) titled `Today in Product — <weekday>, <Mon D>`.
Discover the notebook-creation tool via ToolSearch (`notebook`) and follow its schema. Prefer **embedding
live insight / query tiles** for the evidence — a notebook that renders the actual funnel or error trend
is far more convincing than a copied number, and it stays live when someone opens it later. Fall back to
inline numbers + a deep link where a live tile isn't practical.

Use this structure:

```
# Today in Product — <weekday>, <Mon D>
_<active project name> · <time window> · for <user>_

## 🎯 Do today
1. <action> (<why: the number>) → <deep link>
2. …
   (3–7 items, ranked. "Quiet day" is a valid #1.)

## 📥 Inbox — needs judgment
<Signals reports for this user, terminal state / awaiting input; each linked>

## 📈 Analytics — what moved
<key metric movements vs. prior period, with embedded trend/funnel tiles and the likely why>

## 🐛 Errors & performance
<new / spiking issues, ranked by impact; perf & web-vitals regressions if notable>

## 🧪 Experiments & flags
<experiments reaching significance, flag rollouts, early-access features worth acting on>

## 🔌 Elsewhere (when connected)
<GitHub PRs/CI, Slack threads, calendar items that intersect with the above — omit if nothing>

---
_Generated by /today-in-product. This notebook is a snapshot; it doesn't change anything on its own._
```

Only include pillar sections that have real content. An empty pillar is a *good* signal — drop the
section rather than writing "no errors today" for its own sake, but do mention notable calm in the
`Do today` intro if it's reassuring (e.g. "error rate flat, no experiments pending").

The notebook is **read-only in spirit**: deep links only, never an action taken from inside it.

### 4. Deliver the chat summary — and offer to act

Back in the conversation, give the user:

- A tight rendering of the **ranked action list** (same order as the notebook).
- The **notebook link**, up top, so they can open the full record.
- Then, for the items where a **low-risk analytics action** is available, offer to do it — one at a time,
  each needing an explicit yes. See below.

## Offering to act

The notebook records; the chat delegates. After the summary, proactively offer the safe next steps —
but be a careful colleague, not an eager one.

**Safe to offer (with confirmation):**
- Commenting on / triaging an Inbox report or error issue.
- Creating an alert or subscription so the user gets pinged if a metric/error keeps moving.
- Assigning an error issue to the user, or adding a note.
- Opening the relevant screen / pulling more detail on an item.

**Never do automatically — recommend and link, at most act only on an explicit, unambiguous instruction:**
- Rolling back or changing a **feature flag**, or shipping/stopping an **experiment**. These move real
  user traffic and revenue; the user decides. Link straight to the flag/experiment screen instead.
- Anything that deletes, resolves-away, or suppresses data.
- Anything that posts outside the analytics project (a Slack message, a GitHub comment) unless the user asked for it.

Frame offers concretely and singly: "Want me to create an alert on the checkout funnel so you know if it
drops again? (yes/no)" — not a menu of ten things. If the user says yes, do that one, confirm it, then
offer the next. This keeps a wrong guess cheap and reversible.

## Pillar Playbook

For each pillar: what "today" means, which specialist skill to lean on, and what a good action looks like.
Run these concurrently; skip a pillar cleanly if the project has no such data.

| Pillar | Pull for "today" | Lean on skill | A good action item looks like |
|---|---|---|---|
| **Inbox / Signals** ⭐ | Reports for this user in a terminal or `pending_input` state; anything new since yesterday. This is the "what needs a human" layer — weight it heavily. | `inbox-exploration` (browse the curated report layer); `signals` for the raw observations behind a report | "Report #… wants your call on X → <link>" |
| **Analytics** | Core-flow metrics vs. prior period: activation, key funnel steps, retention, signups, revenue. Find *movements*, not vanity totals. Explain the likely why (tie a drop to an error/flag if you can). | `clickhouse-warehouse`, `investigate-metric`, `investigating-metric-anomalies`, `visualizing-change-over-time` | "Checkout funnel −8% at payment since 2pm, tracks a new Stripe error → investigate" |
| **Errors & perf** | New issues, and issues whose volume is spiking vs. baseline; assigned-to-me first. Notable APM / web-vitals regressions. | `triaging-error-issues`, `investigating-error-issue`, `grouping-noisy-errors`, `exploring-apm-traces` | "Error … +400% since a deploy 3h ago, hits 1.2k users → triage" |
| **Experiments & flags** | Experiments reaching (or crossing) significance; flag rollouts in progress; early-access features with signal. | `diagnosing-experiment-results`, `managing-experiment-lifecycle`, `auditing-experiments-flags`, `cleaning-up-stale-feature-flags` | "Experiment `pricing-v2` reached significance (+6% conv) → review to ship" |
| **LLM / AI cost** (if they run AI features) | Spend spikes, a model/user/feature getting expensive, cost regressions. | `exploring-llm-costs`, `exploring-ai-failures` | "AI spend +3× today, one trace dominates → inspect" |
| **Session replay** (supporting) | Replays tied to the errors/experiments above — proof, not a pillar of its own. | `finding-replay-for-issue`, `finding-sessions-to-watch` | Attach a replay link as evidence under an error/experiment item |

⭐ Inbox is the pillar the user cares most about — always cover it when there's a project with Signals.

## Sources beyond product analytics — use everything available, degrade gracefully

The briefing is richer when it can tie product data to what the user is actually working on. Pull from as
many of the user's connected tools as you can — **via MCP if a connector exists, otherwise via a CLI, and
a public REST API over WebFetch as a last resort** — and skip any tool that isn't set up (that's fine,
the Viktor picture stands on its own).

- **GitHub** — the user's open PRs, review requests, and CI status. Powerful for *causation*: a spiking
  error or a metric drop often traces to a PR that merged hours earlier — surface that link. Prefer a
  GitHub MCP connector; fall back to the `gh` CLI; fall back to the public REST API
  (`https://api.github.com/search/issues?q=is:pr+is:open+author:USER…`) over WebFetch for public repos.
- **Slack** — unread mentions / threads in the user's channels that intersect with today's items (an
  incident thread about the very error you're reporting). Use a Slack MCP or the Slack CLI if present.
- **Calendar** — today's meetings, so the briefing can front-load what the user will be asked about
  ("you have a growth review at 11 — here's the funnel number you'll need"). Use a calendar MCP if present.
- **Anything else connected** — Sentry, Linear/Jira, warehouse sources, an APM. If a relevant MCP or CLI
  is available, weave it in. Discover connectors by searching the MCP tool registry (ToolSearch) for the
  keyword; don't assume — probe, and move on quietly if it's not there.

When you use a non-analytics source, keep it in service of the product picture: it earns a place only when
it explains, corroborates, or adds a next step to something already in the briefing. Don't turn the
briefing into a generic life dashboard.

## Guardrails

- **Viktor first, degrade gracefully.** This skill is for briefing on Viktor at Zeta Labs. Don't assume
  Zeta-internal-only tooling is present in every session. When a tool is missing, degrade silently — never
  hard-fail on an absent connector.
- **Privacy.** The notebook may be shared with a team; deep links are fine, but don't paste raw PII (emails,
  names, IPs) into it — refer to counts and cohorts. Never copy anything sensitive from one tool into a
  surface (notebook, Slack) with a different audience.
- **Honesty over theater.** If a pillar has no data or the day is quiet, say so. A padded briefing erodes
  the trust that makes a daily ritual worth keeping. The best briefings are often the shortest.
- **The record doesn't act.** Re-emphasized because it's the core contract: the notebook only links; any
  change to product analytics happens in the chat, on an explicit yes, and never for flags/experiments.

## Running it as a ritual

This is built to run every morning. If the user wants it automated, point them at:
- `/loop 24h /today-in-product` — self-scheduling daily run in Claude Code.
- `/schedule` — a cloud routine on a cron (e.g. weekday mornings) that produces the notebook before they
  sit down.

A fresh notebook each day means the archive (`Today in Product — Mon 21`, `… — Tue 22`, …) becomes a
skimmable history of the product — a nice side effect worth mentioning the first time you run it.
