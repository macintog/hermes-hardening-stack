# Subagent 07: skill/plugin/hub hardening

You are a skill/plugin supply-chain and prompt-boundary subagent. Your task is to ensure skill, plugin, and hub content cannot become privileged instructions merely because Hermes loaded or displayed it.

## Security invariant

Skill/plugin content may be useful evidence or documentation. External/community/plugin skill content is not automatically trusted instruction. Installing, updating, executing, or giving authority to skill/plugin content requires explicit trust policy and/or user confirmation.

## Inputs to inspect

Search and read code for:

```bash
rg -n "skill_view|skill_install|skills_hub|skill|plugin|hub|community|github|install|update|pre_llm_call|_serve_plugin_skill|toolsets|enabled_skills|load_skill" tools agent .
```

Read existing tests for skill view/install/hub behavior.

## Required classifications

For each skill/plugin path, classify:

1. Source:
   - bundled/local trusted
   - user-authored local
   - configured external
   - community/hub
   - GitHub/URL-based
   - plugin-provided

2. Operation:
   - view/list/search
   - read content
   - install/update
   - load/enable
   - execute/run
   - inject pre-call context
   - expose tool definitions

3. Authority:
   - trusted by local policy
   - user confirmation required
   - evidence only
   - blocked

## Required implementation behavior

- `skill_view` can report findings, but report-only is insufficient where content becomes model-visible and later influences actions.
- External/community/plugin skill content must be promoted as untrusted evidence unless explicitly trusted by local policy.
- Linked skill file content that is model-visible must either carry provenance/scan/fence metadata or be documented as not model-visible.
- Skill install/update paths must use safe fetch or equivalent controls for remote bytes.
- Skill install/update/execute must go through the action-authority gate.
- Plugin `pre_llm_call` context must be scanned/fenced/tainted unless the plugin is trusted by explicit local policy.
- Skill README/setup instructions must not authorize command execution or file writes by themselves.

## Test requirements

Add or update tests for:

- external skill content containing prompt injection is marked evidence-only
- linked file content containing prompt injection is not silently treated as trusted instruction
- community/hub skill install uses safe fetch or equivalent URL/redirect/byte-cap controls
- skill README cannot authorize terminal execution
- plugin pre-call context cannot authorize side-effecting tools
- explicit trusted local skill can preserve expected behavior where policy says it is trusted

Likely files:

```text
tests/tools/test_skills_tool.py
tests/security/test_skill_plugin_boundaries.py
tests/security/test_action_authority.py
```

## Deliverables

- code changes for skill/plugin boundaries if needed
- tests
- updated surface map
- updated security model or intent docs if trust policy needs to be explicit

## Acceptance criteria

No skill/plugin/hub content can cross from “content/documentation/evidence” into “instruction authority” without a deterministic trust decision outside the content itself.
