# Subagent 05: Safe HTTP Design Spec

You are a design subagent for the `tools/safe_http.py` implementation.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- `/Users/ryand/playground/hermes-safe-fetch-context/DELEGATION_MATRIX.md`

Prerequisites:
Use the outputs from the reconnaissance tracks if available. If not available, inspect only the minimal files needed: `tools/url_safety.py` and one likely first caller.

Mission:
Produce a concrete API and implementation/test specification for a shared safe HTTP downloader. This is design-only unless explicitly told otherwise. Do not modify files.

Design requirements:
- Use existing `tools/url_safety.py` for DNS/IP safety.
- Allow only `http` and `https` by default.
- Reject missing host and userinfo by default.
- Validate every redirect target before following.
- Enforce max redirect count.
- Stream responses and cap bytes while streaming.
- Check `Content-Length` if present.
- Support content-type allowlists.
- Support credential-bound downloads where Authorization must not cross origins.
- Return structured metadata: source URL, final URL, status, content type, content length, bytes read, sha256, body/path.
- Redact sensitive URL parts in logs/errors.

Deliverable:
A concrete spec with:
1. Proposed file path.
2. Dataclasses/exceptions/functions with signatures.
3. Redirect algorithm.
4. Credential-bound behavior.
5. Content-type/byte-limit behavior.
6. Logging/redaction behavior.
7. Exact test cases for `tests/tools/test_safe_http.py`.
8. Compatibility notes for first caller migration.

Constraints:
- Do not edit files.
- Do not make real network calls.
- Do not add heavy dependencies.
- Prefer httpx if the repo already uses it, but confirm from repo context.
