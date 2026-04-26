# Subagent 02: surface reconnaissance

You are a code reconnaissance subagent. Your task is to identify all live Hermes surfaces relevant to hostile-download prompt-injection containment.

## Ground rules

- Inspect live code before drawing conclusions.
- Do not modify code unless explicitly needed to add documentation of surfaces.
- Prefer exact file/function references and short evidence snippets.
- Do not stop at existing docs; verify against the current checkout.

## Required searches

Run broad searches such as:

```bash
rg -n "httpx|requests|aiohttp|urlopen|urllib|fetch|download|safe_download_bytes|is_safe_url|url_private|url_private_download|attachment\.url|proxy_url|file_info|media|get_file|Content-Length|Authorization|headers=.*Authorization" .
rg -n "context_from|system_prompt_block|pre_llm_call|skill_view|skill_install|skills_hub|plugin|memory|MEMORY\.md|USER\.md|cron|_build_job_prompt|@|context file|SOUL\.md|AGENTS\.md|CLAUDE\.md|\.cursorrules" agent tools cron gateway .
rg -n "tool_call|function_call|execute_tool|call_tool|tool_result|dispatch|invoke|side_effect|write|delete|send|email|message|secret|credential|cron|memory|install" agent tools toolsets.py cron gateway .
```

Adjust paths if the repository layout differs.

## Required classification

Produce or update a surface inventory with these categories:

### A. Remote-byte ingress

Examples to verify:

- gateway attachments/downloads
- web extraction/crawl/fetch tools
- skill hub/community/GitHub install/fetch paths
- plugin download/update paths
- media/document fallback download paths
- any direct `httpx`, `requests`, `urllib`, `aiohttp`, or equivalent usage

For each surface, record:

- file/function
- whether it uses `tools.safe_http`
- whether it preserves auth headers safely
- max byte caps
- content-type checks
- redirect behavior
- redaction behavior
- whether fetched bytes become model-visible text

### B. Extraction and cache paths

Record where bytes become:

- text
- markdown
- OCR
- PDF/Office/document extracted content
- summaries
- cached files
- temporary files
- gateway message fields

### C. Context-promotion surfaces

Record every path where external or derived text enters a prompt, system prompt block, user message context, tool result, memory block, cron job prompt, skill view, plugin pre-call context, or @ reference.

### D. Side-effecting action surfaces

Record every tool/action that can cause:

- file write/delete
- secret read/transmission
- outbound email/message/webhook/API post
- memory/profile write
- cron create/update/delete
- skill/plugin install/update/execute
- terminal command execution
- credentialed network call
- downloaded code execution

## Deliverables

Update:

```text
docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md
```

If the existing file is too patch-stack-focused, create an additional:

```text
docs/customizations/hermes-safe-fetch-context/HARDENING_SURFACE_INVENTORY.md
```

The deliverable must include exact file/function names and a status for each surface:

```text
covered
partially covered
uncovered
not applicable / read-only / no model promotion
needs policy decision
```

## Acceptance criteria

The output must be actionable for implementation. A later subagent should be able to pick any `uncovered` or `partially covered` surface and know what behavior to preserve or add.
