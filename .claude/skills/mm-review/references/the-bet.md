# The bet

The most important lens. Does this change make sense at all, and does it make sense all the way down to the edge cases it will actually meet?

## Grounding

- **Chesterton's Fence** (Chesterton, *The Thing*). Do not approve the removal of a fence until you know why it was put there. Applied here: a change that quietly undoes a deliberate past decision is one of the most expensive mistakes a review can miss, and `git blame` usually reveals it in seconds.
- **The four product risks** (Marty Cagan, *Inspired*): value, usability, feasibility, viability. Most PRs have feasibility settled by the fact that the code exists. Value and usability are exactly what a diff cannot tell you, which is why this lens needs outside context.
- **Appetite before solution** (Ryan Singer, *Shape Up*). Scope is a variable, not a given. A change doing far more than the problem deserves is a finding, and so is one solving a fraction of it while claiming the whole.
- **"What are the important problems?"** (Richard Hamming, *You and Your Research*). Worth asking on the occasional PR that is competent work on something that does not matter.

## Work out the bet, for yourself

Say in one or two sentences what product bet this change makes, reconstructed from the diff, the description, and the surrounding code, and name the assumption it rests on. Aim it at behavior and users, not implementation:

> Widget tickets get a findings panel so users see the fix before the report. Assumes fix-first is what they want, and that every channel has findings worth showing.

Not:

> Adds a `FindingsPanel` component and wires it into `TicketView`.

**This is scaffolding, not output.** It forces you to understand the change before criticizing it, and it is how you notice the diff doing something the description never mentions. Michael has already read the description, so restating it back to him is filler.

Put it in the report only when the bet itself is the finding: the change solves something not worth solving, the description misdescribes the diff, or the intent is genuinely ambiguous and the verdict turns on which reading is right. Then it is a finding with consequences attached, not a header.

## Check the claim against the diff

The PR description is the author's claim, not the truth.

- Behavior in the diff that the title and description do not disclose deserves extra scrutiny. If that undisclosed behavior lands anywhere risky, it is a blocker on its own, regardless of whether the code is correct.
- Scope creep hiding inside a narrow title is the common version of this, especially in agent-authored PRs: a bug fix that also refactors three neighbouring modules.
- A missing description on a non-trivial change is a mild negative, not a blocker. Weigh it; do not refuse on it.

## Digging for context that is not on the PR

Whether an idea makes sense usually needs context the PR does not carry. Go get it, in roughly this order of cost.

1. **The repo.** `git log` and `git blame` on the touched lines. Why does the current behavior exist? Who last changed it, and did they change it *to* this on purpose? Look for the fence before agreeing to remove it. Also check whether a previous attempt at this same change was reverted, and why.
2. **GitHub.** Linked issues, referenced PRs, earlier PRs touching the same files, the discussion on this one. Review comments on the predecessor often contain the constraint this PR is about to violate.
3. **Slack**, when a product judgment is still hanging and Slack is reachable. Search the feature name, the surface, the error string, the PR URL. Design decisions frequently live only in a thread and nowhere else.
4. **Product data**, when the change rests on a claim about real behavior: "nobody uses this", "this path is hot", "most orgs have fewer than ten". Check the claim rather than accepting it. This is also how a low-risk-looking change gets correctly reclassified as wide.

## Down at the bottom

The same lens applies to the small decisions, and they carry as much of Michael's attention as the big ones. For every branch the change introduces, ask what the other branch does, and whether the author decided it or defaulted into it. Silence about an edge case is not the same as handling it.

Distinguish the two:

- **Deliberate:** the code says what happens when the list is empty, and it is reasonable.
- **Defaulted:** the code happens to do something when the list is empty, and nobody chose it.

Defaulted behavior in a risky path is a finding even when it currently produces the right answer.

## When to interrupt Michael

Only when the answer is load-bearing, meaning the verdict flips on it. Then stop before spending tokens on investigation:

> Before I dig in: is this widget meant to replace the old one or run alongside it? The blast radius answer is completely different.

Anything less than load-bearing waits for the "couldn't judge without" section at the end. Do not interrupt for it, and do not pad that section either: each entry has to say what it would change.
