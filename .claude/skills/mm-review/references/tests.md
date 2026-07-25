# Tests

Judged in both directions: what is missing, and whether what is there earns its place. A test that cannot fail is worse than no test, because it buys false confidence.

## Grounding

- **Test Desiderata** (Kent Beck): tests should be isolated, composable, deterministic, fast, writable, readable, behavioral, structure-insensitive, automated, specific, predictive, inspiring. **Structure-insensitive** is the one that catches the most real problems: a test that breaks when you refactor without changing behavior is testing the implementation, not the behavior.
- ***Software Engineering at Google***, chapters 11 to 14. Test sizes (small, medium, large) and the pressure toward the smallest that catches the bug. Brittle tests as a maintenance tax that eventually gets paid by deleting them. The **Beyoncé Rule**: if you liked it, you should have put a test on it, meaning anything not covered is fair game to break.
- ***Working Effectively with Legacy Code*** (Michael Feathers). Characterization tests, and the definition of a unit test that excludes anything touching the database, the network, or the filesystem. Useful for naming what a "unit" test that spins up Postgres actually is.
- **The test pyramid, used as a cost argument** rather than a rule. The question is always: what is the cheapest level that would have caught this bug?

## Missing coverage

Name specific untested paths that carry real regression risk. Not a coverage percentage, and not "add more tests".

- The risky paths this change introduces, per the blast radius triage. A wide change with no test on the widened path is the finding.
- The bug being fixed: does a test exist that fails without the fix? A fix without a regression test invites the same fix again in six months. This is the single most valuable missing test to ask for.
- The edge cases the code visibly handles. If the code has a branch for empty input, there should be a test proving the branch does the right thing, or the branch is unverified.
- The failure paths. Error handling is the least tested and most trusted code in most repos.

Missing tests also drive the verdict's confidence tag. If a wide change is untested, your code reading is the only assurance the change has, and the report should say exactly that.

## Tests that do not earn their place

- **Tautological.** The test asserts what the implementation does by construction: mocking the thing under test, asserting a constant equals itself, asserting a mock was called with what the test just passed to it. It will never fail for a reason anyone cares about.
- **Structure-sensitive.** Asserting on private methods, internal call order, mock invocation counts, or the exact shape of an intermediate value. These break on every refactor and get deleted rather than fixed. Assert on the observable outcome through the public interface instead.
- **Near-duplicates.** Five tests differing only in an input value. That is one parameterized test, and the collapsed version is both cheaper and easier to extend.
- **Snapshot tests standing in for assertions.** A snapshot proves the output did not change, not that it was ever right. A large snapshot on a new feature usually means nobody stated what the correct output is.
- **Non-deterministic.** Depends on wall-clock time, random values, ordering that is not guaranteed, network access, or a sleep. A sleep in a test is both flakiness and wasted CI time, every run, forever.
- **Too large for the job.** An end-to-end test where a unit test would catch the same bug. Cost is paid on every run by everyone.
- **An eval that is really a test.** If the expected output is fully determined by the input, it is a test, and it belongs in the test suite where it runs faster and fails more clearly. See [llm-and-prompts.md](llm-and-prompts.md).

## Test changes that are themselves findings

- A test deleted or its assertions weakened as part of this change, without the description saying why. Sometimes correct, always worth surfacing.
- A test marked skipped, `xfail`, or excluded, especially near the code being changed.
- A timeout or retry raised to make something pass, which usually means the flake was renamed rather than fixed.
- A fixture broadened so much that the test no longer pins anything down.

## Reporting

Test findings are usually "worth knowing" rather than blockers. Promote to blocker when the untested path is the risky one, or when a test was quietly disabled to let the change through.

Keep the ask specific. "No test covers the retry path in `sync.py:88`, which is the part that can double-write" is actionable. "Needs more test coverage" is not.

If the repo has its own testing skill or a stated bar for when a test is worth writing, defer to it.
