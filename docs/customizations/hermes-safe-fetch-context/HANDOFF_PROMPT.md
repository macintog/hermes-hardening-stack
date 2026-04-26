# Maintainer handoff

Use this prompt when handing the customization to a fresh Hermes/Codex/Claude thread.

```
We maintain a downstream Hermes customization documented at:
  docs/customizations/hermes-safe-fetch-context/

The executable patch stack is at:
  patches/hermes-safe-fetch-context/

Mission:
  Re-apply and keep current the safe fetch + context safety customization while upstream Hermes changes frequently.

Read first:
  1. docs/customizations/hermes-safe-fetch-context/README.md
  2. docs/customizations/hermes-safe-fetch-context/INTENT.md
  3. docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md
  4. docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md
  5. patches/hermes-safe-fetch-context/series

Rules:
  - Preserve intent over exact line placement.
  - Keep patch 0001 about context promotion safety.
  - Keep patch 0002 about safe HTTP/gateway downloads.
  - Do not run npm install unless explicitly authorized.
  - If upstream has equivalent functionality, prefer it only if it preserves redirect validation, byte caps, URL redaction, structured context findings, and tests.
  - Refresh docs when surfaces move.

Done criteria:
  - Patches apply or have been refreshed cleanly.
  - Targeted tests in REBASE_PLAYBOOK.md pass, or failures are documented with root cause.
  - Patch stack applies in a fresh upstream worktree with git apply --check --3way.
  - SURFACE_MAP.md is still accurate.
```
