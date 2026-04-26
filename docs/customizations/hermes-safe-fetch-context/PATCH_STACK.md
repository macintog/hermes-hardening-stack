# Patch stack notes

This patch stack is meant to be small, reviewable, and portable across frequent Hermes upstream changes.

## Files

`series` lists patch order:

1. `0001-context-safety-core.patch`
2. `0002-safe-http-gateway-download-hardening.patch`
3. `0003-customization-maintenance-tool.patch`
4. `0004-provenance-action-authority-hardening.patch`
5. `0005-tool-result-promotion-action-registry.patch`

`base.ref` records `base=`, the clean upstream commit the stack applies to. `tip=`, if present, must be the actual patched Hermes commit whose diff against `base=` generated the stack. If the stack is generated from working-tree diffs rather than a committed patched tree, omit `tip=`; the verifier rejects `base == tip` when patches are non-empty.

## Why five patches?

The concerns are related but independently maintainable.

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

Current 0002 is self-contained and includes the safe HTTP helper plus the gateway files/tests listed in `SURFACE_MAP.md`, including WeCom coverage.

This patch should remain independent of prompt/context scanning.

### Patch 0003: customization maintenance tool

Owns the reusable guardrail for this recurring downstream-maintenance pattern:
- `tools/customization_tool.py`
- `tests/tools/test_customization_tool.py`
- `toolsets.py` registration for the `customizations` toolset

This patch should stay focused on inspecting/auditing patch-stack repos. It should not contain project-specific safe-fetch logic.

### Patch 0004: provenance/action-authority hardening

Owns taint/provenance labels and explicit action-authority gates:
- `agent/artifact_provenance.py`
- `agent/action_authority.py`
- `model_tools.py` and `run_agent.py` integration
- `HARDENING_SURFACE_INVENTORY.md`
- security tests for artifact provenance, action authority, and prompt-injection containment

This patch should remain independent of gateway downloader migrations and the customization-maintenance tool.

### Patch 0005: tool-result promotion and registry classification

Owns the follow-up containment boundary for derived hostile text and unknown tools:
- complete built-in registered-tool action classification
- default confirmation for unknown side-effect behavior
- taint-loss regression tests for downloaded text, gateway attachment text, browser snapshots, recalled/session-search output, cron output, and skill README instructions
- model-visible string tool-result fencing by default, with only explicitly trusted internal agent-loop control output preserving raw shape
- agent-loop propagation of prior model-visible tool/evidence text into the action-authority gate, plus deterministic checks that concrete side-effect targets/args copied from evidence-only content are not authorized by vague trusted requests

This patch builds on 0004 and should stay focused on tool-result promotion plus action-classification coverage. Do not re-introduce a targeted-only result-fencing policy unless an equivalent registry-backed output-trust metadata layer is added and verified.

## Why not one giant patch?

Hermes changes frequently. Smaller patches make it easier to tell whether a failure is:
- prompt/context movement
- gateway/platform movement
- central safe HTTP policy drift
- central scanner policy drift
- provenance/action-authority enforcement drift
- tool-result promotion / registry classification drift

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
