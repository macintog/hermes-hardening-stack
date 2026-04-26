Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: verifier, CI, and drift checks

## Task

Strengthen verification so future maintainers cannot accidentally drop a mandatory hardening phase or trust stale docs.

## Read

- `scripts/verify-hermes-safe-fetch-context-stack.sh`
- `manifest.yaml`
- `series`
- `REBASE_PLAYBOOK.md`
- docs README and surface map
- verification-output directory
- `.github/workflows/` if present

## Required checks to consider

- `series` order equals manifest patch order.
- Every patch in `series` exists and is tracked.
- Every manifest-owned path appears in a patch diff header.
- Every manifest-required test appears in verifier targeted tests.
- Every manifest-required test appears in playbook targeted tests.
- Every `series` patch appears in playbook patch list and refresh `series` rewrite.
- `SURFACE_MAP.md` mentions each patch in `series`.
- Public verification summaries should not include avoidable local absolute paths.

## CI

If feasible, add a manual or scheduled GitHub Actions workflow that runs static consistency checks and documents how to run full clean-stack verification locally if upstream Hermes credentials/access are unavailable.

## Output

- Verifier changes.
- CI changes if any.
- Tests/static checks added.
- Residual gaps.
