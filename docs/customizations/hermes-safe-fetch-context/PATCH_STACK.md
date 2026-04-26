# Patch stack notes

This patch stack is meant to be small, reviewable, and portable across frequent Hermes upstream changes.

## Files

`series` lists patch order:

1. `0001-context-safety-core.patch`
2. `0002-safe-http-gateway-download-hardening.patch`

`base.ref` records the upstream-ish base and captured tip used to generate the current patches.

## Why two patches?

The two concerns are related but independently maintainable.

### Patch 0001: context safety core

Owns text/context promotion safety:
- scanner data model
- suspicious context findings
- untrusted context rendering
- prompt-builder integration
- memory provider integration
- cron prompt/script/context integration
- skill view/reporting integration

This patch should remain independent of gateway/media fetching.

### Patch 0002: safe HTTP gateway download hardening

Owns network fetch/download safety:
- URL/host validation
- redirect validation
- streaming byte caps
- URL redaction
- gateway downloader call-site migrations

This patch should remain independent of prompt/context scanning.

## Why not one giant patch?

Hermes changes frequently. Smaller patches make it easier to tell whether a failure is:
- prompt/context movement
- gateway/platform movement
- central safe HTTP policy drift
- central scanner policy drift

## Why not only docs?

The full customization commit is useful evidence, but future maintenance needs exact diffs that can be applied and refreshed. Docs explain intent; patches preserve executable change.

## Why not only patches?

Patches alone rot into archaeology. The docs tell a future maintainer what to preserve when upstream code moves or supersedes local code.

## Updating the stack

Use `REBASE_PLAYBOOK.md`. After updating, keep these files in sync:
- `patches/hermes-safe-fetch-context/*.patch`
- `patches/hermes-safe-fetch-context/base.ref`
- `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
- this file, if patch order or responsibilities change
