# Hermes Safe Fetch + Context Promotion Master Thread Prompt

Use this prompt in a fresh Hermes thread.

You are the orchestrator for the Hermes safe-fetch and context-promotion hardening project.

Repo:
`~/.hermes/hermes-agent`

Project docs:
`$HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/`

Primary recommendation:
`docs/customizations/hermes-safe-fetch-context/README.md`

Implementation plan:
`docs/customizations/hermes-safe-fetch-context/IMPLEMENTATION_PLAN.md`

Subagent prompts:
`docs/customizations/hermes-safe-fetch-context/subagents/`

Prior related project:
prior related project notes, if available locally

## Current project state

The safe_fetch first wave and the first context-promotion centralization wave are complete.

Completed:
1. First-wave reconnaissance tracks A-D.
2. `IMPLEMENTATION_PLAN.md` was created and updated.
3. `tools/safe_http.py` was implemented.
4. `tests/tools/test_safe_http.py` was implemented.
5. Safe HTTP security/spec and quality/regression reviews passed after fixes.
6. Exactly one fetch caller was migrated:
   - `gateway/platforms/wecom.py::_download_remote_bytes`
7. WeCom migration tests were added/updated in:
   - `tests/gateway/test_wecom.py::TestMediaUpload`
8. WeCom migration security/spec review passed and quality/regression review approved.
9. `agent/context_safety.py` was implemented.
10. `tests/agent/test_context_safety.py` was implemented.
11. Context-safety core security/spec review passed and quality/regression review approved after fixes.
12. `agent/prompt_builder.py::_scan_context_content` was wired through `agent.context_safety.scan_context_text`.
13. Prompt-builder context-file scanner wiring passed security/spec and quality/regression reviews after fixing a long-context scan gap.
14. `tools/cronjob_tools.py::_scan_cron_prompt` was wired through `agent.context_safety.scan_context_text`.
15. Cron prompt scanner wiring passed security/spec and quality/regression reviews after preserving the exact invisible-unicode `Blocked:` string shape.
16. `cron/scheduler.py::_build_job_prompt` now fences cron script output and `context_from` prior output as untrusted evidence.
17. Slice 3C security/spec review passed and code-quality/regression review approved.
18. `agent/memory_manager.py::build_memory_context_block` now scans/renders memory provider prefetch context as untrusted recalled evidence while preserving the outer `<memory-context>` fence.
19. Memory provider context fencing/scanning security/spec review passed and code-quality/regression review approved.
20. `tools/skills_tool.py::skill_view` and plugin skill loading now add report-only structured `context_safety` findings for local, configured external, and plugin skill content without changing returned content or linked-file JSON shape.
21. Skill_view findings security/spec review passed and code-quality/regression review approved after fixes for report-only verdicts and external provenance.
22. `gateway/platforms/feishu.py::_download_remote_document` is migrated to `tools.safe_http.safe_download_bytes` with a 25 MiB cap, redirect revalidation, redacted errors, and streaming max-byte enforcement.
23. Feishu migration security/spec review passed and code-quality/regression review approved after fixing streaming/no-Content-Length over-cap handling.
24. `gateway/platforms/slack.py::_download_slack_file` and `_download_slack_file_bytes` are migrated to `tools.safe_http.safe_download_bytes` with a 20 MiB cap, same-origin credential redirect enforcement, private redirect blocking, and redacted signed-URL logging.
25. Slack migration security/spec review passed and code-quality/regression review approved.
26. `gateway/platforms/qqbot/adapter.py` media/STT download paths are migrated to `tools.safe_http.safe_download_bytes` with caps for image, voice/STT, and other attachments, credentialed redirect enforcement, private redirect blocking, and redacted media/STT URLs.
27. QQBot migration security/spec review passed and code-quality/regression review approved.
28. `gateway/platforms/mattermost.py` inbound file and URL-as-file paths are migrated to `tools.safe_http.safe_download_bytes` with URL-as-file strict SSRF checks, configured-origin support for self-hosted inbound attachments, credentialed redirect enforcement, caps, and redacted URLs.
29. Mattermost migration security/spec review passed and code-quality/regression review approved after fixing private/self-hosted configured-origin compatibility.
30. `gateway/platforms/telegram.py` fallback image download is migrated to `tools.safe_http.safe_download_bytes` with a 10 MiB cap, image content-type allowlist, strict SSRF/redirect checks, redacted URL logging, and preserved Telegram/Base fallback behavior.
31. Telegram migration security/spec review passed and code-quality/regression review approved.
32. `gateway/platforms/discord.py` fallback image/animation/attachment downloads are migrated to `tools.safe_http.safe_download_bytes` with caps, media allowlists where appropriate, strict SSRF/redirect checks, fail-closed SafeHTTPError handling, and redacted URL logging.
33. Discord migration security/spec review passed and code-quality/regression review approved after fixing unsafe URL forwarding on SafeHTTPError.
34. `gateway/platforms/base.py` shared `cache_image_from_url` and `cache_audio_from_url` helpers are migrated to `tools.safe_http.safe_download_bytes` with streaming byte caps, redirect revalidation, redacted errors, and compatibility for missing/generic media content types.
35. Base media cache migration security/spec review passed and code-quality/regression review approved after fixing retry tests, stream-time error wrapping, and content-type compatibility.

