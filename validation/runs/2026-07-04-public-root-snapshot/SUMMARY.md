# Public Root Snapshot Reproducibility Summary

Status: PASS for the recorded public snapshot route check. ATTENTION for workflow proof, because no workflow-run proof was recorded in this repo.

## Snapshot Identity

- Public root snapshot commit: `db5646b2ec21caebfea6a634e7bf630cd4149a29`
- Payload base ref: `7b12753948acc373dab31eca481c3b8e6a6329ea`
- Series SHA-256: `e160e753f674befc458d45810f4da075ea3f4da02650897cba309982b2907253`
- Manifest SHA-256: `aaa489380ad5c6fbf5bfdff35b6a79da8a16001535f4f201a17ec9b19799f2ab`

## Reproducible Verifier Command Shape

```bash
PYTHON=<managed-hermes-python> HERMES_CHECKOUT=<hermes-checkout> ./scripts/verify-hermes-safe-fetch-context-payload.sh <hermes-checkout>
```

Use a clean Hermes checkout at the payload base ref and a managed Python environment for that checkout. Workstation-specific paths are intentionally omitted from this public-safe artifact.

## Recorded Results

- Source verifier result: not rerun for this public snapshot summary.
- Public sample result: not rerun for this public snapshot summary; the latest public-safe verifier summary records `failure_count=0`.
- PII/local-path scan result: `PASS` from `scripts/codex-hermes-git-routing check-public --ref codex/public-publish-59c9690`.
- Workflow status: no workflow-run proof was recorded in this repo for commit `db5646b2ec21caebfea6a634e7bf630cd4149a29`.

## Public-Safe Evidence Boundary

This summary records reproducibility metadata for the public root snapshot. It does not claim private authoring-tree verifier counts as public workflow evidence.
