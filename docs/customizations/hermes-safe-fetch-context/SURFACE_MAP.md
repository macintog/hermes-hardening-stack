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

Current intent:
- scan memory provider output before including it in model context
- render provider output as an untrusted context block with findings metadata when relevant

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
- `gateway/platforms/discord.py`

Current intent:
- use safe fallback downloader for images/media/attachments
- preserve Discord SDK primary path where applicable
- block/redact unsafe fallback URLs
- enforce media/attachment byte caps

Search hints:
- search for Discord attachment download fallback, `attachment.url`, `proxy_url`, `to_file`, image/audio attachment handling

### Slack

Current file:
- `gateway/platforms/slack.py`

Current intent:
- download Slack files through safe downloader while preserving auth headers
- use team-specific token/header behavior
- apply per-media byte caps

Search hints:
- search for `url_private`, `url_private_download`, `_download_slack_file`, Slack file headers

### Mattermost

Current file:
- `gateway/platforms/mattermost.py`

Current intent:
- download Mattermost files through safe downloader with auth headers
- enforce explicit caps because downloads are held in memory

Search hints:
- search for file download endpoint handling, `files/{file_id}`, image/audio/document handling

### Feishu

Current file:
- `gateway/platforms/feishu.py`

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
- `gateway/platforms/telegram.py`

Current intent:
- handle user-provided image URL downloads through safe downloader
- block unsafe URLs before cache/write

Search hints:
- search for image URL detection, `cache_image_from_url`, Telegram message image handling

### WeCom

Current file:
- `gateway/platforms/wecom.py`

Current intent/status:
- use `safe_download_bytes` for WeCom media downloads
- preserve required access-token behavior
- include `tests/gateway/test_wecom.py` coverage

Search hints:
- search for `gateway/platforms/wecom.py`, `_download_remote_bytes`, and `tests/gateway/test_wecom.py::TestMediaUpload`


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
- `tests/agent/test_context_safety.py`
- `tests/tools/test_safe_http.py`

Context integration tests:
- `tests/agent/test_memory_provider.py`
- `tests/agent/test_prompt_builder.py`
- `tests/cron/test_cron_context_from.py`
- `tests/cron/test_cron_script.py`
- `tests/tools/test_cronjob_tools.py`
- `tests/tools/test_skills_tool.py`

Gateway integration tests:
- `tests/gateway/test_base_media_cache_safe_http.py`
- `tests/gateway/test_discord_attachment_download.py`
- `tests/gateway/test_feishu.py`
- `tests/gateway/test_mattermost.py`
- `tests/gateway/test_media_download_retry.py`
- `tests/gateway/test_qqbot.py`
- `tests/gateway/test_slack.py`
- `tests/gateway/test_telegram_safe_image_download.py`
- `tests/gateway/test_wecom.py`

Security boundary tests:
- `tests/security/test_context_promotion_boundaries.py`
- `tests/security/test_safe_fetch_surfaces.py`
- `tests/security/test_skill_plugin_boundaries.py`
- `tests/security/test_artifact_provenance.py`
- `tests/security/test_action_authority.py`
- `tests/security/test_prompt_injection_containment.py`
- `tests/security/test_prompt_injection_public_corpus.py` — public/benign scanner-quality corpus
- `tests/security/test_tool_result_promotion.py`

## Customization maintenance tool

### Tool implementation

Current files:
- `tools/customization_tool.py`
- `tests/tools/test_customization_tool.py`
- `toolsets.py`

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
