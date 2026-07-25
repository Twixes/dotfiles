# Security

Always on, but proportionate. A real security issue is a blocker every time. Security theater on a diff that touches nothing sensitive trains the reader to skim.

## Grounding

- **Saltzer and Schroeder's design principles** (1975, still the best list): least privilege, fail-safe defaults, complete mediation, economy of mechanism, open design, separation of privilege. Most findings in a code review are a violation of one of these, and naming which one makes the finding concrete rather than vibes.
- ***Threat Modeling*** (Adam Shostack), STRIDE: spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege. Useful as a fan-out axis when a diff genuinely opens a new surface.
- **OWASP Top 10 and ASVS.** The Top 10 as a reminder list, ASVS when a specific control needs a standard to point at.
- **"Never trust the client."** Any check that exists only in the frontend does not exist.

## Complete mediation, first

The highest-yield question in most codebases: is every newly reachable thing actually checked?

- Does a new endpoint, route, tool, or handler have authentication and authorization, or did it inherit only whatever the framework does by default? Verify rather than assume the base class covers it.
- **Tenant and scope isolation.** Does every new query filter by the tenant, org, project, or user boundary the rest of the code uses? A missing scope filter is a security finding, not a performance one, and it is the most common serious defect in a multi-tenant codebase. Watch especially for lookups by ID alone, which let a caller read another tenant's row by guessing.
- Object-level authorization: having access to the collection is not having access to the item.
- Does a permission check happen before the side effect, or after some of the work has already been done?

## Untrusted input

Trace where user-controlled data actually goes.

- SQL: parameterized, or string-built? Raw query builders and dynamic `ORDER BY` are where this hides, since the obvious cases are usually already safe.
- Shell and subprocess: any interpolation into a command line.
- File paths: traversal via `..`, absolute paths, symlinks.
- HTML: anything rendering user content without escaping, or a framework escape hatch such as a raw-HTML prop.
- Deserialization of user-supplied data with anything that can construct arbitrary objects.
- Template injection, where user input reaches a template string rather than a template variable.
- Redirects and outbound requests to user-supplied destinations (open redirect and SSRF). New outbound calls to a URL derived from input deserve a look at whether internal addresses are reachable.

## Secrets and exposure

- Credentials, tokens, or keys in code, in fixtures, in test files, or in a committed config.
- Secrets in logs, error messages, exception payloads, or telemetry. An exception handler that logs the full request body is the usual culprit.
- Over-broad serializers: a new field or a `fields = "__all__"` style change quietly exposing internal columns, other users' data, or a hashed password.
- Error responses that leak existence ("no such user" versus "wrong password") where that matters.

## Least privilege

- New credentials, roles, or scopes: is the grant the minimum, or is it whatever was easy?
- Does a new background job or service run with more access than its task needs?
- Does a new integration request permissions beyond what the feature uses?

## Supply chain

- New or bumped dependencies: is the package what it claims to be, is it maintained, does the name resemble a popular package, does it run install-time scripts.
- Lockfile changes without a matching manifest change, or vice versa.
- Anything adding a build step, hook, or CI action that executes third-party code.

## Reporting

Say which principle is violated and what an attacker actually gets. "Missing tenant filter on the new lookup, so any authenticated user can read another org's report by ID" is a finding. "Potential IDOR risk" is not.

If the repo has its own security skill or a scanner already covering an area, defer to it and say so rather than duplicating its output.
