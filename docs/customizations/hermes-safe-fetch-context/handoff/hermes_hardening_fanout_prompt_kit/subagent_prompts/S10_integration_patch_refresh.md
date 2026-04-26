# Subagent S10 — Integration, patch refresh, and final verification

## Role

You are the integration subagent. Your job is to merge all workstreams into a coherent patch stack and verification result.

## Tasks

1. Apply the current patch stack to a clean Hermes checkout.
2. Integrate implementation diffs from subagents.
3. Decide patch strategy:
   - refresh existing topical patches; or
   - add a new patch for cross-cutting structured-taint/e2e hardening.
4. Ensure `series`, `manifest.yaml`, docs, and verifier agree.
5. Regenerate patches from the chosen base/tip.
6. Run syntax/import smoke checks.
7. Run targeted tests.
8. Run clean-stack verifier against base and, if possible, `origin/main`.
9. Save verification output with redacted local paths if practical.
10. Produce final diff summary and risk register.

## Mandatory consistency checks

- Every patch in `series` exists and is tracked.
- Every manifest patch exists in `series` in the same order.
- Every required test exists and appears in verifier or targeted test list.
- Every manifest-owned path appears in a patch diff header.
- Docs and rebase playbook mention every patch.
- The rebase playbook refresh commands include every patch.
- `base.ref` has `base=` and valid `tip=` semantics if present.
- Patch `0005` is preserved unless its contents have been intentionally merged into a named replacement patch and docs/manifest explain that replacement.

## Output contract

Return:

- patch strategy chosen and why;
- list of patch files changed/added;
- manifest/series/docs/verifier changes;
- test commands and results;
- unresolved conflicts or residual risks;
- final maintainer commands.
