# Backlog and priority plan

## P0: fix handoff hazards

1. Fix `REBASE_PLAYBOOK.md` so it cannot regenerate a four-patch stack by accident.
2. Fix docs README to describe the five-patch/five-phase stack.
3. Add patch `0005` to `SURFACE_MAP.md`.
4. Include `tests/security/test_tool_result_promotion.py` in every targeted test list.
5. Add verifier/doc drift checks if feasible.

## P1: complete the security methodology

1. Implement structured turn/session taint or the closest viable deterministic authority signal.
2. Make string tool outputs untrusted by default.
3. Require explicit registry metadata for trusted internal control output.
4. Classify browser-console/browser-context capabilities as credentialed/sensitive.
5. Gate or disable inline shell expansion for untrusted skill/plugin/community content.
6. Ensure memory/cron/persistence paths preserve untrusted provenance.

## P2: broaden coverage and clean up auditability

1. Add adversarial tests for gateway-native transcripts/OCR/doc outputs that may bypass normal tool-result promotion.
2. Add plugin injected-message policy or residual-risk documentation.
3. Add lower-level safe HTTP/parser/extraction tests for DNS rebinding, proxies, cloud metadata, decompression bombs, archive traversal, and content-type sniffing where feasible.
4. Sanitize verification logs and avoid local path noise in tracked docs.
5. Add scheduled/manual CI for stack verification if feasible without assuming unavailable private upstream credentials.

## Defer only with explicit residual risk

If any P1 item cannot be implemented in one session, document:

- exact file/function inspected;
- why implementation was not possible;
- current compensating control;
- test or code change needed next.
