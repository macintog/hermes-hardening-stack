# Upstream Alignment Public Validation

Status: PASS for the local payload verifier. ATTENTION for already-published public commit metadata.

## Payload Identity

- Payload base ref: `7b12753948acc373dab31eca481c3b8e6a6329ea`
- Upstream ref observed by verifier: `origin/main`
- Upstream commit observed by verifier: `e670d9cdd6697d24c4b170ac0ecdf6d344dc96a7`
- Series count: `108`
- Required test count: `55`
- Series SHA-256: `e160e753f674befc458d45810f4da075ea3f4da02650897cba309982b2907253`
- Manifest SHA-256: `aaa489380ad5c6fbf5bfdff35b6a79da8a16001535f4f201a17ec9b19799f2ab`
- Sorted patch-bundle SHA-256: `b0a8ffe17aa3921615f28d2fad478521925d136333a9979d0088c420aa51b745`

## Verifier Command Shape

```bash
PYTHON=<managed-hermes-python> HERMES_CHECKOUT=<hermes-checkout> ./scripts/verify-hermes-safe-fetch-context-payload.sh <hermes-checkout>
```

Local workstation paths are intentionally redacted from this public-safe artifact.

## Result

- Payload input, manifest, series, and patch target/base-ref checks passed.
- `py_compile` smoke passed for `106` files.
- Import smoke passed.
- Action-authority contract checks passed: `10` checks.
- Targeted tests passed: `2456 passed, 1 skipped, 164 warnings`.
- Strict evidence-ledger validation passed: `6 passed`.
- Public-sample prompt-injection checks passed: `sample_count=8`, `ux_regression_count=14`, `failure_count=0`.
- Final verifier status: `passed`.

## Commit Metadata Note

The previous public snapshot tip `fdb27d58c0553d80120f5e81f7da3df75f261d60` contains a local machine path in its commit message validation command. Tree scrubbing did not scrub commit metadata, and this artifact does not claim otherwise.

This pass did not rewrite or replace public history. A future public publish should replace or rewrite the public snapshot commit if the public branch must be metadata-clean. The public route checker now inspects the public snapshot tip commit message so this leak class is caught before later publication.
