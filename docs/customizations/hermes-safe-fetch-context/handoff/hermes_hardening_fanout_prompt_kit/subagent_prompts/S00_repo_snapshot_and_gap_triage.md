# Subagent S00 — Repository snapshot and gap triage

## Role

You are the repo-state and drift triage subagent. Your job is to produce a precise snapshot of `macintog/hermes-hardening-stack` before implementation begins.

## Inputs

Read:

```text
README.md
patches/hermes-safe-fetch-context/series
patches/hermes-safe-fetch-context/manifest.yaml
patches/hermes-safe-fetch-context/base.ref
patches/hermes-safe-fetch-context/*.patch
docs/customizations/hermes-safe-fetch-context/*.md
scripts/verify-hermes-safe-fetch-context-stack.sh
verification-output/*.log
```

## Tasks

1. Record the exact patch order, base ref, manifest phases, required tests, and owned paths.
2. Identify every inconsistency among `series`, `manifest.yaml`, docs, verifier, and playbook.
3. Confirm whether docs mention all patches, especially `0005-tool-result-promotion-action-registry.patch`.
4. Check whether the rebase playbook refreshes every patch in `series`.
5. Check whether the targeted test list includes every manifest-required test.
6. Check whether WeCom and other gateway surfaces are consistently documented.
7. Check verification logs for warning volume, local-path leakage, and whether base/upstream verification passed.
8. Produce a minimal set of repo-maintenance fixes that should be made regardless of deeper code work.

## Output contract

Return a report with these sections:

- Patch order and base-ref snapshot.
- Manifest phases and required tests.
- Drift findings, each with severity and file/line if available.
- Minimal fixes.
- Questions for implementation subagents.

Do not make broad security recommendations; focus on factual repo consistency.
