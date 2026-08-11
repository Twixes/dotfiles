# The design lab harness

A throwaway Storybook folder holding one story per variant plus a grid story that renders them all at once. The grid renders **iframes**, not components, because a tile has to be an isolated instance and an isolated instance needs its own document.

Everything in this file is plain Storybook, so it works in any project that has Storybook at all. The parts that differ per project are called out as such, and they belong in the repo memory once derived.

## Why iframes and not N components on one page

An app of any size has a single global store and a single URL-driven router. Mount four copies of the root component into one document and they fight over both: whichever navigated last wins, and all four tiles render the same route. This is true of Redux, kea, Zustand, MobX, and every router built on the History API. It is not a bug you can work around inside one document.

Each iframe is a separate document, so each gets its own store, its own router, and its own mock handlers. That is what makes four labeled full-context tiles possible at all.

The cost is real and worth naming: four tiles means four full app boots. Expect the grid to be slow to settle and heavy on a laptop.

## Layout on disk

Put the lab next to the surface being redesigned, inside whatever glob the project's Storybook already scans, so no config change is needed. Check `.storybook/main.ts` for the `stories` globs. Give the folder an obviously temporary name so it is greppable at cleanup time.

```
<surface>/design-lab/
    Variants.stories.tsx     # every variant story + the grid story. You own this file.
    contract.tsx             # shared props and mock data. You own this file.
    variantA.tsx             # one subagent each
    variantB.tsx
    variantC.tsx
    variantD.tsx
```

## The shared contract

Written by you before any subagent starts. Its whole job is to guarantee the tiles compare **design** and not **data**.

```tsx
// contract.tsx
export const MOCK_ITEMS = [ /* the same fixture every variant renders */ ]

/** Every variant is this shape, so the grid can treat them interchangeably. */
export interface VariantProps {
    items: typeof MOCK_ITEMS
    state: 'loaded' | 'empty' | 'loading' | 'error'
}
```

Invent the mock data rather than copying anything real. In a public repo that is a hard rule, not a preference: write the fixture from a list of the properties it must exercise, with any real source closed.

Make the fixture unflattering. Long strings, a 60-character name, one item and forty items, a null where a null is possible. Designs that only survive tidy data all look equally good in a grid, and the differences you are trying to surface are exactly the ones that appear under strain.

## How much each tile shows

Pick by **what the decision is actually about**, not by how realistic you can make the tile. Maximum realism is the wrong default, because every layer you mount is another thing that can hang, race, or fail to mock, and a flaky tile teaches you nothing about a design.

**Redesigning page chrome, navigation, or a whole route?** Mount the app root at a real route. The chrome is the thing under discussion, so it has to be real.

**Redesigning a component inside a page, a modal body, a panel, a card?** Do **not** mount the app root. Write each variant as a pure component fed by a shared fixture, and frame it in a plain wrapper that stands in for its container. This is the better tile for most redesigns:

- Deterministic. No router, no mock layer, no async settling, so nothing flakes.
- A brutal stress fixture is one line rather than a mock endpoint.
- Boots in a fraction of the time, which matters when four tiles boot at once.

You lose surrounding context, so when the design leans on how it sits inside the page, frame it with a wrapper of roughly the right width and background rather than reaching for the whole app.

**A component library or a project with no single app root** is the pure-component case by default.

Record which mode a given surface needed in the memory. It is the most annoying thing to re-derive.

## One story per variant

Two project-specific pieces here, both marked. Everything else is stock Storybook.

```tsx
// Variants.stories.tsx
import type { Meta, StoryObj } from '@storybook/react'

import { MOCK_ITEMS } from './contract'
import { VariantA } from './variantA'

const meta: Meta = {
    title: 'DesignLab/InboxRedesign',
    // Pins the component half of every story ID. The story half is still derived from the export
    // name, so this does not save you from reading the real IDs. See "Never guess a story ID".
    id: 'designlab-inbox',
    parameters: {
        layout: 'fullscreen',
        viewMode: 'story',
    },
    // PROJECT-SPECIFIC: however this project supplies mock data to a story, usually an MSW
    // decorator or msw-storybook-addon. Same mocks for every variant.
    decorators: [],
}
export default meta

// PROJECT-SPECIFIC: navigate, then mount the root. Navigate SYNCHRONOUSLY, inside render, before
// the root mounts. A useEffect or a play function pushes after first paint, so the tile renders
// the default route for a frame and a screenshot can catch the wrong page.
const renderVariant = (Variant: () => JSX.Element) => (): JSX.Element => {
    // router.push(...) / history.pushState(...) / whatever this project uses
    return <Variant />
}

export const AVariant: StoryObj = { render: renderVariant(VariantA) }
export const BVariant: StoryObj = { render: renderVariant(VariantB) }
```

## The grid story

Same file, its own `render`, which overrides the meta-level one in CSF3. Inline styles on purpose, so the harness does not depend on the project having Tailwind or any particular CSS setup.