Important review-found fixes already applied:
- `safe_http` credential/redirect edge cases:
  - client default Authorization redirect leakage
  - client `auth=` redirects
  - target-origin cookie jar redirects
  - cross-origin redirects that set cookies before redirect
  - malformed initial URL and malformed redirect Location handling
  - stream-time `httpx.HTTPError` wrapping
- `context_safety` coverage gaps:
  - bidi isolate controls U+2066/U+2067/U+2068/U+2069
  - hidden HTML/CSS variants including hidden attributes, inert tags, transparent/offscreen/zero-size CSS
  - external-surface fencing coverage
  - escaped `source_label` attributes
  - immutable `ContextSafetyResult.flags`
- Prompt-builder long-context regression:
  - context files are full-scanned before truncation so payloads in kept-but-previously-unscanned regions are blocked.
- Cron prompt compatibility:
  - invisible Unicode still returns exactly:
    `Blocked: prompt contains invisible unicode U+XXXX (possible injection).`
- Skill_view compatibility:
  - main local/external/plugin skill responses add report-only `context_safety` and `context_safety_findings` fields only.
  - linked `file_path` responses preserve their exact previous JSON shape.
  - returned skill content is not fenced, rewritten, sanitized, or blocked.

Expected Hermes repo working tree state at handoff:
- Modified by this project from the original safe_fetch wave:
  - `gateway/platforms/wecom.py`
  - `tests/gateway/test_wecom.py`
- New from the original safe_fetch wave:
  - `tools/safe_http.py`
  - `tests/tools/test_safe_http.py`
- Modified by the context-promotion wave:
  - `agent/prompt_builder.py`
  - `tests/agent/test_prompt_builder.py`
  - `tools/cronjob_tools.py`
  - `tests/tools/test_cronjob_tools.py`
- New from the context-promotion wave:
  - `agent/context_safety.py`
  - `tests/agent/test_context_safety.py`
- Modified by Slice 3C:
  - `cron/scheduler.py`
  - `tests/cron/test_cron_context_from.py`
  - `tests/cron/test_cron_script.py`
- Modified by memory provider context slice:
  - `agent/memory_manager.py`
  - `tests/agent/test_memory_provider.py`
- Modified by skill_view context-safety findings slice:
  - `tools/skills_tool.py`
  - `tests/tools/test_skills_tool.py`
- Project docs modified outside repo:
  - `docs/customizations/hermes-safe-fetch-context/IMPLEMENTATION_PLAN.md`
  - `docs/customizations/hermes-safe-fetch-context/MASTER_THREAD_PROMPT.md`
