# Generating a spread that is actually a spread

The failure mode this file exists to prevent: four variants that are the same design with different padding. It happens because of how generation naturally works. You think of one design, it feels right, and then you produce three perturbations of it to satisfy the requirement for four. The grid then shows four near-identical tiles, Michael learns the exercise is theater, and the skill is dead.

The fix is to stop varying the **design** and start varying the **bet**.

## Vary the bet, not the arrangement

Every design encodes an assumption about what the person using it is mainly trying to do. That assumption is the variant. The layout is just its consequence.

So write the bet first, then let the layout fall out of it:

- "Filtering is the main verb" produces a persistent filter rail.
- "Scanning is the main verb, acting is rare" produces a dense list with actions hidden until hover.
- "People arrive to deal with one specific thing they were notified about" produces search-first, or a detail view with the list demoted to a sidebar.
- "The grouping matters more than the individual rows" produces a board or grouped sections.
- "There are usually zero items and that is the healthy state" produces a design built around the empty case, with the list as an afterthought.

Four bets that genuinely conflict give you four designs that genuinely differ. Four layouts chosen first give you four versions of one design.

## The distinctness test

Run this on your own list before you spend build time on it. Nobody else is going to catch a padded spread, because the spread is never sent for approval. **Would being wrong about each variant look different?**

Two variants that would fail for the same reason are one variant. Two variants that fail differently, one because filtering turned out to be rare and one because the grouping turned out to be meaningless, are genuinely two options and worth building.

Second check: can you state each bet in one sentence without using the words "cleaner", "more modern", or "better"? Those words mean you varied the aesthetics, which is the one axis a grid does not need help exploring.

## Axes worth reaching for

When the bets are not obvious, these reliably produce real difference:

- **What gets promoted to first-class.** Every surface has something currently buried that could be the main event, and something prominent that could be demoted.
- **Density.** A version that fits three times as much on screen is a real option with real costs, not a tweak.
- **Where the detail lives.** In place, in a side panel, on its own page, in a modal. This choice changes everything downstream.
- **Navigation model.** Tabs, a rail, sections on one long page, a switcher.
- **Subtraction.** A variant that removes half of what is there. This is the most underused option and quite often the winner, because most redesigns are asked for when a surface has accumulated rather than when it lacks anything.

## The two ends have jobs

**A, the safe one, must be genuinely shippable today.** Not a straw man. Its job is to be the honest answer to "what if we just fixed the hierarchy and spacing and stopped there", and it wins often enough that making it weak on purpose is self-defeating. Michael's instinct favors small contained changes, so the safe variant is a real contender, not a control.

**D, the swing, must be defensible rather than merely strange.** Weird is not the goal. The goal is an option that would be clearly right if its bet holds, and clearly wrong if it does not. If you cannot argue for it sincerely, it is not a variant, it is a decoy, and decoys make the whole grid feel padded.

## Ground it in what people actually do

A bet about the main verb is checkable when the product has analytics on itself. Which filters get used, how often the detail panel is opened, what fraction of sessions touch the thing you are about to promote. One real number kills a plausible-sounding bet faster than any amount of design reasoning, and it is worth the two minutes when the data is reachable.

When there is no data, say the bet is unverified. Do not present a guess about behavior as a fact about behavior.

## Practical limits

- **Only propose what you can build this session.** A variant that needs a new backend endpoint is not a variant, it is a project. Note it as a direction and move on.
- **All variants obey the repo's component library.** Layout and interaction are the playground. The button is not.
- **Do not propose the same losing idea twice.** The repo memory records what he has already rejected on principle, so read it before writing the spread.
- **Labels are a letter, a colon, and two to four words.** He refers to them out loud, so they need to be sayable: "B, but with C's header".
