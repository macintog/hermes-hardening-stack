# Source-of-truth notes for this prompt package

Review the live repository before acting; these notes are a starting point, not a substitute for inspection.

Expected current public state observed during package generation:

- Repository: `macintog/hermes-hardening-stack`
- Latest observed commit: `62d16af` with message `harden action registry and tool result promotion`
- Root README still describes the repo convention: `$HOME/.config/hermes-agent-patches`, canonical patch stack under `patches/hermes-safe-fetch-context/`, docs under `docs/customizations/hermes-safe-fetch-context/`.
- `series` includes five patches through `0005-tool-result-promotion-action-registry.patch`.
- `manifest.yaml` includes required phases for `registry_action_classification` and `tool_result_promotion_policy` mapped to `0005`.
- `REBASE_PLAYBOOK.md` was still observed with stale four-patch wording and a targeted test list that omitted `tests/security/test_tool_result_promotion.py`.
- docs README was still observed with stale two-intention/three-patch wording and stale WeCom wording.
- `SURFACE_MAP.md` was still observed without a dedicated patch `0005` section.
- `HARDENING_SURFACE_INVENTORY.md` documents multiple partially covered surfaces and also contains local path noise that should be sanitized.

Fresh session instruction: always re-check the repo first. If later commits already fix any item above, verify the fix and focus on remaining gaps.
