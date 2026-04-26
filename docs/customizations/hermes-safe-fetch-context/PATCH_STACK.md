# Patch stack notes

This patch stack is meant to be small, reviewable, and portable across frequent Hermes upstream changes.

## Files

`series` lists patch order:

1. `0001-context-safety-core.patch`
2. `0002-safe-http-gateway-download-hardening.patch`
3. `0003-customization-maintenance-tool.patch`

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
- downstream-owned `tools/safe_http.py` and `tests/tools/test_safe_http.py`
- URL/host validation
- redirect validation
- streaming byte caps
- URL redaction
- gateway downloader call-site migrations

Current 0002 is self-contained and includes the safe HTTP helper plus the gateway files/tests listed in `SURFACE_MAP.md`. It does not currently include WeCom; if WeCom remains downstream-owned in a future refresh, add `gateway/platforms/wecom.py` and `tests/gateway/test_wecom.py` to 0002 rather than leaving that migration implicit in planning docs.

This patch should remain independent of prompt/context scanning.

### Patch 0003: customization maintenance tool

Owns the reusable guardrail for this recurring downstream-maintenance pattern:
- `tools/customization_tool.py`
- `tests/tools/test_customization_tool.py`
- `toolsets.py` registration for the `customizations` toolset

This patch should stay focused on inspecting/auditing patch-stack repos. It should not contain project-specific safe-fetch logic.

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
