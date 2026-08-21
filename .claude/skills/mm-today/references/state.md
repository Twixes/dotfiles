# State

`~/.claude/mm-today-state.json` — deliberately **outside** the dotfiles repo,
since the skill directory is symlinked from git and daily churn shouldn't dirty
it.

Two jobs, and the second is the hard one:

1. Stop the skill re-nagging him with things he already dismissed.
2. **Stay small enough to still be worth loading in six months.** A daily file
   that only ever appends will, after a few months, cost more context than the
   triage it informs. Compaction is the design, not the cleanup.

## Schema

```json
{
  "lastRun": "2026-08-04",
  "wip": [
    {"date": "2026-08-04", "open": 28, "ballInCourt": 26, "merged": 0}
  ],
  "principles": [
    "RFCs rank below shipping code even when they have lots of comments",
    "Customer-facing PRs beat internal ones when a visit is imminent"
  ],
  "suppressions": {
    "https://github.com/zetalabs-ai/zeta/pull/12345": {
      "until": "2026-08-18", "note": "parked until billing revamp lands"
    },
    "https://zetalabs.slack.com/archives/C0000000000/p0000000000000000": {
      "until": "forever", "note": "not a promise, small talk"
    }
  },
  "discharged": ["https://zetalabs.slack.com/archives/C0000000000/p0000000000000000"],
  "pending": [
    {"date": "2026-08-04", "note": "said RFC ranking was too high"}
  ]
}
```

Keys are permalinks, so nothing collides.

## The three tiers, and what each costs to load

| Tier | Loaded | Cap |
|---|---|---|
| `principles` | **In full, every run.** These shape ranking. | ~20 lines, one line each |
| `suppressions` | Keys only. Read a `note` only when that key appears in today's data. | Auto-pruned on expiry |
| `discharged` | Keys only, never the context. | Prune older than ~90 days |
| `pending` | In full, but it should almost always be short. | Distil at 3+ related entries |
| `wip` | Last entry, plus the one ~7 days back for the trend. | Keep ~30 entries, then thin to weekly |

`wip` is what makes "reducing work in progress" measurable instead of a slogan.
One small row per run: open PR count, how many have the ball in his court, and
how many landed since the last run. The report header uses the delta — **the
number going down is the win condition**, and it can only be shown if it's
recorded. Thin old entries to one per week rather than deleting them; the
month-over-month shape is the interesting part and it costs almost nothing.

`pending` is the staging area for raw corrections that haven't earned a
principle yet. It is **not** a permanent log.

## Compaction rules

- **Distil, don't append.** When three related entries pile up in `pending`,
  collapse them into one line in `principles` and delete the raw three. The
  point of a correction is the rule it implies, not the incident.
- **Principles must earn their place.** A principle exists to change a ranking
  decision. If one hasn't fired in a couple of months, drop it — it was an
  observation, not a rule.
- **Prefer rewriting a principle to adding a neighbour.** Two principles about
  the same thing means neither is right yet.
- **Never let `principles` exceed ~20 lines.** At the cap, merge or drop before
  adding. A cap that is quietly exceeded is not a cap.
- **Prune on write, not on read.** Drop lapsed suppressions and stale
  discharged keys every time the file is written.

The test at the end of every run: *would this file still be readable, and still
worth loading, in six months?* If not, compact it now rather than later.

## Rules

- **Suppress, don't delete.** A suppressed PR still exists; it just doesn't lead
  the report. If it later goes red or picks up a blocking comment, surface it
  again and note that it was parked.
- **Ask before suppressing.** A `suppressions` entry goes in when he says "stop
  showing me that" — never off your own judgment that something is boring.
- **`until: "forever"`** for things that should never resurface; a date for "not
  this sprint," which correctly reappears once it lapses.
- **Corrections are the only part that compounds.** Everything else is
  bookkeeping.
