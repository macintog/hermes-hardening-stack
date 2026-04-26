Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: repo state and drift baseline

## Task

Establish the exact current state of the patch stack and identify drift between executable artifacts and human docs.

## Read

- root `README.md`
- `patches/hermes-safe-fetch-context/series`
- `manifest.yaml`
- `base.ref`
- all patch files in `series`
- docs under `docs/customizations/hermes-safe-fetch-context/`
- `scripts/verify-hermes-safe-fetch-context-stack.sh`
- verification logs if present

## Questions to answer

1. What is the current commit SHA?
2. What exact patches are listed in `series`?
3. Does `manifest.yaml` match `series` exactly?
4. Which docs mention an obsolete patch count, omit `0005`, omit tests, or contradict the manifest?
5. Are there local absolute paths, user identifiers, or noisy logs in tracked docs/logs?
6. Which verifier checks already catch drift, and which do not?

## Output

Produce:

- patch/doc/test drift matrix;
- exact stale passages or sections to change;
- recommended file edits;
- tests/verifier checks that should fail before fixes and pass after fixes.
