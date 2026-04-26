# Subagent 06: Implement Safe HTTP Slice

You are an implementation subagent for the first safe HTTP hardening slice.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- `/Users/ryand/playground/hermes-safe-fetch-context/DELEGATION_MATRIX.md`
- safe HTTP design spec from the master thread or `subagents/05-safe-http-design-spec.md`

Mission:
Implement the minimal shared safe HTTP helper and its unit tests. Do not migrate callers unless the master thread explicitly includes that in your task context.

Expected files:
- Create: `tools/safe_http.py`
- Create: `tests/tools/test_safe_http.py`

Required behavior:
- http/https only by default
- reject missing host
- reject URL userinfo by default
- use `tools.url_safety.is_safe_url` before request
- validate each redirect target
- enforce max redirects
- stream response bodies
- enforce max bytes during streaming
- check `Content-Length` when present
- support content-type allowlist
- support credential-bound origin mode
- do not forward Authorization across origin-changing redirects
- return structured result with sha256 and metadata
- redact sensitive URLs in error/log text

TDD steps:
1. Write failing tests first.
2. Run targeted tests and confirm failure.
3. Implement minimal code.
4. Run targeted tests and confirm pass.
5. Report exact commands and results.

Suggested tests:
- unsafe scheme blocked
- metadata/private target blocked via mocked `is_safe_url` or safe local parsing path
- redirect to blocked URL rejected
- redirect count exceeded
- oversized response rejected during streaming
- content-type mismatch rejected
- same-origin credential redirect allowed
- cross-origin credential redirect blocked
- returned sha256/bytes metadata is correct

Constraints:
- Do not make real network calls in tests.
- Do not install dependencies.
- Do not touch unrelated files.
- Do not modify provider tool-call schemas.
- Do not migrate multiple callers in this task.
- Preserve existing `tools/url_safety.py` behavior unless explicitly required by tests and approved by the master thread.

Deliverable:
- Summary of files changed.
- Tests added.
- Commands run and results.
- Any deviations from the design spec.
