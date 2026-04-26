# Hermes safe fetch + context safety customization

This directory documents the downstream customization currently carried outside Hermes proper.

Goal: keep the customization understandable and portable while upstream Hermes changes frequently.

Current shape:
- Patch stack: `patches/hermes-safe-fetch-context/`
- Series file: `patches/hermes-safe-fetch-context/series`
- Base reference: `patches/hermes-safe-fetch-context/base.ref`
- Intent docs: this directory

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
- `0002-safe-http-gateway-download-hardening.patch`: `tools/safe_http.py` plus gateway downloader integrations and tests.

Preferred maintenance model:
1. Update Hermes upstream normally.
2. Re-apply this patch stack in order.
3. If a patch fails, use `SURFACE_MAP.md` to find the new upstream equivalent surface.
4. Preserve intention first; do not mechanically preserve old line placements.
5. Refresh patches from the repaired working tree.
6. Run the verification commands in `REBASE_PLAYBOOK.md`.

Do not treat the full `gitprime/hermes-agent-customizations` repository as the source of truth for intent. It is a capture of a full Hermes checkout. The durable source of truth should be this documentation plus the patch stack.
