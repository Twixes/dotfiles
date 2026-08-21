# Queries

Constants: GitHub login `Twixes`, GitHub org `zetalabs-ai` (Viktor lives in
`zetalabs-ai/zeta`). For Slack, use `from:me` / `to:me` — don't hardcode a user
or channel id; those change across workspaces.

Run the sweeps in parallel — Slack dominates wall-clock.

## PRs

Always go through the script. It paginates, which is mandatory (see below).

```bash
D=~/.claude/skills/mm-today/references
$D/fetch-prs.sh 'is:pr is:open org:zetalabs-ai author:Twixes'            # his PRs
$D/fetch-prs.sh 'is:pr is:open org:zetalabs-ai review-requested:Twixes'  # his queue
```

Returns `{prs, issueCount, fetched, truncated}`. **Check `truncated`.** Report it
if true — a silently short queue makes the whole run wrong.

Parse with Python, not chained `jq`; the bucketing logic needs to be readable and
you need it for ranking anyway.

### Why the page size is 25

`pr-triage.graphql` uses `first: 25` **on purpose**. Measured against the review
queue:

| search page size | result |
|---|---|
| 100 | **HTTP 502** after ~12s |
| 50 | **HTTP 502**, even with sub-fields halved |
| 25 | OK, ~8.5s, cost 14 |

The bottleneck is PRs-per-page, not the sub-field sizes — 50 still 502s with
`files(first:50)`. Do not raise `first:` without re-testing against the queue,
which is the heavy one. A 502 comes back as HTML, so a naive JSON parse dies with
a confusing decode error rather than anything that reads like a rate limit.

The old single-call `first: 50` version **silently truncated a review queue that
was larger than one page.** That's the failure this script exists to prevent.

### Fields, and what each is for

| Field | Why |
|---|---|
| `mergeStateStatus` | `CLEAN`/`BEHIND`/`DIRTY`/`BLOCKED`. The real mergeability signal. |
| `mergeable` | Computed async — often `UNKNOWN` on first request. Prefer `mergeStateStatus`. |
| `reviewRequests.totalCount` | `0` = **invisible, nobody asked to review**. `1` = he's the sole reviewer. |
| `viewerLatestReview` | Has he already reviewed it? Compare `submittedAt` to the last `pushedDate` to catch "author pushed since". |
| `files.nodes.path` | Deep-review risk. **Titles hide risk; paths don't.** |
| `reviewThreads` | `isResolved` for unresolved counts; the first comment's author for who's waiting. |
| `baseRefName` | Not `master`/`main` = stacked, and it cannot merge until the parent lands. |
| `autoMergeRequest` / `isInMergeQueue` | Already handled — don't surface as actionable. |
| `statusCheckRollup.state` | Coarse CI only. See below. |

`files(first: 100)` is ample — his PRs top out around 55 changed files. If
`changedFiles > 100` the list is truncated, but such a PR is deep-review on size
alone, so it only ever under-detects on something already flagged.

### CI: the rollup lies, and contexts don't fit

`statusCheckRollup.state` can read `FAILURE` when the only bad job was **cancelled
by a superseding run**. So it needs verification — but **you cannot verify it
inside the GraphQL query.** Large monorepo PRs can carry **hundreds of check
contexts** and `contexts(last: 100)` silently truncates, so the genuinely-failed
job usually falls outside the window. An early version of this skill did exactly
that and reported real failures as false alarms.

So: take the rollup as the coarse signal, then shell out **only for the handful
that read `FAILURE`**:

```bash
gh pr checks <n> --repo <repo> | awk -F'\t' '$2=="fail"{print $1}'
```

Only a few PRs are red, so this is a few extra calls, not the whole queue.

### Search qualifier gotchas

- `org:zetalabs-ai` goes **inside the query string**. `gh search prs --org=` is not a
  real flag and errors out.
- `review-requested:` drops off once he submits a review, so the queue is
  genuinely un-actioned — but team-assigned requests persist and some entries are
  abandoned by their author. Age plus a dead author means rank it low, not chase it.
- `reviewDecision: null` means nothing was requested or submitted — common on his
  own PRs, and **not** the same as `REVIEW_REQUIRED`.

## Slack — team channels

Don't hardcode a channel id. Find the Zeta Labs / Viktor channels he's actually
in from recent mentions and conversations, then read the last 2–3 days of the
ones that look like team home (engineering, product, his working group).

Two to three days is enough. Pull only: someone blocked on Michael, work
colliding with his open PRs, unanswered questions to him, and what the team is
pushing this week. Follow a thread with `slack_read_thread` only when the parent
looks like it blocks him.

## Slack — unanswered mentions

The highest-yield dropped-ball signal in the run.

```
slack_search_public_and_private(
  query="to:me after:<14d ago>", sort="timestamp", limit=20)
```

For each hit, check whether he replied in that thread. No reply from him after
the mention = a dropped ball.

## Slack — promises

Wide net, then filter hard.

```
slack_search_public_and_private(
  query="from:me <phrase> after:<14d ago>",
  sort="timestamp", limit=20, include_context=false)
```

Run several phrasings — one query doesn't cover it:

`I'll` · `I will` · `let me` · `I can` · `on it` · `will do` · `I'll take a look`
· `going to` · `I'll ship` · `write this up` · `I'll look into`

`include_context=false` keeps responses small; fetch the thread only for
candidates that survive filtering.

**Verified signal-to-noise.** One `I'll` search over two weeks returned twelve
hits: roughly four real commitments, the rest jokes ("I'll need to practice my
Abba"), narration, and small talk. Expect to discard most of it, and never report
a promise you haven't read in context.

**Then check for discharge**, and then check whether the discharging PR is
*itself* stalled — that's where the value is. The shape: he says he'll add
support for something a customer asked about, a PR goes up the next day, and
that PR is sitting green with **no reviewer requested**. A customer commitment,
invisible, one click from moving.
