# Verification log summary template

## Environment

- Patch repo commit:
- Hermes base ref:
- Hermes patched tip:
- Python version:
- Date/time:

## Commands

```bash
# paste exact commands
```

## Results

| Check | Result | Notes |
|---|---|---|
| Patch apply | Pass/Fail | |
| Manifest/series consistency | Pass/Fail | |
| Docs drift checks | Pass/Fail | |
| Py compile | Pass/Fail | |
| Imports | Pass/Fail | |
| Targeted tests | Pass/Fail | |
| Clean-base verifier | Pass/Fail | |
| origin/main verifier | Pass/Fail | |

## Warnings

Summarize warning classes and counts. Redact local user paths where practical.

## Failures

For each failure: root cause, fix status, and owner.
