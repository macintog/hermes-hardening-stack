Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: integration and patch refresh

## Task

Integrate subagent work into the patch stack, regenerate patches, update metadata, and ensure the final bundle is coherent.

## Steps

1. Apply code/doc/test changes in the Hermes checkout and/or patch-stack repo as appropriate.
2. Decide whether each change belongs in an existing patch or a new patch.
3. Refresh patches from the intended base.
4. Update `series` if patch files changed or a new patch was added.
5. Update `manifest.yaml` owned paths, surfaces, required tests, smoke checks, imports, and consistency rules.
6. Update docs and playbook to match.
7. Run verifier.
8. Produce a file list and patch summary.

## Guardrails

- Never regenerate only a subset of mandatory patches unless intentionally removing a phase with explicit approval.
- Never let a passing verifier hide stale docs/playbook text if drift checks are part of acceptance.
- Preserve the repo’s purpose: downstream patch stack, not a vendored Hermes fork.