```tsx
const SCALE = 0.5
const TILE_W = 1440  // render each tile at a real desktop width, then shrink it
const TILE_H = 920

const VARIANTS = [
    { id: 'a-variant', label: 'A: Tightened baseline' },
    { id: 'b-variant', label: 'B: Split rail' },
    { id: 'c-variant', label: 'C: Inline expansion' },
    { id: 'd-variant', label: 'D: Board' },
]

export const AllVariants: StoryObj = {
    render: () => (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, padding: 16 }}>
            {VARIANTS.map(({ id, label }) => {
                const src = `/iframe.html?id=designlab-inbox--${id}&viewMode=story`
                return (
                    <div key={id}>
                        <a href={src} target="_blank" rel="noreferrer" style={{ fontWeight: 600 }}>
                            {label}
                        </a>
                        <div
                            style={{
                                width: TILE_W * SCALE,
                                height: TILE_H * SCALE,
                                overflow: 'hidden',
                                border: '1px solid #ccc',
                                borderRadius: 4,
                            }}
                        >
                            <iframe
                                src={src}
                                title={label}
                                style={{
                                    width: TILE_W,
                                    height: TILE_H,
                                    border: 0,
                                    transform: `scale(${SCALE})`,
                                    transformOrigin: 'top left',
                                }}
                            />
                        </div>
                    </div>
                )
            })}
        </div>
    ),
}
```

`iframe.html` is how Storybook serves a single story standalone, in both dev and static builds, so this works without any addon.

### Never guess a story ID

**Read the real IDs from `http://localhost:<port>/index.json` and copy them into the grid.** Setting `id` on the meta pins only the component half; Storybook still derives the story half from the export name, and its kebab-casing has an edge that will catch you out: **digits become their own segment.** `AVariant` gives `a-variant`, but `B1Variant` gives `b-1-variant`, not `b1-variant`. `AVariantHeavy` gives `a-variant-heavy`.

A wrong ID renders a blank tile with no error, which is indistinguishable from a slow tile, so guessing costs a whole debugging round. `index.json` is authoritative and takes one request.

The label is a link to the same URL, so clicking it opens that variant full size in a new tab. That is the move he will want the moment two tiles are close.

Scale to taste. `0.5` fits four desktop-width tiles on a laptop and stays readable enough to judge layout, though not type. When the decision is about density or copy, drop to two tiles at `0.7` instead of shrinking further.

## Gotchas, in the order they will bite

- **Never point a tile at the grid story's own ID.** It recurses until the tab dies.
- **Give the grid ten seconds before believing anything.** Four iframes are four independent Storybook boots, so a blank tile at first paint is usually just slow rather than broken. Screenshot each variant directly to tell the two apart.
- **A control with no handler can render as an inert element that looks perfectly normal.** Many component libraries downgrade a switch or checkbox to a plain `div` when no `onChange` is passed, so it paints correctly and does nothing. He will try to click the tiles, so variants must hold enough local state to respond.
- **A blank or spinning tile usually means mocks did not reach that document.** A mock service worker registers per document, so a nested iframe needs the worker already installed at the origin. Load one variant story directly first, which installs it, then reload the grid.
- **Route-driven data needs the route, not just the component.** If a tile shows an empty state you did not ask for, check that the synchronous navigation actually matched the route the data layer listens on.
- **Feature-flagged surfaces need the flag set the way this project's Storybook expects**, usually a story parameter. Imperative calls into a flag store are silently dropped in some Storybook runtimes, and the tile then renders the ungated design while looking fine.
- **Pin the date** for anything rendering relative timestamps, or two tiles will differ only by "3 minutes ago".
- **Storybook globals go in the URL**, so append `&globals=theme:dark` to a tile to force a theme. Worth a second grid pass when the design leans on surface colors.

## Verify before you open it

Screenshot every variant yourself, headless, at `1440x920`, hitting each variant URL directly rather than the grid. Direct hits tell you whether the variant is broken; the grid cannot, because a broken tile and a slow tile look identical.

Use the browser tooling available in the session: resize to 1440x920, navigate to `http://localhost:<port>/iframe.html?id=designlab-inbox--a-variant&viewMode=story`, wait for the surface to settle, screenshot, repeat. Check each one actually shows that variant's idea. An error boundary, a spinner, or the untouched baseline all mean the tile is not ready to show him.

Then screenshot the grid itself, since that is the thing he opens.

## Opening it

Start Storybook if it is not already running, in the background, and wait for the port rather than assuming it is up. A cold boot can take a while, especially where a prebuild step runs first.

Some task runners refuse to forward passthrough flags to the underlying Storybook command, so prefer the project's own script unmodified over appending flags to it. Do not wrap the server in a timeout either: a cap that expires kills the session he is still reviewing in. Launch it detached and poll `index.json` until it answers.

Then open the grid in his browser, using the story ID you read from `index.json`:

```sh
open "http://localhost:6006/?path=/story/designlab-inbox--all-variants"
```

Leave it running while he reviews, and shut it down at the end of the session if you started it.

## Fallback when Storybook will not boot

Do not let a broken harness eat the session. If Storybook is genuinely wedged, fall back to rendering each variant headless against the project's own dev server and compositing the screenshots into one labeled contact sheet. He loses interactivity, which is a real loss, so say so plainly and say why you fell back.
