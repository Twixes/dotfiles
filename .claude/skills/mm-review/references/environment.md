# Repo memory and getting a live app

Two jobs: remember what was learned about a repo so it is never re-derived, and get the change actually running so UI and behavior can be seen rather than inferred.

## The memory

One file per repo at `~/.claude/mm-review/<slug>.md`, where `<slug>` is the GitHub `owner-repo` when there is a remote, otherwise the repo directory name.

Read it at the very start of every run. Write it at the end. If it does not exist, do the discovery once during this run and create it.

### Schema

Keep it terse. This is a cache, not documentation. If an entry grows past a few lines it belongs in the repo's own docs, not here.

```markdown
# mm-review memory: <owner/repo>

## Seeing it run
Preview env: <how a PR gets one, how to find the URL, or "none">
Devbox: <command to start, connect, tear down, and any prerequisite, or "none">
Local: <command to start, ports, how heavy it is, how to stop>
Verified: <date>

## Base and stacks
Trunk: <branch>. Stacks: <tool, or "no">. Review base for a stacked branch: <how to find the parent>

## Conventions
Agent instructions: <paths>
Area skills worth invoking: <area -> skill>
Checks worth running or reading: <lint, typecheck, preflight commands>

## Where product context lives
<issue tracker, Slack channels, docs, analytics project>

## Data available here
<how to measure how often a code path is actually taken: analytics project and the skill
that queries it, log or metric store, useful event names already found, DB access for row
counts. "None" is a valid entry and changes how findings get ranked.>

## Risky territory here
<the areas in this repo where changes have actually hurt, one line each>

## Calibration
<dated one-liners: where a past review was wrong, and what Michael said instead>
```

### Refresh rules

- Trust the memory. Do not re-verify a working entry.
- If a recorded command fails, re-discover that one entry and update it. Never fall back silently to a lower rung while leaving a stale entry in place.
- If `Verified` is more than a couple of months old and the run needs the environment anyway, re-check while using it. Do not schedule verification work for its own sake.
- The Calibration section only grows from real corrections. Do not seed it with guesses.

## Getting a live app

This is the primary evidence source for the whole review, not a frontend extra. Michael's blocking findings come overwhelmingly from running the thing and watching it misbehave, so treat a run as the default and a static read as the fallback you had to settle for.

Backend changes count. Call the endpoint, run the management command, trigger the job, watch the worker log. "I ran it and the workflow completed but the rows were never updated" is worth more than any amount of reading the same code twice.

Work down this ladder. Stop at the first rung that works, and record in the report which rung was reached, because it sets the confidence on everything you report.

**1. A preview environment that already exists for this PR.** Best rung by a distance: it is the real change, already deployed, at zero cost to you. Check the PR's checks, deployments, and bot comments for a URL. Many repos post one as a sticky comment. Some only build previews when a label is applied or when the diff touches particular paths, which is worth recording in the memory so it is not rediscovered.

Check the preconditions the memory records before spending a timeout on it. Preview environments are often behind a VPN, a tailnet, or SSO, and an unreachable URL looks identical to a broken deploy. If a precondition is not met, say so and drop a rung rather than retrying.

**2. A devbox, or whatever the repo's ephemeral remote dev environment is called.** Preferred over local. Remote boxes are cheap to spin up, can run in parallel, and are torn down when done, so nothing is left holding local resources or fighting whatever state the local stack is already in. Record the start, connect, exec, and stop commands in the memory, along with any prerequisite (VPN or tailnet membership, a CLI login, a secret) since a missing prerequisite fails in a way that looks like a broken command.

**3. Local.** Only when there is no preview and no devbox. If a dev server is already running, just use it. If nothing is running and the stack is heavy, **ask before starting it**: it is slow, it can be disruptive, and Michael may have local state he cares about.

**4. Screenshots the author attached.** Judge those, and treat every state they do not show as unverified.

**5. Static read.** Review the source directly and produce an explicit "go look at this yourself" checklist naming the surfaces and states worth a human glance.

### Discipline once it is up

Name the surface, viewport, and theme you looked at. "Report detail page, 1440px, dark" beats "the UI". Capture before and after where the change modifies something that already existed; an after-only screenshot cannot show a regression.

Tear down anything you started. A devbox left running costs money, and a local stack left running costs Michael his laptop.