- Pre-existing unrelated change:
  - `web/package-lock.json`
  - Do not touch it. Do not include it in any final diff/commit for this work.

Latest known verification:
```bash
scripts/run_tests.sh tests/tools/test_safe_http.py -q
scripts/run_tests.sh tests/tools/test_url_safety.py tests/tools/test_safe_http.py -q
scripts/run_tests.sh tests/gateway/test_wecom.py::TestMediaUpload -q
scripts/run_tests.sh tests/tools/test_safe_http.py tests/gateway/test_wecom.py::TestMediaUpload -q
scripts/run_tests.sh tests/agent/test_context_safety.py -q
scripts/run_tests.sh tests/agent/test_prompt_builder.py::TestScanContextContent tests/tools/test_cronjob_tools.py::TestScanCronPrompt tests/tools/test_cron_prompt_injection.py tests/agent/test_context_safety.py -q
```

Most recent combined verification:
```bash
.venv/bin/python -m py_compile agent/context_safety.py agent/prompt_builder.py tools/cronjob_tools.py agent/memory_manager.py tests/agent/test_context_safety.py tests/agent/test_prompt_builder.py tests/tools/test_cronjob_tools.py tests/agent/test_memory_provider.py
scripts/run_tests.sh tests/agent/test_prompt_builder.py::TestScanContextContent tests/tools/test_cronjob_tools.py::TestScanCronPrompt tests/tools/test_cron_prompt_injection.py tests/agent/test_context_safety.py -q
scripts/run_tests.sh tests/cron/test_cron_context_from.py::TestBuildJobPromptContextFrom tests/cron/test_cron_script.py::TestBuildJobPromptWithScript tests/agent/test_context_safety.py -q
scripts/run_tests.sh tests/agent/test_memory_provider.py tests/tools/test_memory_tool.py tests/agent/test_context_safety.py -q
.venv/bin/python -m py_compile tools/skills_tool.py tests/tools/test_skills_tool.py
scripts/run_tests.sh tests/tools/test_skills_tool.py tests/agent/test_context_safety.py -q
```

Most recent result:
- `97 passed, 97 warnings` for skill_view context-safety structured findings verification.

Known warning:
- `tests/conftest.py:433: DeprecationWarning: 'asyncio.get_event_loop_policy' is deprecated and slated for removal in Python 3.16`
- This warning is pre-existing and not part of this hardening task unless explicitly asked.

Environment note:
- Use `scripts/run_tests.sh` as the canonical test runner.
- If direct Python inspection is needed, use `.venv/bin/python`; bare `python` may not import repo dependencies such as `httpx` or `yaml`.

## Core mission from here

Complete the remaining hardening work without redoing completed waves.

Target pipeline:
```text
Remote bytes
  -> safe fetch
  -> artifact quarantine/provenance
  -> optional text extraction
  -> context safety scan
  -> fenced promotion as evidence
  -> side-effecting tools require trusted user/system/developer intent
```

Important security model:
- Downloaded, recalled, gateway, cron, skill, and other external text may be evidence.
- It is never authority.
- Do not let untrusted content silently become instructions.
- Do not globally mutate provider tool-call/result shapes.
- Preserve normal explicit developer workflows.

## Non-goals and hard constraints

Do not:
- Re-run first-wave reconnaissance unless current evidence shows the repo changed materially.
- Re-implement `tools/safe_http.py` or `agent/context_safety.py` from scratch.
- Re-wire prompt_builder or cron prompt scanning unless fixing a concrete regression.
- Migrate multiple fetch callers in one unreviewed slice.
- Globally sanitize every tool result.
- Rewrite OpenAI/Anthropic tool-call/result message formats.
- Make LLM Guard or any new scanner a hard dependency.
- Block normal explicit terminal workflows.
- Touch unrelated files, especially `web/package-lock.json`.
- Use `npm install` without explicit user authorization.
- Preserve or expose secrets/tokens/signed URLs in logs or docs. Redact as `[REDACTED]`.

