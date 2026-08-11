---
name: mm-frontend
description: "Michael's frontend design process: never converge on one implementation without seeing the alternatives first. Picks a labeled spread of designs from safe to strange without stopping to ask, builds them concurrently as parallel variants inside a throwaway Storybook design lab, renders them together as a scaled grid of full-app iframes so they can be compared side by side, then consolidates the traits Michael names into the real component and deletes the lab. Keeps a per-repo memory so harness wiring is discovered once. Use for any new frontend feature, UI redesign, layout or navigation change, empty or error state design, or when asked to make something look better, and generally whenever there is a real visual or interaction decision to make rather than one obvious implementation."
---

# mm-frontend

You are building frontend for Michael. The rule that makes this skill exist:

**Do not converge on one implementation before he has seen the alternatives.**

The first design that occurs to you is almost never the best one available, and prose cannot settle a visual question. So the shape of the work is: propose a spread, build the spread, show the spread rendered, let him name what he likes from each, then converge. He picks by label and explains what he liked. That commentary is the actual specification, and it only exists once he has something to look at.

The output of this skill is not "a design". It is **a decision Michael made with real pixels in front of him**, plus the one implementation that came out of it.

## When this fires, and when it does not

Fires when there is a genuine design decision: a new surface, a redesign, a layout or hierarchy change, a new empty or error state, "make this nicer", anything where two competent engineers would produce visibly different results.

Does **not** fire when there is one obvious implementation. Do not run the ritual for a copy fix, a color token swap, a single prop, adding a column to an existing table, or a bug fix that restores the design already intended. Building four variants of a one-line change wastes his time and trains him to skip the grid.

When it is genuinely borderline, say in one line that you are skipping the spread and why, then just do the work. He will ask for options if he wants them.

## 0. Load the repo memory

Read the memory for this repo before anything else. It records how the design lab is wired here so it is never re-derived: how to start Storybook, where stories live, how to mount the app at a real route, which component library is mandatory, and which past spreads landed.

[references/repos.md](references/repos.md) has the location, the schema, and the rules for keeping it honest. Nothing about any specific codebase lives in this skill, which is what lets it work in any project that has Storybook.

If there is no memory, do the discovery during this run and write it at the end.

## 1. Find the real surface first

You cannot propose alternatives to something you have not seen. Before any design thinking:

- **Locate the actual component and its logic.** Not a component that looks related. The one that renders at the route in question.
- **Look at it running, or at least at its existing story.** If a story already exists, open it. This is the baseline every variant gets compared against, and it is also the thing you must not break.
- **Enumerate the states.** Loaded, empty, loading, error, one item, many items, long strings, narrow viewport. A design that only works in the happy state is not a design, and the states are where the interesting differences between variants show up.
- **Read the repo's frontend rules and obey them in every variant.** The mandated component library is not a variable you get to experiment with. If the repo says use its own design system rather than hand-rolled markup, all four variants use it. Creative means creative layout, hierarchy, and interaction, not creative reinvention of the button.

Note the baseline honestly. Sometimes the existing design is already fine, and saying so beats four alternatives to a solved problem.

## 2. Pick the spread yourself, and start building

**Do not ask him to approve the spread.** Choosing the options is your job, and a prose list is a poor way to judge a design anyway. Decide the variants and go straight to building them, in parallel.

Four by default. One safe, two genuinely different middles, one that takes a real swing. Fewer if the surface is small.

State them as you launch, one line each, so he knows what is coming and can redirect you while it builds if he wants to. This is an announcement, not a question.

```
Building four:
A: Tightened baseline   Keeps today's layout, fixes the hierarchy and spacing. The safe pick.
B: Split rail           Moves the filters into a persistent left rail. Bets that filtering is the main verb.
C: Inline expansion     Rows expand in place instead of opening a panel. Bets people scan, then dip in.
D: Board                Drops the table for a grouped board. Bets the grouping matters more than the columns.
```

Getting the spread right is the hard part, and four shades of the same idea makes the whole exercise pointless. [references/proposing.md](references/proposing.md) covers how to generate genuinely distinct options and the check to run on your own list before you commit build time to it.

## 3. Build the variants in parallel

Fan out **one subagent per variant**, working in the shared tree with no worktrees. That works only under strict file ownership, because agents in one tree will happily clobber each other.

The one thing that is genuinely sequential is the shared scaffolding. This is a collision constraint, not an approval step, so do it fast and keep going. **You, the orchestrator, write everything shared, first, before spawning anyone:**

- the design lab folder
- the stories file, including the grid story, with every variant already imported and referenced
- the shared variant contract: the props and mock data every variant receives, so the tiles are comparing design rather than comparing different data
- anything extracted from the baseline that more than one variant needs

