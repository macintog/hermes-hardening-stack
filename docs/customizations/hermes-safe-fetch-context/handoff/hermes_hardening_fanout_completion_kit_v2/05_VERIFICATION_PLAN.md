# Verification plan

## Baseline

From the patch-stack repo:

```bash
patch_repo=${HERMES_AGENT_PATCHES:-$HOME/.config/hermes-agent-patches}
```

From a Hermes checkout root:

```bash
"$patch_repo/scripts/verify-hermes-safe-fetch-context-stack.sh" "$PWD"
```

Against upstream main:

```bash
HERMES_BASE_REF=origin/main "$patch_repo/scripts/verify-hermes-safe-fetch-context-stack.sh" "$PWD"
```

## Required targeted tests

The verifier should derive these from `manifest.yaml`, but hand-run commands should include all of them:

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
  tests/security/test_tool_result_promotion.py
```

## New tests to add if missing

- `test_tool_string_output_defaults_to_untrusted`
- `test_trusted_internal_tool_output_requires_registry_metadata`
- `test_untrusted_turn_taint_blocks_outbound_message`
- `test_untrusted_turn_taint_blocks_terminal_execution`
- `test_browser_console_requires_confirmation_after_untrusted_context`
- `test_unknown_side_effect_tool_fails_closed_after_untrusted_context`
- `test_untrusted_skill_inline_shell_expansion_blocked_before_execution`
- `test_rebase_playbook_patch_list_matches_series`
- `test_rebase_playbook_targeted_tests_include_manifest_required_tests`

## Public verification summary format

Do not commit verbose local-path-heavy logs if a summarized report is sufficient. Prefer:

```text
verified_at: <timestamp>
patch_repo_commit: <sha>
hermes_base_ref: <ref-or-sha>
series:
  - ...
patch_apply: pass/fail
py_compile: pass/fail
imports: pass/fail
targeted_tests: <passed>/<skipped>/<failed>
warning_count: <n>
known_warning_classes:
  - ...
redactions:
  - absolute local worktree paths removed
residual_failures:
  - none / list
```
