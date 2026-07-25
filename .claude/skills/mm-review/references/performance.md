# Performance

Mostly queries. It is easy to add a query and hard to keep the query count and the indexes in check, so that is where the attention goes.

## Grounding

- ***SQL Performance Explained*** and **Use The Index, Luke!** (Markus Winand). The central idea: an index is only useful if its leading columns match the query's predicates, in order. A new filter or sort without a supporting index is not "maybe slow later", it is a full scan now. Also that `LIKE '%x'` and functions applied to indexed columns silently disable the index.
- **Knuth, in full.** "We should forget about small efficiencies, say about 97% of the time: premature optimization is the root of all evil. Yet we should not pass up our opportunities in that critical 3%." Both halves matter. Do not flag micro-inefficiency; do flag the critical path.
- ***Release It!*** (Nygard) on unbounded result sets, which is the failure that looks fine in development and takes production down when one row count grows.
- **N+1**, the name for the single most common finding in this file.

## Query count

Count the queries one request issues after this change. Count, do not estimate.

- Queries inside a loop. The classic N+1, and it hides well inside a serializer, a template, a property accessor, a permission check, or a `__str__`.
- Lazy relation access on a collection that was fetched without prefetching or joining.
- A helper that looks like a cheap lookup and is not, called once per item.
- Permission or feature-flag checks evaluated per row rather than once.

An N+1 in a path handling a handful of items is a nit. The same N+1 in a list endpoint with no upper bound is a blocker. Say which it is, and on what basis.

## Indexes

For every new or changed filter, join, sort, or uniqueness constraint, name the index that serves it or state that there is none.

- Does the index's leading column match the most selective predicate, and does the column order match how the query filters and sorts?
- Does an `ORDER BY` have index support, or will it sort the whole result set?
- Is the predicate index-eligible at all, or does a function, a cast, or a leading wildcard defeat it?
- Is a new index redundant with an existing one whose prefix already covers it? Extra indexes are not free: they cost every write.
- Index creation on a large table is a migration concern too. See [data-and-deploys.md](data-and-deploys.md).

## Bounds

- Is any result set unbounded? Not "is it usually small", but is there a limit in the code.
- What does this do at the largest realistic size rather than the fixture size? The honest answer is often "I do not know the real cardinality", which belongs in the confidence line, not in silence.
- Does anything load a full table or a full collection into memory to filter it in application code, when the store could have filtered it?

## Work in the wrong place

- Synchronous work in a request path that belongs in a background job: external calls, large aggregations, file or image processing, sending mail.
- Work per row that could be done once: recompiling a regex, reopening a connection, re-reading config, re-deriving a constant.
- Work done eagerly that is rarely needed, especially expensive computation for a field most callers do not read.
- Repeated identical queries inside one request, which is the case where caching is genuinely warranted rather than speculative.

## Calibration

Separate what will be felt from what is theoretical, and say which is which. An extra millisecond in a rarely hit admin path is not a finding. A new unindexed filter on the main list view is.

Where a claim about size or traffic decides whether something matters, and the repo cannot settle it, check the product data if it is reachable. Otherwise put the open question in the confidence line rather than guessing in either direction.