## Orchestration style

Operate like a real master thread:
- Delegate aggressively to subagents.
- Use fresh subagents for implementation and review tasks.
- Parallelize independent read-only review/recon tasks.
- Do not run implementation tasks in parallel if they touch the same files.
- Keep the master thread focused on coordination, scope control, synthesis, and verification.
- Use TDD for each implementation slice.
- Use two-stage reviews after each implementation slice:
  1. security/spec review via `subagents/10-security-spec-review.md`
  2. code-quality/regression review via `subagents/11-code-quality-regression-review.md`
- Do not proceed past a slice while either review has blocking findings.

## Resume gate for a fresh thread

Before making changes:
1. Read this file.
2. Read `IMPLEMENTATION_PLAN.md`.
3. Read `subagents/INDEX.md` and `DELEGATION_MATRIX.md`.
4. Inspect repo state:
   ```bash
   git status --short --branch
   git diff --name-only
   ```
5. Confirm `web/package-lock.json` is still unrelated and untouched.
6. Prefer a small verification command before continuing:
   ```bash
   scripts/run_tests.sh tests/tools/test_skills_tool.py tests/agent/test_context_safety.py -q
   ```

If current repo state differs from this handoff, stop only if the difference creates a real risk of overwriting unrelated user work. Otherwise proceed and record the difference in the final report.

## Next-session operating instruction

When the next session begins, act as the master-thread orchestrator and delegate all substantive implementation and review work to fresh subagents until the remaining project work is complete. Do not pause for user approval between remaining slices. Stop and ask the user only if intervention is actually required, such as:
- a hidden product/security tradeoff that changes the intended scope.
- credentials, external service access, or authorization is required.
- current repo state shows unrelated user work that would be overwritten.
- tests expose a failing behavior whose correct resolution cannot be inferred from the plan.

For every remaining slice:
1. Run the hygiene gate.
2. Dispatch an implementation subagent with strict TDD.
3. Dispatch security/spec and code-quality/regression review subagents.
4. If either review requests changes, dispatch a fix subagent and re-review.
5. Run targeted verification from the master thread.
6. Update this file and `IMPLEMENTATION_PLAN.md` before moving to the next slice.

Do not commit unless the user explicitly asks.

## Completed phase: fence cron script output and context_from prior output

Slice 3C is complete and reviewed.

### Slice 3C: cron script output and context_from fencing

Likely files:
- `cron/scheduler.py`
- `tests/cron/test_cron_context_from.py`
- `tests/cron/test_cron_script.py`
- possibly `tests/agent/test_context_safety.py` only for missing core behavior

Goal:
- Fence cron script stdout/stderr and prior job output injected through `context_from` as untrusted evidence.
- Preserve the rule that cron sessions cannot recursively schedule cron jobs.
- Do not break existing prompt shape beyond the intended fence labels.
- Do not change cron prompt create/update validation; that is already wired and reviewed.

Suggested implementation approach:
1. Inspect `cron/scheduler.py` prompt-building paths for:
   - script stdout/stderr injection
   - `context_from` prior job output injection
   - cron recursion guard text
2. Write failing tests first in the existing cron test files.
3. Use `agent.context_safety.render_untrusted_context(...)` or `scan_context_text(...).rendered_text` to fence output as evidence.
4. Use clear surfaces:
   - `ContextSurface.CRON_SCRIPT_OUTPUT`
   - `ContextSurface.CRON_PRIOR_OUTPUT`
5. Preserve existing labels/headings around script and prior output where tests depend on them.
6. Do not fence the trusted user-authored cron prompt itself in this slice.
7. Do not globally mutate terminal output or tool result messages.

