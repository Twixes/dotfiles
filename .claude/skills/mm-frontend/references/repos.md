# Repo memory

Harness wiring is annoying to derive and identical every time. Derive it once per project, write it down, trust it afterwards. That is what keeps this skill generic: nothing about any particular codebase lives in the skill, it lives in the memory.

One file per repo at `~/.claude/mm-frontend/<slug>.md`, where `<slug>` is the GitHub `owner-repo` when there is a remote, otherwise the repo directory name. Read it at the start of a run, write it at the end.

This is a cache, not documentation. If an entry needs more than a few lines it belongs in the project's own agent instructions instead.

## Schema

```markdown
# mm-frontend memory: <owner/repo>

## Storybook
Start: <command, port, cold boot time, whether a prebuild step runs first>
Story globs: <where a story file must live to be picked up, from .storybook/main.ts>
Tile depth: <app root at a real route / page container / component only, and the exact imports>
Navigate before mount: <the synchronous navigation call this project needs, or "n/a">
Mocks: <the decorator or addon that supplies data, and where fixtures live>
Parameters that matter: <date pinning, feature flags, theme, layout>
Exemplar story: <path to the closest existing story to copy>

## Frontend rules
Component library: <the mandated one, and what is off limits>
Logic layer: <where business logic goes>
Data types: <generated or handwritten, location, and the command that regenerates>
Checks: <typecheck command, lint/format command, and how expensive each is>
Project skills worth invoking: <area -> skill>
Also read: <paths to agent instruction files that govern frontend here>

## Data available here
<can bets about user behavior be checked, and how>

## History
Won: <dated one-liners: surface, which variant won, why>
Rejected on principle: <ideas he does not want proposed again, and why>
Harness scars: <things that broke and the fix>
```

## Rules

- Trust a working entry. Do not re-verify it.
- If a recorded command fails, re-derive that one entry and update it. Never leave a stale entry in place while quietly working around it.
- **Mark what was verified by running versus by reading config.** They are not the same confidence, and a pattern read out of a config file can be subtly wrong in a way only a boot reveals.
- **A project with no Storybook is a valid finding.** Record it, and either set Storybook up if that is proportionate to the work, or use the contact-sheet fallback in [harness.md](harness.md). Do not silently skip the grid.
- `Rejected on principle` only grows from real rejections. Do not seed it with guesses, and keep the reason, because "rejected because the execution was rough" is the opposite of "rejected because he hates the idea".
