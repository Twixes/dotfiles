# Frontend and UX

Frontend changes are usually low blast radius, which buys them forgiveness on risk. They get none on user experience. A change that ships an awkward flow or sloppy spacing is worth blocking.

Reading the diff is not enough. Get eyes on it: [environment.md](environment.md) has the ladder (existing preview environment, then devbox, then local) and the repo memory that stops it being rediscovered every time. Say in the report which rung was reached, because it sets the confidence on everything here.

## Grounding

- ***Refactoring UI*** (Adam Wathan and Steve Schoger). The working vocabulary for craft findings. Start with too much white space and remove it rather than cramming. Establish hierarchy with weight and color, not just size, and emphasize by de-emphasizing everything else. Use a constrained spacing and type scale instead of eyeballing values, so the scale is the reason a gap looks wrong. Don't use grey text on colored backgrounds. Give empty states real design attention, since they are the first thing every new user sees.
- ***The Design of Everyday Things*** (Don Norman). Affordances and signifiers, mapping, and above all **feedback**: after any action the user must know what happened. The gulf of evaluation is the gap between what the system did and what the user can tell it did, and most "confusing UI" findings are that gap.
- **Nielsen's 10 usability heuristics.** Three earn their keep on nearly every PR: visibility of system status, error prevention over error messages, and help users recognize, diagnose, and recover from errors. The heuristics also double as a checklist for the states below.
- ***Don't Make Me Think*** (Steve Krug). The user should not have to work out what a thing is or what will happen. If a reviewer has to reason about it, a user will not bother.
- **GOV.UK content design** for copy: plain language, front-load the meaningful words, say what happens next.

## Flow, first

The part that matters most and the part a screenshot alone will not tell you.

- After the user acts, can they tell what happened? Norman's feedback, and the most common real defect.
- Can they tell what to do next?
- Is anything two steps that should be one, or one step that should have been confirmed because it is destructive or expensive?
- Does the change put something important behind a hover, a scroll, or a state the user has no reason to enter?
- Does it break an existing habit or muscle memory without a reason worth the cost?
- Is the change discoverable at all, or does it rely on the user already knowing it exists?

Anything that would make a first-time user hesitate is worth raising even when it is technically correct.

## States

The diff shows the happy path. Ask what the others look like, and check them where the environment allows.

Loading, empty, error, permission denied, zero items, one item, very many items, very long strings and unbroken tokens, slow network, stale data, offline.

Missing empty and error states are the most common real defect in frontend PRs. An error state that dead-ends without saying what to do next is a defect, not a nit. An empty state that is a blank box is a wasted first impression, per *Refactoring UI*.

**Double submission** deserves its own check every time: any button or form firing a network request must be disabled and show a loading state while in flight, with the state reset on both success and error. A clickable submit during an active mutation is a defect.

## Craft

- Spacing and alignment consistent with neighbouring components and on the design system's scale, rather than eyeballed per element. Name the odd value.
- Hierarchy: is the most important thing on screen actually the most prominent, and is prominence achieved with weight and color rather than everything competing at once.
- Transitions that are not abrupt or janky, and no layout shifting as content loads.
- Focus and keyboard navigation intact, including on anything newly interactive. Focus visible, focus trapped in modals, escape closes.
- Behavior at narrow widths, and with the browser zoomed.
- Dark mode as well as light, and contrast that holds in both.
- Reuse: a hand-rolled component duplicating something the design system already provides is both a craft and a consistency finding, and it is easy to catch by grepping for the existing primitive.

## Copy

Everything a person reads: labels, buttons, tooltips, empty and error states, notifications, toasts, confirmations.

- Sentence case, not Title Case. This holds even for product names: "Product analytics", not "Product Analytics".
- **No em-dashes.** They are the clearest tell of unedited generated text. Replace with a hyphen, a comma, or a rewrite. En-dashes in ranges are fine and should be left alone.
- The rest of that family travels with them: "not just X, but Y", rule-of-three padding, hedging preambles, cheerful filler, and exclamation marks.
- **No internal jargon leaking to users.** The word the engineer uses is rarely the word the user needs. "Pattern examples" is a data model talking; the user calls those "issues". Read every new string and ask whether it is named from the user's side or the implementation's.
- **No unexplained acronyms.** If someone who does not work here would not know it, expand it or drop it.
- **Do not assume the user is a company.** "Your business" alienates the hobbyist and the side-project user. "Your project" costs nothing and fits both.
- **Put the user at the center, not the product.** "I'll ask you a few questions" centers the software; "Hope it's okay if I ask a few questions" centers the person.
- Descriptions read best as plain imperatives. Conditionals and a third sentence are usually cuttable.
- No trailing ellipsis on placeholders unless the surrounding UI already adds one, and never two.
- Errors and empty states say what happened and what to do next. Never dead-end.
- Consistent with the terms the rest of the product already uses for the same thing.

If the repo has its own copy or design-system skill, invoke it. Its rules beat these generic ones.

## Semantics of color and icon

Cheap to get wrong, and jarring for a user when it is.

- Color has to carry the meaning it conventionally carries. Severity ordering runs red, orange, yellow: high is not green, and green never marks a problem. Errors are red rather than a neutral tint.
- An icon means what it depicts. An "x" says close, not minimize. A product's own mascot or logo says that product, so reusing it for something else implies a link that is not there.
- Anything interactive must look interactive: a cursor change, a hover state, weight, or an affordance. "It's impossible to tell that this is clickable without hovering over it" is a real finding.
- A control that is disabled for a reason should say the reason, and one that is disabled with nothing to explain it is usually better hidden.

## Reporting

Rank flow problems above state gaps, above craft, above copy. Mark anything not actually seen as unverified rather than assuming it is fine.

Include screenshot paths where captured. Before and after beats after alone, since an after-only shot cannot show a regression.
