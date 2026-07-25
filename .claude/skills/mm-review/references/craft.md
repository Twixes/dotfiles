# Craft

The least important lens, because agents and colleagues mostly write sensible code. Two things get called out every time anyway: bloated comments, and code that fights the language.

Keep everything here to one terse line per finding. Craft findings are mechanical and do not need an argument.

## Grounding

- ***A Philosophy of Software Design*** (John Ousterhout). Complexity is change amplification, cognitive load, and unknown unknowns. His rule for comments is the one to apply: **comments should describe things that are not obvious from the code.** A comment restating the code adds cognitive load while pretending to remove it. He also supplies the module test worth carrying: depth, meaning a simple interface over substantial implementation.
- **The Zen of Python (PEP 20)** and its equivalents: *Effective Python* (Slatkin), *Effective Go*, the *Rust API Guidelines*. Every language has a written idiom, and "works" is not the same as "written the way this language is written".
- ***The Pragmatic Programmer*** (Hunt and Thomas). Orthogonality, and DRY as duplication of *knowledge* rather than duplication of text. Two similar-looking blocks that encode different decisions are not a DRY violation, and merging them is a mistake.
- ***Refactoring*** (Fowler), for one specific question: a change labelled a refactor should be behavior-preserving. If it is not, that is a finding regardless of whether the new behavior is better.

## Comments

Two failure modes, and they pull in opposite directions. The rule that resolves them is Ousterhout's: **a comment earns its place by carrying information that is not in the code.** Judge every comment against that one sentence rather than against length.

### Missing why

The more common defect, and the one Michael actually asks for most often. Any value, threshold, or ordering a reader cannot derive should say where it came from:

> We should have a comment WHY this number specifically.

> Oddly specific without comment.

> Let's add this context to the code, for other/later readers.

So flag:

- A magic number, timeout, batch size, or limit with no rationale. `timedelta(hours=1, minutes=5)` needs to say it is a little over the max wait it is covering.
- A non-obvious ordering, a deliberate exclusion, or a workaround that looks like a mistake.
- A guard whose absence caused a bug once, where the next person will delete it as dead code.
- Settings copied from elsewhere that nobody can now justify.

When a reviewer asks "why is this like this" and the author answers in the thread, that answer belongs in the code. A good explanation that lives only in a resolved PR comment is lost.

### Bloat

The other failure mode, and Michael's stated allergy. Enormous blocks that restate the code, narrate the change history, or explain what any competent reader can see. They burn tokens, they rot into lies as the code moves, and they make the file harder to read, not easier. *"This is kind of wall-of-text-y!"*

Always goes:

- Comments restating the next line or the function signature in prose.
- Change narration: "previously did X, now does Y", "changed because", "per the review", "AI:", "updated to handle the new case". That belongs in the commit message and the PR description, where it is dated and attributed.
- Section banners and decorative dividers inside a function.
- Docstrings listing parameters and types with nothing the signature does not already carry.
- Commented-out code. Git remembers it, and a commented-out block is a recipe for abandonment and confusion later.
- A docstring arguing with reviewers rather than explaining the code.

### Both at once

The two coexist happily: a file can have three paragraphs of narration and still not say why the retry count is seven. When flagging bloat, say what should survive rather than just cutting, and when flagging a missing why, write the sentence you want rather than asking for one.

When refactoring or moving code, existing comments should survive unless the change actually made them obsolete. Silently dropping a why comment during a move is a real loss.

## Fighting the language

Code that works but is not how the language is written. Judge against the language's idiom *and* against what the surrounding file already does, since local consistency usually wins.

The recurring Python case is imports inside functions instead of at module level. It hides dependencies from static analysis, repeats the lookup on every call, and usually papers over a circular import that should have been fixed structurally. There are three legitimate exceptions: breaking a genuinely unavoidable cycle, `TYPE_CHECKING`-only imports, and keeping a heavy optional dependency off the import path. Anything else is a finding.

The category is broader than that one case. Other examples of the same shape:

- Manual index loops instead of iteration or comprehension; building a list by index when a comprehension says it.
- Mutable default arguments; `type(x) == Y` instead of `isinstance`; bare `except`.
- Reimplementing something the standard library already provides.
- Ignoring the language's own idioms for errors: exceptions where the language uses exceptions, result types where it uses those, and not swallowing errors into a sentinel value.
- In TypeScript: `any` where a real type exists, type assertions covering up a modelling problem, enums or classes where the codebase uses unions and functions.
- Async code that blocks, or sequential awaits where the calls are independent.

## Strings a person reads

Copy rules are not frontend-only. Backend error messages, API error bodies, CLI output, notification and email text, and docs all get read by someone. The same bar applies: sentence case, plain language, no em-dashes, say what to do next. See [frontend-ux.md](frontend-ux.md) for the full list.

## Structure, at nit weight

Only when it is actually costing something:

- A new abstraction with exactly one caller, added speculatively.
- A shallow module: a wrapper whose interface is as complex as what it wraps, adding vocabulary without removing work.
- Dead code introduced by the change, including a flag that is never read and a parameter never passed.
- Copy-paste of a nearby block where the two copies genuinely encode the same decision and will need to change together.
- A function that grew a boolean parameter changing what it fundamentally does, which is two functions wearing one name.

Do not flag naming taste, formatting the linter already owns, or "I would have structured this differently" on code that is clear and contained.
