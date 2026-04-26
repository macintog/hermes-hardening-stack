Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: safe HTTP, parser, and extraction risk

## Task

Review remote-byte ingress and post-download parsing/extraction risk. Separate what is implemented now from residual risk.

## Read/search

- `tools/safe_http.py`
- gateway download integrations
- document/PDF/OCR/transcript/STT extraction paths
- skill hub/community fetch paths
- tests in `tests/tools`, `tests/gateway`, `tests/security`

## Areas to assess

- DNS rebinding and connection-time IP validation.
- IPv4/IPv6 private/link-local/cloud-metadata blocking.
- proxy/environment-variable behavior.
- redirects with credentials/auth headers.
- content-length and streaming byte caps.
- content-type sniffing/allowlists.
- archive traversal and decompression bombs.
- parser timeouts/page/file/object limits.
- extracted text length limits and model-promotion taint.

## Output

- What can be fixed in this pass.
- What should remain documented as residual risk.
- Tests to add now versus future hardening.