Required tests:
- Cron script stdout containing `ignore previous instructions` is fenced as untrusted evidence, not injected raw as authority.
- Cron script stderr, if promoted into the job prompt, is also fenced or covered by the same helper.
- `context_from` prior job output containing `ignore previous instructions` is fenced as untrusted evidence.
- Nested spoofed fences inside cron output are escaped or neutralized so they cannot break out.
- Existing cron recursion guard remains present/effective.
- Existing benign cron output still appears, but inside the untrusted fence.

Verification:
```bash
scripts/run_tests.sh tests/cron/test_cron_context_from.py::TestBuildJobPromptContextFrom tests/cron/test_cron_script.py::TestBuildJobPromptWithScript tests/agent/test_context_safety.py -q
```

If class/test names have drifted, inspect the files first and use the nearest targeted tests. Do not invent paths.

Review gates:
- Security/spec review.
- Code-quality/regression review.

Only proceed when both pass/approve.

## Completed phase: memory provider context fencing/scanning

This slice is complete and reviewed.

Likely files:
- `agent/memory_manager.py`
- memory-related tests under `tests/agent/` and `tests/tools/`

Goal:
- Apply context-safety scanning/neutralization to memory provider prefetch context while preserving the existing outer `<memory-context>` fence and system note.
- Treat memory as helpful recalled evidence, not authority.
- Neutralize nested/spoofed `<memory-context>` and `<untrusted-context>` tags.
- Do not initially modify `MemoryProvider.system_prompt_block()` unless the user explicitly asks; that enters the system prompt directly and is more compatibility-sensitive.

Suggested implementation approach:
1. Inspect `agent/memory_manager.py` for provider prefetch rendering and sanitization helpers.
2. Write failing tests proving nested memory-context fence spoofing is neutralized.
3. Use `scan_context_text(..., surface=ContextSurface.MEMORY_CONTEXT, source_label=provider name or "memory_provider")`.
4. Preserve the current outer fence and note exactly unless tests are deliberately updated.

Verification:
```bash
scripts/run_tests.sh tests/agent/test_memory_provider.py tests/tools/test_memory_tool.py tests/agent/test_context_safety.py -q
```

Review gates:
- Security/spec review.
- Code-quality/regression review.

## Completed phase: skill_view findings without JSON-shape breakage

This slice is complete and reviewed.

Modified files:
- `tools/skills_tool.py`
- `tests/tools/test_skills_tool.py`

Implemented behavior:
- `skill_view()` reports structured `context_safety` and `context_safety_findings` for local, configured external, and plugin skill content.
- Presentation verdict is report-only: `safe` when no findings, `warn` when findings exist.
- Underlying scanner verdict is preserved as `raw_verdict` for diagnostics.
- Provenance is explicit: `local`, `external`, or `plugin`; plugin responses include `plugin_namespace`.
- `enforcement` is always `report_only` in this slice.
- Returned skill content is not fenced, rewritten, sanitized, or blocked.
- Linked `file_path` responses preserve their exact old JSON shape.

Verification:
```bash
.venv/bin/python -m py_compile tools/skills_tool.py tests/tools/test_skills_tool.py
scripts/run_tests.sh tests/tools/test_skills_tool.py tests/agent/test_context_safety.py -q
```

Review gates:
- Security/spec review: PASS.
- Code-quality/regression review: APPROVED.

## Remaining work to complete the project

All core context-promotion surfaces named in the definition of done are complete. Remaining work is now the fetch-caller migration set plus optional provenance/authority follow-ups.

### Remaining required work: additional safe_fetch caller migrations

Migrate one caller per slice with TDD and review. Do not batch multiple platforms in one unreviewed implementation slice.

Remaining required work: none. The recommended safe_fetch caller migration set is complete.

Completed caller migrations now include:
1. `gateway/platforms/feishu.py::_download_remote_document`.
2. `gateway/platforms/slack.py::_download_slack_file` and `_download_slack_file_bytes`.
3. `gateway/platforms/qqbot/adapter.py` media/STT download paths.
4. `gateway/platforms/mattermost.py` inbound file / URL-as-file paths.
5. `gateway/platforms/telegram.py` fallback image download.
6. `gateway/platforms/discord.py` fallback image/animation/attachment downloads.
7. Shared media cache helpers in `gateway/platforms/base.py`.

