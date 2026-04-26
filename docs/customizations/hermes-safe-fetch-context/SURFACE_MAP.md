# Surface map

Use this when upstream Hermes moves code around. The point is to preserve the behavior, not the exact line numbers.

## Patch 0001: context safety core

### Core module

Current file:
- `agent/context_safety.py`

Purpose:
- define context surfaces
- scan untrusted text for prompt-injection, hidden text, path/script injection, and secret-exfil patterns
- return structured findings
- render untrusted context blocks with metadata

If moved upstream:
- search for prompt/context safety helpers
- keep a single shared scanner rather than per-tool regex copies

### Prompt/context file ingestion

Current file:
- `agent/prompt_builder.py`

Current intent:
- use `scan_context_text(...)` for context files promoted into system prompt context
- convert structured scanner result into legacy blocking/error behavior where required

If moved upstream:
- search for `SOUL.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `_scan_context_content`, or prompt context file loading

### Memory provider context

Current file:
- `agent/memory_manager.py`

Current intent:
- scan memory provider output before including it in model context
- render provider output as an untrusted context block with findings metadata when relevant

If moved upstream:
- search for `build_memory_context_block`, memory provider context rendering, `MEMORY.md`, or `USER.md`

### Cron prompt/script output context

Current files:
- `cron/scheduler.py`
- `tools/cronjob_tools.py`

Current intent:
- scan cron prompts before saving/scheduling
- render cron pre-run script output and upstream job context as untrusted data when building job prompts

If moved upstream:
- search for `_build_job_prompt`, `context_from`, `prerun_script`, `cronjob`, or cron prompt validation

### Skill view/install surfaces

Current file:
- `tools/skills_tool.py`

Current intent:
- scan skill content served into the conversation
- expose `context_safety` and `context_safety_findings` fields in tool output
- distinguish provenance where possible: builtin/local/plugin/hub/external

If moved upstream:
- search for `skill_view`, `_serve_plugin_skill`, skill content serialization, hub install/audit logic

## Patch 0002: safe HTTP and gateway download hardening

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

If moved upstream:
- search for URL safety helpers, SSRF guards, browser URL blocklist, or download utilities
- keep redirect validation explicit

### Base gateway media cache

Current file:
- `gateway/platforms/base.py`

Current intent:
- `cache_image_from_url` and `cache_audio_from_url` use `safe_download_bytes`
- preserve retry behavior
- enforce media byte caps

If moved upstream:
- search for `cache_image_from_url`, `cache_audio_from_url`, `IMAGE_CACHE_DIR`, `AUDIO_CACHE_DIR`

### Discord

Current file:
- `gateway/platforms/discord.py`

Current intent:
- use safe fallback downloader for images/media/attachments
- preserve Discord SDK primary path where applicable
- block/redact unsafe fallback URLs
- enforce media/attachment byte caps

If moved upstream:
- search for Discord attachment download fallback, `attachment.url`, `proxy_url`, `to_file`, image/audio attachment handling

### Slack

Current file:
- `gateway/platforms/slack.py`

Current intent:
- download Slack files through safe downloader while preserving auth headers
- use team-specific token/header behavior
- apply per-media byte caps

If moved upstream:
- search for `url_private`, `url_private_download`, `_download_slack_file`, Slack file headers

### Mattermost

Current file:
- `gateway/platforms/mattermost.py`

Current intent:
- download Mattermost files through safe downloader with auth headers
- enforce explicit caps because downloads are held in memory

If moved upstream:
- search for file download endpoint handling, `files/{file_id}`, image/audio/document handling

### Feishu

Current file:
- `gateway/platforms/feishu.py`

Current intent:
- download Feishu media through safe downloader with auth headers

If moved upstream:
- search for media/file download functions and Feishu token headers

### QQBot

Current file:
- `gateway/platforms/qqbot/adapter.py`

Current intent:
- use safe downloader for QQ image/audio/media URLs while preserving required Authorization headers
- redact unsafe URLs in logs

If moved upstream:
- search for QQ media URL fetches, `file_info`, audio transcription temp file handling

### Telegram

Current file:
- `gateway/platforms/telegram.py`

Current intent:
- handle user-provided image URL downloads through safe downloader
- block unsafe URLs before cache/write

If moved upstream:
- search for image URL detection, `cache_image_from_url`, Telegram message image handling

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

## Patch 0003: customization maintenance tool

### Tool implementation

Current files:
- `tools/customization_tool.py`
- `tests/tools/test_customization_tool.py`
- `toolsets.py`

Current intent:
- expose `hermes_customizations` for status/audit of downstream Hermes patch-stack repos
- read the informational config pointer at `customizations.hermes_agent_patches`
- verify patch-stack repos do not vendor Hermes source roots
- scan tracked patch-stack contents for common user-specific paths, PII, and secret-looking tokens
- verify `series` entries point to tracked patch files

If moved upstream:
- search for `hermes_customizations`, `customizations.hermes_agent_patches`, or patch-stack maintenance helpers
- preserve the repo-separation and PII-audit behavior even if the toolset name changes
