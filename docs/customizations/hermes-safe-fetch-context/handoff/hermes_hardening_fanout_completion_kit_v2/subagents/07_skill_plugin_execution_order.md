Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: skill/plugin execution ordering and inline shell expansion

## Task

Determine whether skill or plugin content can cause execution before provenance/trust checks and context fencing. Fix or specify a precise fix.

## Read/search

- `agent/skill_commands.py`
- `tools/skills_tool.py`
- `tools/skills_hub.py`
- `tools/skill_manager_tool.py`
- `tools/skills_guard.py`
- plugin hook/injection code
- tests for skills/plugins and security boundaries

## Current concern

`_build_skill_message` appeared to call `_expand_inline_shell(...)` before `scan_and_render_untrusted_context(...)`. If untrusted/community/plugin skill content can reach this path, shell expansion may occur before safety controls.

## Required behavior

- Determine provenance/trust before inline shell expansion.
- Disable inline shell expansion for external/community/plugin skills unless trusted scoped authorization permits it.
- Fencing/scan should not happen after an execution-capable transform has already run.
- Loaded skill body content should be untrusted evidence unless trusted local/bundled provenance is established.

## Tests

Add tests proving:

- untrusted skill content with inline shell syntax does not execute;
- trusted local/bundled skill behavior remains compatible if allowed;
- plugin-injected or hub-provided skill content cannot authorize side effects.
