# Hermes safe fetch + context safety customization

This directory documents the downstream customization currently carried outside Hermes proper.


Canonical location:
- Local: `$HOME/.config/hermes-agent-patches`
- Remote: the configured `origin` remote (see `git remote -v`)
- Hermes config pointer: `~/.hermes/config.yaml` → `customizations.hermes_agent_patches`

Canonical sources for this customization:
- Patch order: `patches/hermes-safe-fetch-context/series`
- Machine-readable manifest: `patches/hermes-safe-fetch-context/manifest.yaml`
- Clean-base verifier: `scripts/verify-hermes-safe-fetch-context-stack.sh`
- Executable patch payloads: `patches/hermes-safe-fetch-context/*.patch`
- This docs directory is explanatory/maintenance guidance only and must not override the series, manifest, verifier, or patch files.

Goal: keep the customization understandable and portable while upstream Hermes changes frequently.

Current shape:
- Patch stack: `patches/hermes-safe-fetch-context/`
- Series file: `patches/hermes-safe-fetch-context/series`
- Manifest: `patches/hermes-safe-fetch-context/manifest.yaml`
- Base reference: `patches/hermes-safe-fetch-context/base.ref`
- Verification script: `scripts/verify-hermes-safe-fetch-context-stack.sh`
- Intent docs: this directory, explanatory only

The customization has two separable intentions:

1. Safe HTTP download boundary
   - Centralize URL validation and redirect validation for gateway/media downloads.
   - Block private/internal/link-local/loopback targets before fetching and on redirects.
   - Enforce explicit byte caps at call sites.
   - Redact sensitive URLs in logs/errors.

2. Context safety boundary
   - Centralize scanning of text that is promoted into privileged prompt/context slots.
   - Preserve raw external content as quoted/fenced data where possible.
   - Return structured findings so callers can block, warn, or report consistently.
   - Avoid broad ad hoc pattern copies across tools.

This is not intended to fork Hermes behavior broadly. It is a narrow hardening layer around:
- untrusted network fetches entering local cache/tool flows
- untrusted text entering prompt-like context surfaces

Patch files:
- `0001-context-safety-core.patch`: `agent/context_safety.py` plus memory, prompt-builder, cron, and skill/cron tool integrations and tests.
- `0002-safe-http-gateway-download-hardening.patch`: downstream-owned `tools/safe_http.py`, `tests/tools/test_safe_http.py`, gateway downloader integrations, related gateway tests, and current WeCom hardening for `gateway/platforms/wecom.py` plus `tests/gateway/test_wecom.py`.
- `0003-customization-maintenance-tool.patch`: `tools/customization_tool.py` and tests for auditing downstream patch-stack repos as this pattern repeats.
- `0004-provenance-action-authority-hardening.patch`: artifact provenance, taint/quarantine metadata, action-authority gating, and deterministic containment tests.
- `0005-tool-result-promotion-action-registry.patch`: mandatory tool-result-promotion and action-registry hardening, including default fencing for model-visible string tool outputs, prior tool-result taint propagation into the agent-loop action gate, scoped argument/target checks for evidence-derived side effects, unknown side-effect confirmation, and `tests/security/test_tool_result_promotion.py`.

Preferred maintenance model:
1. Update Hermes upstream normally.
2. Re-apply this patch stack in order.
3. If a patch fails, use `SURFACE_MAP.md` to find the new upstream equivalent surface.
4. Preserve intention first; do not mechanically preserve old line placements.
5. Refresh patches from the repaired working tree.
6. Run the verification commands in `REBASE_PLAYBOOK.md`.

Do not treat the old full-Hermes customizations clone repository as the source of truth for intent. It is a capture of a full Hermes checkout. The durable canonical sources are `patches/hermes-safe-fetch-context/series`, `patches/hermes-safe-fetch-context/manifest.yaml`, `scripts/verify-hermes-safe-fetch-context-stack.sh`, and the executable patch files; this documentation is explanatory only.
