# Naming and interfaces

Anything with consumers, and anything with a name a human will read. This is the highest-volume theme in Michael's review history and one of the few things he reliably blocks on, so give it real attention rather than treating it as polish.

## Grounding

- **Hyrum's Law.** With enough consumers, every observable behavior becomes part of the contract, whether or not it was documented. For an external interface this means the surface is larger than the schema: status codes, error shapes, field ordering, null versus absent, pagination behavior, and timing are all contract.
- ***A Philosophy of Software Design*** (John Ousterhout). Deep modules: a simple interface hiding significant implementation. The finding to look for is the shallow module, where the interface is nearly as complicated as the thing it wraps, so it adds vocabulary without removing work. Also "somewhat general-purpose" as the sweet spot between over-specialized and speculatively generic.
- ***API Design Patterns*** (JJ Geewax) and Google's AIPs. Consistency across a surface beats local cleverness. A new endpoint that names, paginates, or errors differently from its siblings is a defect even when it is individually reasonable.
- **Postel's Law, and its critique.** Be liberal in what you accept is how ambiguity becomes permanent. Prefer rejecting malformed input loudly over guessing at it.
- **"There are only two hard things in computer science"** is a joke that is also true. Naming is the cheapest thing to fix during review and the most expensive to fix after, because every reader and every caller pays for a bad one forever.

## Naming

Judge every new name a person will read: endpoints, resources, types, serializers, functions, variables, constants, config keys, flags, tool names. The bar is that the name should tell a reader what the thing is without them opening it.

**The resource test, for anything RESTful.** A URL segment should be a noun, and specifically a resource. Actions hang off the resource. Michael on a PR he blocked over exactly this:

> I'll be pedantic but I think API design matters a shit ton: "pause" does not feel like a good name for this, it's not a resource certainly, and barely a noun! I propose `signal_processing_pipeline`, where it makes a lot of sense for the actions to then be `/signal_processing_pipeline/pause` or `/signal_processing_pipeline/unpause`.

Related and worth checking every time: are the verbs consistent? A pair of sibling actions where one is PUT and one is POST for no reason is a finding.

**Conventions that recur.** These are ordinary good practice, and they are also what he actually writes:

- A retrieval function starts with a verb: `get_`, `fetch_`, `find_`. A function named for a noun should return that noun without side effects.
- Booleans read as predicates: `isProgrammatic`, not `programmatic`.
- Module-level constants are SCREAMING_SNAKE_CASE. A magic number inline is worse than a named constant, and a named constant with no explanation of *why that number* is barely better.
- Follow the codebase's existing pair conventions rather than inventing a new one. If the repo has `NotebookMinimalSerializer` and `NotebookSerializer`, the new pair is `ThingMinimalSerializer` and `ThingSerializer`.
- A `Raw` or `Internal` prefix on a type that is returned and consumed as-is is a smell: it implies a cooked version that does not exist, and it makes callers wonder what they are missing.
- A name ending in `Response` should be the whole response, not a fragment of one.
- Prefix names that would otherwise be ambiguous to the rest of the company. A generic `CoreMemory` viewset in a shared codebase leaves everyone guessing whose memory it is.
- Overloaded words in a large codebase (`filters`, `context`, `state`, `config`) need qualification, because the reader has met four other things with that name.

**Naming is not a nit when it is load-bearing.** A confusing internal variable is a nit. A public resource name, a tool name, or a type that other people will build against is worth blocking on, because it is the one thing that gets harder to change every day it exists.

**The capability-name match.** For an agent tool or a user-facing action, the name has to match what the thing can actually do. Michael blocked a PR precisely here: a tool called "Edit dashboard" that could rename and add insights but not remove them, edit filters, or change the description. Either narrow the name to the capability or widen the capability to the name.

## External surfaces: strict

External means consumers outside this codebase: REST and GraphQL APIs, MCP tools, webhooks, SDKs, emitted events, CLI flags, config file formats, anything a customer or another service touches.

- **Consistency with siblings first.** Read the neighbouring endpoints or tools before judging this one. Naming, casing, pluralization, pagination style, filter syntax, timestamp format, error envelope. Divergence from the local convention is the most common real finding here and the easiest to miss by reviewing the change in isolation.
- **Backwards compatibility.** Removing a field, tightening validation, changing a default, changing an error code, and narrowing an enum are all breaking even when the type checker is happy. Adding a required request field is breaking. Changing what an existing field means while keeping its name is the worst kind, because nothing fails loudly.
- **Required versus optional.** Every new required field is a compatibility cliff. Every optional field with an implicit default is a question about what old clients get.
- **Error shapes.** Does a failure produce something a caller can act on: a stable machine-readable code, and a message that says what to do? Is the status code right, in particular not returning 200 with an error body?
- **Pagination and limits.** Is a list endpoint bounded? Unbounded list endpoints are both a performance finding and a contract one, because the bound cannot be added later without breaking clients.
- **Idempotency.** Can a create be safely retried? If not, say so, because the caller will retry.
- **Discoverability.** For tool and SDK surfaces especially, the description and parameter docs *are* the interface, since they are what the consumer reads before calling. Vague or absent descriptions are a real finding, not documentation polish.
- **Versioning and deprecation.** If this breaks something, is there a version, a deprecation window, or at least an acknowledgement in the description?

## Internal surfaces: lenient

Internal means only this codebase and its agents will ever see it. Judge these gently. Michael's bar is deliberately lower here, because the cost of getting it slightly wrong is a later refactor rather than a broken consumer.

Flag only:

- Genuinely confusing shape: a function whose parameters can be passed in a combination that makes no sense, a return type that has to be interrogated to be understood, booleans at call sites that read as `do_thing(True, False, True)`.
- Gratuitous divergence from the conventions of the surrounding code, which costs every future reader.
- Shallow wrappers that add a layer without hiding anything.
- Leaking internals that will make the thing hard to change later, such as returning a raw ORM object or an internal enum through what is meant to be an abstraction boundary.

Do not flag naming taste, parameter ordering, or "I would have shaped this differently" on internal code.

## The test for which one it is

Ask who has to change if this changes. If the answer is "someone outside this repo, on their own schedule", it is external. If the answer is "this repo, in the same commit", it is internal. Anything reachable by a customer, a partner, a mobile app, or a saved integration is external, no matter what folder it lives in.
