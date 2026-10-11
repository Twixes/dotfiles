# HTML explainers, proposals, and change reviews

Help an engineer understand the work and enjoy reading about it. Assume engineering competence, not familiarity with this project's names, files, or flows. The reader should finish able to explain the situation and reason about it independently.

## Understand before presenting

Read the actual code, diff, plan, or data, even if you authored it. Verify claims and retain the method behind measurements. Distinguish observed facts, illustrative examples, proposals, and estimates. For a change review, compare the actual base and head revisions; do not treat the current checkout as evidence of both.

Work out the background the reader needs and choose a concrete example that makes the mechanism clear. Explain what normally happens and why before introducing implementation names. For example, explain how a stalled worker's late cleanup could erase its replacement's status before naming an ownership token.

Order the explanation by what the reader must understand first, not by file order or research chronology. Keep material uncertainties visible. Move detailed evidence to an appendix, not concepts essential to following the argument.

## Choose the purpose and shape

| Purpose | What the page teaches |
| --- | --- |
| Explainer | How something works or why it behaves this way; no problem or proposed fix is required |
| Proposal | The current situation, concrete problem, plausible options, recommendation, benefits, and costs |
| Change review | What the change does, why, consequences, alternatives actually considered, and what remains to verify |

Default to a scrolling, illustrated engineering article. Use slides when the user asks or when sequential pacing helps. There is no mandatory section sequence, figure quota, or card grid. Do not invent alternatives or a problem to fill a template.

For several proposals, give a compact overview followed by a complete explanation of each. Readers should not need to assemble one proposal from scattered subsystem notes. For simplification claims, identify which states or responsibilities disappear and which are introduced; distinguish measured source size from estimated removable code and net savings.

## Build on the visual foundation

Copy [the base HTML](../assets/visualization-base.html) into the project's documentation or artifact directory. It supplies light/dark tokens, a theme toggle, code highlighting, copy buttons, print styles, and optional primitives. Invent the page layout; the foundation is not a fixed outline.

- Open with an understandable situation or takeaway. Keep branch names, author metadata, and process details quiet.
- Write connected prose, short paragraphs, and concrete examples. Cut repetition without stripping away the explanation.
- Keep text near 70 characters per line, body type at least 15px, and figure labels readable. Support light/dark and a 390px viewport without clipping or navigation covering content.
- Use interaction when it teaches: reveal a sequence, compare before and after, explore a tradeoff. Keep the main explanation understandable without hidden hover states. Make controls keyboard accessible.
- Replace title, description, and Open Graph metadata. Inline CSS, scripts, diagrams, and images into one file, ideally under about 3 MB. Use system fonts by default so the file works offline.
- Escape literal code and data before inserting them into HTML. The built-in highlighter reads code text; it does not make raw HTML-safe insertion unnecessary.

## Choose visuals by the question

State what the reader should learn from a visual before choosing its form. Introduce actors and concepts before relying on them. Labels use plain language first, with identifiers only where they help connect the explanation to verified code.

| Question | Useful form |
| --- | --- |
| What happens over time, or how does a race arise? | Timeline or sequence |
| What changes for one concrete input? | Worked example or before/after comparison |
| What is it made of, and which parts change? | Annotated parts drawing |
| Which cases lead to which outcomes? | Outcome groups or a decision tree |
| Which quantity is larger, or how does it change? | Chart computed from the data |
| What exact values should I compare? | Table with units and a baseline |
| What will the experience feel like? | Screenshot or working UI comparison |

Avoid defaulting to boxes and arrows for every subject. A connected list of module names is not an explanation. Split overloaded figures into understandable steps. A paragraph is sometimes the clearest choice.

Use text-searchable HTML/CSS or inline SVG for precise diagrams. Render Mermaid into the artifact instead of requiring a remote runtime. Compute chart geometry from real data; label units, sources, time windows, and uncertainty. Never invent measurements or intervals.

Illustrations can introduce a substantial topic or make a difficult concept approachable. Use an available image-generation tool when helpful; no mandatory images or credentials dependency. Keep a coherent style across the page and both themes. Illustrations support learning, while exact code, numbers, and architectural claims remain verified text.

## Review and hand over

Read the main path as an engineer unfamiliar with the subsystem. Can you explain the normal flow, the change where relevant, and its consequences? Does every figure teach something using only the background supplied? Fix passages that substitute jargon or inventories for explanation.

Open the page with available browser tooling. Inspect light and dark desktop views and a narrow phone view; exercise the interactions. Check for clipped text, tiny labels, broken images, console errors, and unexpected network dependencies. A successful render alone does not establish that the document explains the topic well.

Deliver the local HTML file. If sharing was requested and the project has an authorized publishing path, publish there and provide the URL. Do not import another repository's deployment commands or assume its hosting, credentials, or access controls. Update the same artifact for follow-up edits.