**Each subagent gets exactly one file to create and nothing else.** Its brief carries: the one path it owns, the variant idea from the agreed spread, the baseline file to read, the shared contract to import, and the repo's frontend rules.

Hard rules in every subagent brief, because these are the collisions that actually happen:

- Create only your one file. Edit no other file, including the stories file, which already imports you.
- Need something shared that does not exist? Report it back. Do not add it.
- Do not touch the production component. Variants are copies that live in the lab.
- Do not run typecheck, lint, typegen, or codegen. The orchestrator runs those once at the end.
- Do not start a dev server or Storybook. One instance only, owned by the orchestrator.
- Make your variant respond to clicks. Hold local state for anything toggleable or expandable, because he will try the tiles, and a control wired to nothing often still renders as if it works.

Keep each variant copy thin. Import the real subcomponents and fork only the layer being redesigned, so a variant stays readable as a diff from the baseline and so the winner is cheap to promote in step 6.

When the agents come back, you run typecheck and lint yourself, once, and fix what they left. A variant that does not compile is a blank tile in the grid.

## 4. Show them all at once

The grid is a Storybook story that renders one scaled iframe per variant, each labeled, each pointing at that variant's own story. Iframes because every tile then gets its own document, and therefore its own store and its own router, which is what makes N full-app instances possible on one page at all.

[references/harness.md](references/harness.md) has the story file shape, the iframe grid, story ID pinning, the scaling math, and the isolation gotchas. It is stock Storybook throughout, so it carries across projects; only the mount and mock calls differ, and those go in the memory.

No Storybook in this project? Set it up if that is proportionate to the work, otherwise use the contact-sheet fallback in the same file. Either way say which, and never quietly skip the grid.

Before you show him anything, **look at it yourself**. Screenshot each variant headless and check that the tile actually rendered the variant and not an error boundary, a spinner, or the baseline. Handing him a grid with two broken tiles wastes the round trip, and you cannot tell it happened without looking.

Then start Storybook if it is not already up, open the grid story in his browser, and tell him in a couple of lines what to look at. Give him the labels and the bet behind each in one sentence, then stop. The tiles argue for themselves better than a paragraph does.

Say plainly which states each tile is showing. A grid of four happy states hides exactly the differences that matter, so where a variant's bet lives in the empty or loading case, show that case.

## 5. Let him drive

He will refer to labels: "B, but with C's header." That is the specification. Take it literally and do not smooth it into your own preference.

Expect more than one round. Cheap moves between rounds: adjust one variant in place, add a variant, kill a variant, or re-render the grid at a different state or viewport. Killing options as they lose is progress, so keep the grid honest rather than crowded.

Push back once, briefly, if he picks something you think has a real problem, name the problem, then build what he asked for. He decides.

## 6. Consolidate, then delete the lab

The wrap-up is a real step with a deliverable, not a fade-out.

1. **Merge the named traits into the production component.** The real component, wired to the real data layer, following the project's own conventions. A promoted variant file is not the deliverable, because the lab copy has mock data and shortcuts baked into it.
2. **Cover the states you showed him.** The empty, loading, and error cases that appeared in the grid have to work in the real thing.
3. **Delete the entire design lab.** Every variant file, the stories file, the folder. Confirm with `git status` that nothing from the lab is left staged or untracked. The lab existing in a commit is a mistake, so if the change is going to a PR, check the diff for it before pushing.
4. **Keep at most one story, if the surface deserved one anyway.** A story for the shipped design is often worth having. Four variant stories never are.
5. **Screenshot the final result** and show him, so the thing he approved and the thing you shipped are visibly the same thing.

## 7. Update the memory

Write back anything worth not re-deriving: harness wiring you had to work out, a mock that was fiddly to get right, a variant idea he rejected on principle rather than on execution, and which design won. Rejections are the valuable half, because they stop you proposing the same losing idea next quarter.

Keep it terse, per [references/repos.md](references/repos.md).

## Rules

- **Never ask him to approve the spread.** Pick it, announce it in a line each, and build. He judges pixels, not lists.
- **Build the variants in parallel, always.** One subagent per variant. Four sequential implementations is the main way this skill wastes his time.
- **Variants differ in design, never in data.** Same mocks, same props, same states. Otherwise the grid compares fixtures.
- **Every variant obeys the repo's component library and logic conventions.** Creativity lives in layout and interaction.
- **Verify the grid rendered before opening it.** Screenshot each tile yourself first.
- **The lab is throwaway and gets deleted in the same session.** Never commit it.
- **No em dashes in anything he reads**, including labels, story names, and the summary. Commas and colons do the job.
