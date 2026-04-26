# Final deliverable template

## Summary

State the security outcome in one paragraph. Avoid claiming complete prompt-injection prevention unless deterministic invariants justify it.

## Changed files

### Patch-stack repo

- `patches/hermes-safe-fetch-context/series`
- `patches/hermes-safe-fetch-context/manifest.yaml`
- patch files changed or added
- docs changed
- verifier/CI changed

### Hermes target files

List target files touched by the patch stack.

## Security invariants implemented

For each invariant, state:

- implemented: yes/no/partial;
- code paths;
- tests;
- residual risk.

## Tests run

Paste commands and results. If not run, say exactly why and what remains to be run.

## Residual risk register

Use `templates/risk_register_template.md`.

## Maintainer commands

Provide exact commands to apply, verify, refresh, and inspect the patch stack.

## Rebase notes

Explain any upstream movement, patch split changes, or new docs requirements.
