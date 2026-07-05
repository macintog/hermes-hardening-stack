# Surface map

This maps the implementation to the Hermes files it changes.

## Context safety core

### Core module

Current file:
- `agent/context_safety.py`

Purpose:
- define context surfaces
- scan untrusted text for prompt-injection, hidden text, path/script injection, and secret-exfil patterns
- return structured findings
- render untrusted context blocks with metadata
- provide shared scanner behavior for prompt/context files, cron prompts, tool results, memory, skills, and extracted text

Search hints:
- search for prompt/context safety helpers
- keep a single shared scanner rather than per-tool regex copies

### Prompt/context file ingestion

Current file:
- `agent/prompt_builder.py`

Current intent:
- use `scan_context_text(...)` for context files promoted into prompt context
- render allowed context files as untrusted evidence-only context rather than higher-priority instructions
- convert structured scanner result into caller-visible blocking/error behavior where required
- cover prompt override, deception, hidden HTML, translate-and-execute, secret read, and exfiltration patterns in context-file tests

Search hints:
- search for `SOUL.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `_scan_context_content`, or prompt context file loading

### Memory provider context

Current file:
- `agent/memory_manager.py`

Current status:
- memory remains an in-scope hostile-context surface, and the May 31 series patches `agent/memory_manager.py`
- upstream memory prefetch output is still wrapped in `<memory-context>` and nested memory fences are stripped
- memory provider `system_prompt_block()` output is rendered as untrusted memory-context evidence before it reaches provider-facing system prompt text
- `agent/context_safety.py` defines `ContextSurface.MEMORY_CONTEXT`, and model-visible `session_search`-like tool results are fenced through the tool-result promotion path

Search hints:
- search for `build_memory_context_block`, memory provider context rendering, `MEMORY.md`, or `USER.md`

### Cron prompt/script output context

Current files:
- `cron/scheduler.py`
- `tools/cronjob_tools.py`

Current intent:
- scan cron prompts before saving/scheduling with the shared context scanner
- cover prompt override, deception, secret exfiltration, secret reads, SSH persistence, sudoers edits, destructive root removal, and invisible Unicode in cron prompt tests
- render cron pre-run script output and upstream job context as untrusted data when building job prompts


Search hints:
- search for `_build_job_prompt`, `context_from`, `prerun_script`, `cronjob`, or cron prompt validation

### Skill view/install surfaces

Current file:
- `tools/skills_tool.py`

Current intent:
- scan skill content served into the conversation
- expose `context_safety` and `context_safety_findings` fields in tool output
- distinguish provenance where possible: builtin/local/plugin/hub/external
- ensure external/community/plugin skill content is evidence-only for action decisions; it cannot authorize installs, memory writes, cron changes, outbound messages, file writes, or execution without trusted user/system/developer intent through the action-authority gate

Search hints:
- search for `skill_view`, `_serve_plugin_skill`, skill content serialization, hub install/audit logic

## Safe HTTP and gateway download hardening

### Core module

Current file:
- `tools/safe_http.py`

Purpose:
- validate URL scheme and resolved hosts
- block loopback/private/link-local/internal IPs
- validate each redirect before following
- enforce max byte count during streaming
- redact URLs for logs
- return structured download result metadata

Search hints:
- search for URL safety helpers, SSRF guards, browser URL blocklist, or download utilities
- keep redirect validation explicit

### Base gateway media cache

Current file:
- `gateway/platforms/base.py`

Current intent:
- `cache_image_from_url` and `cache_audio_from_url` use `safe_download_bytes`
- preserve retry behavior
- enforce media byte caps

Search hints:
- search for `cache_image_from_url`, `cache_audio_from_url`, `IMAGE_CACHE_DIR`, `AUDIO_CACHE_DIR`


### BlueBubbles

Current file:
- `gateway/platforms/bluebubbles.py`

Current intent:
- use `safe_download_bytes` for BlueBubbles attachment/media URLs
- preserve configured/private BlueBubbles server origins through narrow allowed-private-origin policy
- enforce explicit attachment byte caps and URL redaction

Search hints:
- search for BlueBubbles attachment download helpers, `safe_download_bytes`, and `MAX_ATTACHMENT_DOWNLOAD_BYTES`

### Discord

Current file:
- `plugins/platforms/discord/adapter.py`

Current intent:
- use safe fallback downloader for images/media/attachments
- preserve Discord SDK primary path where applicable
- block/redact unsafe fallback URLs
- enforce media/attachment byte caps

Search hints:
- search for Discord attachment download fallback, `attachment.url`, `proxy_url`, `to_file`, image/audio attachment handling

### Slack

Current file:
- `plugins/platforms/slack/adapter.py`

Current intent:
- download Slack files through safe downloader while preserving auth headers
- use team-specific token/header behavior
- apply per-media byte caps

Search hints:
- search for `url_private`, `url_private_download`, Slack file headers, and Slack adapter download helpers

### Mattermost

Current file:
- `plugins/platforms/mattermost/adapter.py`

Current intent:
- download Mattermost files through safe downloader with auth headers
- enforce explicit caps because downloads are held in memory

Search hints:
- search for file download endpoint handling, `files/{file_id}`, image/audio/document handling

### Feishu

Current file:
- `plugins/platforms/feishu/adapter.py`

Current intent:
- download Feishu media through safe downloader with auth headers

Search hints:
- search for media/file download functions and Feishu token headers

### QQBot

Current file:
- `gateway/platforms/qqbot/adapter.py`

Current intent:
- use safe downloader for QQ image/audio/media URLs while preserving required Authorization headers
- redact unsafe URLs in logs

Search hints:
- search for QQ media URL fetches, `file_info`, audio transcription temp file handling

### Telegram

Current file:
- `plugins/platforms/telegram/adapter.py`

Current intent:
- handle user-provided image URL downloads through safe downloader
- block unsafe URLs before cache/write

Search hints:
- search for image URL detection, `cache_image_from_url`, Telegram message image handling

### WeCom

Current file:
- `plugins/platforms/wecom/adapter.py`

Current intent/status:
- use `safe_download_bytes` for WeCom media downloads
- preserve required access-token behavior
- include `tests/gateway/test_wecom.py` coverage

Search hints:
- search for `_download_remote_bytes`, WeCom media helpers, and `tests/gateway/test_wecom.py::TestMediaUpload`


### Skills hub remote fetches

Current file:
- `tools/skills_hub.py`

Current intent:
- fetch remote/community skill text through `safe_download_bytes`
- validate redirects and block unsafe/private targets unless explicitly scoped by provider policy
- cap bytes and redact URLs at error/log boundaries before skill content reaches cache/install/view flows

Search hints:
- search for `WellKnownSkillSource`, remote skill source fetch helpers, hub/community/GitHub raw fetches, and any provider-mediated skill bundle download path

## Tests to keep aligned

Central tests:
- `tests/agent/test_context_safety.py` - required
- `tests/tools/test_safe_http.py` - required

Context integration tests:
- `tests/agent/test_memory_provider.py` - required
- `tests/agent/test_prompt_builder.py` - required
- `tests/tools/test_cronjob_tools.py` - required
- `tests/tools/test_skills_tool.py` - required

Gateway integration tests:
- `tests/gateway/test_api_server.py` - required
- `tests/gateway/test_base_media_cache_safe_http.py` - required
- `tests/gateway/test_discord_attachment_download.py` - required
- `tests/gateway/test_discord_document_handling.py` - required
- `tests/gateway/test_feishu.py` - required
- `tests/gateway/test_mattermost.py` - required
- `tests/gateway/test_media_download_retry.py` - required
- `tests/gateway/test_matrix_yuanbao_media_downloads.py` - required
- `tests/gateway/test_active_intent_segmentation.py` - required
- `tests/gateway/test_reply_to_injection.py` - required
- `tests/gateway/test_slack.py` - required
- `tests/gateway/test_stt_config.py` - required
- `tests/gateway/test_telegram_safe_image_download.py` - required
- `tests/gateway/test_tts_media_routing.py` - required
- `tests/gateway/test_wecom.py` - required

Security boundary tests:
- `tests/security/test_context_promotion_boundaries.py` - required
- `tests/security/test_development_authority.py` - required
- `tests/security/test_evidence_ledger_surface_matrix.py` - required
- `tests/security/test_safe_fetch_surfaces.py` - required
- `tests/security/test_skill_plugin_boundaries.py` - required
- `tests/security/test_artifact_provenance.py` - required
- `tests/security/test_action_authority.py` - required
- `tests/security/test_prompt_injection_containment.py` - required
- `tests/security/test_prompt_injection_public_corpus.py` - required, public/benign scanner-quality corpus
- `tests/security/test_tool_result_promotion.py` - required

Workflow and cache-regression tests:
- `tests/agent/test_copilot_acp_client.py` - required
- `tests/agent/test_evidence_ledgers.py` - required
- `tests/agent/test_file_safety.py` - required
- `tests/agent/test_shell_hooks.py` - required
- `tests/agent/test_skill_utils.py` - required
- `tests/plugins/browser/test_browser_provider_plugins.py` - required
- `tests/security/test_cli_argument_normalization.py` - required
- `tests/security/test_gateway_media_delivery_authority.py` - required
- `tests/tools/test_browser_console.py` - required
- `tests/tools/test_browser_vision_evidence_ledger.py` - required
- `tests/tools/test_customization_tool.py` - required
- `tests/tools/test_delegate.py` - required
- `tests/tools/test_file_write_safety.py` - required
- `tests/tools/test_modal_sandbox_fixes.py` - required
- `tests/tools/test_registry_availability_cache.py` - required
- `tests/tools/test_skills_hub.py` - required
- `tests/tools/test_skills_hub_clawhub.py` - required
- `tests/tools/test_transcription_tools.py` - required
- `tests/tools/test_vision_tools.py` - required
- `tests/tools/test_web_tools_config.py` - required
- `tests/tools/test_web_tools_tavily.py` - required

## Customization maintenance tool

### Tool implementation

Current files:
- `tools/customization_tool.py`
- `tests/tools/test_customization_tool.py`

Current intent:
- expose `hermes_customizations` for status/audit of downstream Hermes hardening payload repos
- read the informational config pointer at `customizations.hermes_agent_patches`
- verify hardening payload repos do not vendor Hermes source roots
- scan tracked hardening payload contents for common user-specific paths, PII, and secret-looking tokens
- verify `series` entries point to tracked payload fragment files

Search hints:
- search for `hermes_customizations`, `customizations.hermes_agent_patches`, or hardening-payload maintenance helpers
- preserve the repo-separation and PII-audit behavior even if the toolset name changes

## Provenance/action-authority hardening

### Artifact provenance

Current file:
- `agent/artifact_provenance.py`

Current intent:
- represent fetched/extracted/external artifacts with source, trust, authority, URL, content-type, byte-count, sha256, and extraction-chain metadata
- keep external artifacts evidence-only by default

### Action authority

Current files:
- `agent/action_authority.py`
- `model_tools.py`
- `run_agent.py`

Current intent:
- require trusted user intent for side-effecting actions
- treat untrusted retrieved/downloaded/skill/plugin/memory/cron text as evidence, never as action authority
- expose deterministic denial/confirmation outcomes for tests and tool-dispatch integration

Search hints:
- search for tool-call authorization gates, side-effecting tool metadata, provenance/taint envelopes, or confirmation policy helpers
- preserve fail-closed behavior for missing provenance before side effects

### Adjacent upstream terminal scanner: Tirith

Current upstream files:
- `tools/tirith_security.py`
- `tools/approval.py`
- `tools/terminal_tool.py`

Current intent:
- keep Tirith as command-content defense in depth for terminal execution after action authority allows dispatch
- do not treat Tirith findings as provenance or user intent; it scans the shell string, not the source of authority
- do not rely on Tirith for non-terminal tools, safe-fetch policy, model-visible context promotion, yolo/approvals-off behavior, fail-open scanner outages, container backends, or non-interactive paths where upstream command guards may be skipped

Search hints:
- search for `check_command_security`, `check_all_command_guards`, Tirith approval handling, terminal `force`, and container/non-interactive guard skips

## Tool-result promotion and action-registry hardening

### Action registry classification

Current files:
- `agent/action_authority.py`
- `model_tools.py`
- `run_agent.py`

Current intent:
- keep side-effecting action classification explicit and fail-closed
- require confirmation for unknown or unclassified side-effect behavior
- prevent untrusted or derived tool output from becoming action authority

### Tool-result promotion policy

Current files:
- `agent/context_safety.py`
- `agent/skill_commands.py`
- `model_tools.py`
- `run_agent.py`

Current intent:
- fence model-visible string tool results by default unless an explicit trusted-internal control-tool exemption applies
- apply model-visible fencing at the tool-message append boundary in `run_agent.py`, using idempotent helpers in `agent/context_safety.py` so an already complete `<untrusted-context>` block is not recursively double-fenced
- preserve specific provenance labels for browser/web extraction, PDF/OCR/document/YouTube/STT/transcript-like outputs, skill content, session-search/recalled content, plugin/MCP transformed results, and gateway attachment-like text
- propagate prior model-visible tool/evidence text into the action-authority gate before later side-effecting tools run, so clean-looking args derived from hostile evidence are still gated
- block concrete side-effect targets/args that appear only in evidence-only content, even when trusted user text contains a broad action verb
- keep `tests/security/test_tool_result_promotion.py` and taint-loss dispatch tests mandatory

Search hints:
- search for tool-result message creation, function-call result serialization, action registry/classification, skill command loading, browser/web extraction output, gateway attachment/transcript promotion, and prior-message taint collection
- preserve fail-closed action classification, default model-visible string-result fencing, and prior-tool-result taint propagation
