# Data, migrations, and deploys

The irreversible class. This is where a five-line diff earns more scrutiny than a thousand-line refactor, and where "we can fix forward" stops being true.

## Grounding

- ***Designing Data-Intensive Applications*** (Martin Kleppmann). Backward and forward compatibility, schema evolution, and the fact that during a rolling deploy old and new code run at the same time, so the schema must be readable by both. Chapter 4 is the whole mental model for this file.
- **Parallel Change / expand-contract** (Danilo Sato, on Fowler's site). Never change a shape in one step. Expand: add the new shape while the old one still works. Migrate: move readers and writers over. Contract: remove the old shape once nothing uses it. A single-step change is the default finding here.
- **Idempotency and exactly-once being a lie.** Anything that can be retried will be retried. The question is never "will this run twice", it is "what happens when it does".
- **Chesterton's Fence again**, in its sharpest form: deleting data is the one edit with no undo.

## The mixed-version window

During deploy, old and new code run simultaneously against one database. Most migration bugs live in this window rather than in the migration itself.

- Does old code still work against the new schema? A new non-nullable column with no default breaks every old insert.
- Does new code work against the old schema, for the interval before the migration lands? Deploy order is rarely guaranteed.
- If the code and migration ship together and the migration is slow, how long is the window, and what is broken during it?
- Does a rollback of the code leave the migration applied? It almost always does. Is the old code fine with that?

The test question: **if this is reverted after three days of production writes, what state is left, and does the old code cope with it?** If the answer is unknown, that is the finding.

## Schema changes

- New non-nullable column: is there a default, or a backfill, or both? A backfill without a default is a broken deploy.
- Backfill: is it batched, or does it try to rewrite the whole table in one transaction? Is it resumable if it dies halfway? Does it run inside the migration (blocking) or out of band?
- Index creation: is it concurrent or does it lock the table? At what row count does the difference start to matter, and does anyone know the actual row count?
- Column or table drop: has every reader genuinely gone? Grep is necessary and not sufficient, since dynamic access and other services do not show up. This is the case where "needs someone who knows X" is often the honest verdict.
- Renames: almost always should be expand-contract rather than an actual rename.
- Is there a reverse migration, and has anyone thought about whether it works, or is it the auto-generated one that will fail?

## Data transformations and backfills

- What happens to rows that do not fit the transformation? Silently skipped is the dangerous answer; the count of skipped rows should be visible somewhere.
- Is the transformation deterministic, so a rerun after partial failure converges rather than compounding?
- Does it write and read at the same time, and can it therefore process its own output?
- Is there a dry-run path, and did anyone run it?

## Event, message, and storage shapes

Changing a shape that other systems have already persisted is a migration even when no migration file exists.

- Old messages already in the queue, old events already stored, old cache entries already written: does the new consumer handle them?
- Is the change additive (new optional field, safe) or a redefinition (existing field means something different now, unsafe)? Redefining the meaning of an existing field while keeping its name is the worst version because nothing fails loudly.
- Cache and key-format changes: what happens to the existing entries, and does the change cause a full cache miss stampede on deploy?

## Side effects

Irreversible actions that are not database writes still belong in this class: emails, webhooks, payments, external API calls, notifications.

- Are they inside a transaction that might roll back? If so, the side effect happens and the state does not.
- Are they idempotent or deduplicated against a retry?
- On a backfill, does the side effect fire once per historical row? This is how a backfill sends fifty thousand emails.

## What to report

For anything in this class, the report should carry the rollback story explicitly, even when the verdict is "would merge". Michael's queasiness here is well calibrated, and the useful output is not reassurance but a clear statement of what happens if this goes wrong and what the escape hatch is.
