# Blast radius

How to run the heavy part of a review: chasing the ways a change can go wrong, then throwing away everything that does not survive scrutiny.

The goal is not a long list. The win condition is that an entire dive gets distilled into a few things worth knowing. Investigate widely, report narrowly.

## Grounding

- **Hyrum's Law.** With enough users, every observable behavior of a system will be depended on by somebody. The contract is not what the docs say; it is what the code does. This is the single most useful idea for sizing a radius, because it redirects the question from "did the signature change" to "did any observable behavior change".
- ***Release It!*** (Michael Nygard). Stability antipatterns are the failure catalogue worth carrying: integration points, cascading failure, blocked threads, unbounded result sets, slow responses, retry storms. The matching patterns are timeouts, circuit breakers, bulkheads, fail fast. When a change adds a call to something it does not control, this is the vocabulary.
- ***How Complex Systems Fail*** (Richard Cook). Complex systems run in degraded mode continuously; failure needs multiple contributing causes; every change introduces new forms of failure. This is why "each piece looks fine" is not a conclusion, and why the interesting question is what this change does when something else is already broken.
- **Reversibility over correctness** (Bezos' one-way versus two-way doors). Effort belongs where reversal is expensive, not where the diff is large.

## Fanning out

Match the fan-out to the class from the triage table in SKILL.md.

**Contained.** No subagents. Read the diff and its immediate surroundings inline.

**Local.** 2-3 subagents, each holding one distinct question. Do not hand two agents the same question in different words.

**Wide or irreversible.** 5 or more investigators covering different failure axes, then adversarial verification of every candidate finding.

Give each investigator the diff, the base, and exactly one question. Investigators return a concrete failure scenario or nothing. "Looks fine" is a valid and welcome result; a stretched hypothetical is not.

Tentative results are fine. The need is not conclusive research, it is having the sifting done. An investigator that surfaces "probably fine, but here is the one path I could not rule out" has done its job.

## Questions worth handing out

Templates, not a checklist to run in full. Pick the ones the diff earns.

**Callers and contracts**
- Enumerate every existing caller of `<changed symbol>`. For each, does behavior change? Return the list with a verdict per caller.
- Does any caller depend on something this change alters that is not in the signature: ordering, nullability, exception type, timing, idempotency, side effects, log output? (Hyrum's Law lives here.)
- Is `<changed symbol>` reachable from outside this codebase (API, event, SDK, webhook, plugin, tool)? If so, who consumes it and what breaks?

**New logic**
- Trace `<new code path>` with adversarial inputs: empty, null, zero, one, very many, unicode, duplicates, out of order, stale.
- What happens on partial failure? If step 3 of 5 fails, what state is left behind, and is a retry safe?
- What happens under concurrency? Two of these running at once on the same row, key, or user.
- What happens on retry or replay? Does anything double-count, double-charge, or double-send?
- What happens when the thing it depends on is slow, down, or returns something unexpected? Is there a timeout, and is there a bound on the retries?

**Blast containment**
- Does a failure here stay here, or does it take something else down with it? Shared pools, shared queues, and shared caches are where local failures become global.
- Is the new behavior gated, and does turning the gate off actually stop it, or only stop new entries into it?

**Cost and scale**
- Is any result set unbounded? What happens at the largest realistic size, not the fixture size?
- How many calls or queries does one request now issue? Count, do not estimate.

Deploy, rollback, and migration questions live in [data-and-deploys.md](data-and-deploys.md).

## Adversarial verification

For wide and irreversible changes, every candidate finding gets challenged before it reaches the report. Hand it to a fresh agent whose job is to **refute** it, defaulting to refuted when uncertain.

The refuter asks: does the failing path exist and is it reachable? Is there a guard upstream that already prevents it? Does an existing test or type constraint rule it out? Is the described input possible given real callers?

Then:

- Refuted: drop it entirely. Do not report it as "possible" out of politeness to the investigation.
- Survives with a reproducible path: blocker or worth-knowing, depending on impact.
- Survives but cannot be reproduced from real callers: worth-knowing at most, and say plainly that it is theoretical.

A finding resting on something unverifiable from the repo alone (production data volume, real traffic shape, whether a customer depends on old behavior) does not get dropped. It goes into the verdict's confidence line, because that is exactly what Michael can resolve in seconds and you cannot.

## What makes the report

A finding earns a place only if it would change the merge decision, or change how the code is used or watched after merge. Everything else was investigation, not output.

Rank by expected damage: how bad if it happens, times how likely. A certain cosmetic bug ranks below an unlikely data-loss bug.

Merge findings sharing a root cause into one entry. Three symptoms of one missing guard is one finding with three consequences.
