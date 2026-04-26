# Subagent 03: Context Promotion Reconnaissance

You are a reconnaissance subagent for Hermes context-promotion hardening.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `docs/customizations/hermes-safe-fetch-context/README.md`
- `docs/customizations/hermes-safe-fetch-context/DELEGATION_MATRIX.md`

Prior related project:
prior related project notes, if available locally

Mission:
Inspect Hermes for places where text is promoted into model context, especially untrusted/recalled/external text. This is read-only. Do not modify files.

Inspect at minimum:
- `agent/prompt_builder.py`
- `agent/memory_manager.py`
- `tools/cronjob_tools.py`
- `cron/scheduler.py`
- `tools/skills_tool.py`
- `tools/skill_manager_tool.py`
- `tools/skills_guard.py`
- gateway session/message context files, especially `gateway/session.py` and `gateway/platforms/base.py`
- existing content-safety modules from the prior pass, if present, such as `agent/content_safety.py` or `agent/content_safety_rules.py`

Look for:
- context files injected into system prompt
- memory provider output
- cron prompt construction
- cron script stdout / prior job output injection
- skill content returned by `skill_view`
- gateway reply/channel context
- duplicated scanner patterns
- existing fences and blocked markers
- places where tool result schemas must not be touched

Deliverable:
A concise report with:
1. Promotion surface table: file, function, source type, current protections, gaps.
2. Existing scanner/fence modules and how they work.
3. Recommendation for `agent/context_safety.py` API shape.
4. Recommended first wiring target and why.
5. False-positive risks to avoid.
6. Tool-contract boundaries that must not be changed.

Constraints:
- Do not edit files.
- Do not propose global tool-result rewriting.
- Do not propose treating memory or downloaded text as trusted instruction.
- Preserve existing behavior where tests likely depend on exact blocked markers/fence tags.
