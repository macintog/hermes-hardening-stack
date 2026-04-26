# Review R03 — Documentation drift review

You are reviewing whether the patch-stack documentation can safely guide a maintainer.

## Checklist

- Root README says what is canonical.
- Docs README lists all patches and phases.
- Intent doc states authority-containment model, not scanner-as-boundary.
- Surface map includes every changed model-visible ingress and side-effecting sink.
- Rebase playbook lists and regenerates every patch in `series`.
- Rebase playbook targeted tests include manifest-required tests.
- Verifier checks docs/manifest/series/test-list consistency.
- CI or manual workflow is clear.
- No contradictory statements remain, such as claiming no WeCom diff while manifest/tests include WeCom.
- Residual risks are explicit.

## Output

Return drift findings, exact files/sections to edit, and whether docs are handoff-safe.
