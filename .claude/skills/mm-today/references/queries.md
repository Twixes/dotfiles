# Queries

Everything here was run and verified against live data. Constants: GitHub login
`Twixes`, Slack user `U015X6QQN0N`, `#team-self-driving` is `C09SK2PAGKF`.

Run the sweeps in parallel — Slack dominates wall-clock.

## PRs

Always go through the script. It paginates, which is mandatory (see below).

```bash
D=~/.claude/skills/mm-today/references
$D/fetch-prs.sh 'is:pr is:open org:PostHog author:Twixes'            # ~28, ~12s
$D/fetch-prs.sh 'is:pr is:open org:PostHog review-requested:Twixes'  # ~78, ~30s
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

The old single-call `first: 50` version **silently truncated the review queue at
50 when the real count was 78.** That's the failure this script exists to prevent.

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
inside the GraphQL query.** PostHog PRs carry **168–435 check contexts** and
`contexts(last: 100)` silently truncates, so the genuinely-failed job usually
falls outside the window. An early version of this skill did exactly that and
reported three real failures as false alarms.

So: take the rollup as the coarse signal, then shell out **only for the handful
that read `FAILURE`**:

```bash
gh pr checks <n> --repo <repo> | awk -F'\t' '$2=="fail"{print $1}'
```

Only a few PRs are red, so this is a few extra calls, not eighty.

### Search qualifier gotchas

- `org:PostHog` goes **inside the query string**. `gh search prs --org=` is not a
  real flag and errors out.
- `review-requested:` drops off once he submits a review, so the queue is
  genuinely un-actioned — but team-assigned requests persist and some entries are
  abandoned by their author. Age plus a dead author means rank it low, not chase it.
- `reviewDecision: null` means nothing was requested or submitted — common on his
  own PRs, and **not** the same as `REVIEW_REQUIRED`.

## Slack — team channel

```
slack_read_channel(channel_id="C09SK2PAGKF", limit=60)
```

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

For each hit, check whether he replied in that thread. No reply from
`U015X6QQN0N` after the mention = a dropped ball.

## Slack — promises

Wide net, then filter hard.

```
slack_search_public_and_private(
  query="from:<@U015X6QQN0N> <phrase> after:<14d ago>",
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
*itself* stalled — that's where the value is. Aug 3: *"Hmm I'll see what I can do
do have wizard support Replay Vision scanners"* → `wizard#1055` and
`context-mill#313` opened Aug 4, and #313 was sitting green with **no reviewer
requested**. A customer commitment, invisible, one click from moving.