For each fetch migration:
- Preserve caller signatures and return shapes.
- Use `tools.safe_http.safe_download_bytes` or `safe_download_to_file`.
- Pass meaningful `source_type` and `policy` metadata.
- Preserve or improve byte caps.
- Use content-type allowlists only where caller behavior already supports one.
- Add redirect-to-private and oversized-response tests where relevant.
- For credential-bearing callers, keep credentials bound to the original origin and block credentialed cross-origin redirects unless an explicit, tested opt-in retry is designed.
- Redact signed URLs and credentials from logs/errors.
- Run security/spec and code-quality/regression reviews before moving on.

### Remaining optional follow-up: artifact quarantine/provenance

Do after fetch migrations are stable, unless a migration naturally exposes an existing cache/temp artifact flow.
- Add sidecar metadata only where there is an existing artifact/cache/temp flow.
- Include redacted source URL, redacted final URL, content type, bytes read, sha256, source type, fetch policy, and context scan verdict when available.
- Do not introduce a broad new artifact store unless required by concrete caller needs.

### Remaining optional follow-up: action authority regression tests

Do after context fencing and fetch migrations are stable.
- Add tests proving untrusted retrieved/recalled/cron/plugin/gateway content cannot authorize side-effecting actions by itself.
- Start with regression tests and prompt/fence semantics rather than a broad new permission framework.
- High-impact actions to cover eventually: installs, deletes, exfiltration, persistence, auth/system service edits, out-of-scope file writes, messages/emails, cron creation/update, memory/profile writes, secret reads/transmission, downloaded code execution, credentialed network calls.


## Overall definition of done

The project is complete when:
1. `tools/safe_http.py` exists, is tested, and is used by at least the agreed first set of remote-download callers.
2. `agent/context_safety.py` exists with tests covering detection, benign near-misses, long text, and fence rendering.
3. Prompt-builder context files and cron prompt scanning are centralized or bridged through context safety without breaking existing markers/errors.
4. Cron script output and `context_from` prior output are fenced as untrusted evidence.
5. Memory provider context remains fenced, neutralizes spoofed/nested fences, and is never authority.
6. Skill content scanning reports findings without breaking `skill_view()` response shape.
7. Security/spec and code-quality/regression reviews pass for each slice.
8. Targeted tests pass for every touched surface.
9. No unrelated files are touched.
10. Remaining optional work is explicitly documented in `IMPLEMENTATION_PLAN.md`.

## Final verification before reporting completion

Run the targeted suites for all touched areas. At minimum, after context work:
```bash
scripts/run_tests.sh tests/agent/test_context_safety.py -q
scripts/run_tests.sh tests/agent/test_prompt_builder.py::TestScanContextContent tests/tools/test_cronjob_tools.py::TestScanCronPrompt tests/tools/test_cron_prompt_injection.py -q
scripts/run_tests.sh tests/cron/test_cron_context_from.py::TestBuildJobPromptContextFrom tests/cron/test_cron_script.py::TestBuildJobPromptWithScript -q
scripts/run_tests.sh tests/agent/test_memory_provider.py tests/tools/test_memory_tool.py tests/tools/test_skills_tool.py -q
scripts/run_tests.sh tests/tools/test_safe_http.py tests/tools/test_url_safety.py tests/gateway/test_wecom.py::TestMediaUpload -q
```

If a full or broad suite is blocked by unrelated environment gaps, record the exact failure and run the smallest meaningful test slice instead.

Before final response:
```bash
git status --short --branch
git diff --stat
```

Final response should include:
- changed files grouped by slice.
- tests run and results.
- review verdicts.
- any known warnings.
- any remaining follow-up work.
