# Acceptance criteria

The work is complete only when all criteria below are either satisfied or explicitly listed as residual risk with a reason.

## Repository and handoff criteria

- `patches/hermes-safe-fetch-context/series` and `manifest.yaml` agree exactly on patch order.
- Every mandatory phase in the manifest maps to a patch in `series`.
- `REBASE_PLAYBOOK.md` lists every patch in `series`.
- The playbook refresh procedure regenerates every patch in `series` and rewrites `series` with the full list.
- The playbook targeted test command includes every manifest-required test, especially `tests/security/test_tool_result_promotion.py`.
- `docs/.../README.md` describes the actual current stack and no longer presents the hardening as only two intentions or three patches.
- `SURFACE_MAP.md` includes patch `0005` and any new patches added in this session.
- No doc states that WeCom is absent from `0002` if `manifest.yaml` and patch `0002` include WeCom paths/tests.

## Security criteria

- Hostile downloaded/extracted/tool-derived content is never treated as trusted authority solely because it appears in a user-visible/tool-visible text block.
- Model-visible string tool outputs are untrusted by default unless metadata explicitly marks them trusted internal control output.
- Side-effecting tools require trusted scoped authorization when the current turn has been influenced by untrusted content.
- Unknown side-effecting tools fail closed or require confirmation; they do not silently proceed.
- Browser console or browser-context tools are not classified as ordinary read-only fetches when they can inspect or affect a credentialed session.
- Skill/plugin content cannot trigger inline shell expansion before trust/provenance and authority checks.
- Persisted untrusted-derived content remains tainted on recall.

## Test criteria

Add or update deterministic tests for:

- playbook/docs/manifest/series drift or verifier-level consistency;
- `0005` preservation in refresh paths, where practical;
- default-untrusted tool result strings;
- trusted internal control-output exemption;
- structured or equivalent turn taint blocking side effects;
- browser console/credentialed context classification;
- skill inline shell gating/order;
- unknown tool action classification fail-closed behavior.

## Verification criteria

- The clean-base verifier applies the full stack without silently dropping patches.
- The verifier compiles all manifest-owned Python paths.
- The verifier imports core modules.
- The verifier runs all manifest-required targeted tests.
- Verification output is summarized and path-sanitized for public handoff where practical.

## Claim criteria

Use cautious language unless all security invariants are structurally enforced:

- Acceptable: “hostile-content containment,” “untrusted evidence boundary,” “deterministic action-authority gate.”
- Not acceptable unless proven: “prevents all prompt injection.”
