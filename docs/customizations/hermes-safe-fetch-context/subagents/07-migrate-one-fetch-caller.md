# Subagent 07: Migrate One Fetch Caller

You are an implementation subagent for migrating exactly one Hermes remote-download caller to `tools/safe_http.py`.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- `/Users/ryand/playground/hermes-safe-fetch-context/DELEGATION_MATRIX.md`

Prerequisites:
- `tools/safe_http.py` exists and has passing unit tests.
- The master thread will specify the exact caller to migrate. If not specified, recommend one and stop rather than editing multiple paths.

Mission:
Migrate one contained fetch/download function to use safe_http while preserving caller-facing behavior.

Likely first candidates:
- `gateway/platforms/wecom.py::_download_remote_bytes`
- `gateway/platforms/feishu.py::_download_remote_document`

Rules:
- Migrate exactly one caller.
- Preserve return shape and exceptions as much as practical.
- Preserve existing max_bytes behavior if present.
- Add or update targeted tests for that caller.
- Do not opportunistically refactor neighboring code.

Security requirements:
- unsafe initial URL blocked
- redirect to private/metadata/internal target blocked
- max bytes enforced
- content-type behavior preserved or tightened only if the caller already has a clear expected type
- credential-bearing redirects protected if this caller sends auth headers

TDD steps:
1. Write or update a failing test for redirect/private-target behavior or oversized response.
2. Run targeted test and confirm failure.
3. Update the caller to use `safe_http`.
4. Run targeted tests and confirm pass.
5. Run `tests/tools/test_safe_http.py` again to ensure no regression.

Constraints:
- Do not migrate more than one caller.
- Do not touch unrelated platform adapters.
- Do not change user-visible behavior except blocking unsafe fetches.
- Do not install dependencies.
- Avoid real network calls in tests.

Deliverable:
- Caller migrated.
- Tests added/updated.
- Commands run and results.
- Any behavior changes explicitly listed.
