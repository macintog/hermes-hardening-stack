# Verification plan

## Static checks

- Parse `series` and `manifest.yaml`; assert order and file existence match.
- Assert every manifest-owned path appears in a patch diff header.
- Assert every required test exists or is intentionally skipped with a reason.
- Assert docs mention every patch in `series`.
- Assert rebase playbook refresh commands regenerate every patch in `series`.
- Assert tool registry metadata is complete for every registered tool.
- Assert no missing security metadata defaults to allow for side-effecting tools.

## Smoke checks

- Compile all Python paths listed in manifest `owns` and `required_smoke_checks.py_compile`.
- Import core modules:
  - `agent.context_safety`
  - `agent.artifact_provenance`
  - `agent.action_authority`
  - `tools.safe_http`
  - `tools.customization_tool`

## Targeted tests

Run existing targeted tests plus new tests:

```bash
python -m pytest -o 'addopts=' -q \
  tests/agent/test_context_safety.py \
  tests/agent/test_memory_provider.py \
  tests/agent/test_prompt_builder.py \
  tests/cron/test_cron_context_from.py \
  tests/cron/test_cron_script.py \
  tests/tools/test_cronjob_tools.py \
  tests/tools/test_skills_tool.py \
  tests/tools/test_safe_http.py \
  tests/tools/test_customization_tool.py \
  tests/gateway/test_base_media_cache_safe_http.py \
  tests/gateway/test_discord_attachment_download.py \
  tests/gateway/test_feishu.py \
  tests/gateway/test_mattermost.py \
  tests/gateway/test_media_download_retry.py \
  tests/gateway/test_qqbot.py \
  tests/gateway/test_slack.py \
  tests/gateway/test_telegram_safe_image_download.py \
  tests/gateway/test_wecom.py \
  tests/security/test_context_promotion_boundaries.py \
  tests/security/test_safe_fetch_surfaces.py \
  tests/security/test_skill_plugin_boundaries.py \
  tests/security/test_artifact_provenance.py \
  tests/security/test_action_authority.py \
  tests/security/test_prompt_injection_containment.py \
  tests/security/test_tool_result_promotion.py \
  tests/security/test_structured_taint_authority.py \
  tests/security/test_hostile_download_e2e.py \
  tests/security/test_persistence_taint.py \
  tests/security/test_tool_registry_security_metadata.py
```

## Clean-stack verification

```bash
patch_repo=${HERMES_AGENT_PATCHES:-$HOME/.config/hermes-agent-patches}
"$patch_repo/scripts/verify-hermes-safe-fetch-context-stack.sh" /path/to/hermes
HERMES_BASE_REF=origin/main "$patch_repo/scripts/verify-hermes-safe-fetch-context-stack.sh" /path/to/hermes
```

## Red-team acceptance

For each attack chain, answer:

1. What untrusted source introduced the attacker instruction?
2. How was it tainted or fenced before model visibility?
3. Which deterministic gate blocked or required scoped confirmation?
4. Which test proves this?
5. What residual bypass remains?
