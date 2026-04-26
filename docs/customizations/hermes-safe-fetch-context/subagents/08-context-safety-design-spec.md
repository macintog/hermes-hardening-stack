# Subagent 08: Context Safety Design Spec

You are a design subagent for Hermes context-promotion hardening.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- `/Users/ryand/playground/hermes-safe-fetch-context/DELEGATION_MATRIX.md`

Prior related project:
`/Users/ryand/playground/hermes-content-safety/`

Mission:
Design `agent/context_safety.py` as a higher-level provenance-aware scan/fence/promotion wrapper. This is design-only unless explicitly told otherwise. Do not modify files.

Important distinction:
The earlier content-safety work focused on shared scanner primitives. This design should focus on promotion policy: where text came from, whether it is trusted, how to fence it, and when to block it.

Design requirements:
- Preserve surface-specific policy.
- Keep downloaded/recalled/external text as evidence, not authority.
- Do not globally mutate tool result messages.
- Do not break existing memory/context fence shapes unless tests are updated deliberately.
- Support source/provenance labels.
- Support structured findings and verdicts.
- Support a standard untrusted-context fence.
- Allow benign developer/security text and near-misses.

Suggested surfaces:
- context_file
- cron_prompt
- cron_script_output
- cron_prior_output
- memory_context
- skill_content
- gateway_reply
- gateway_attachment_text
- downloaded_text
- terminal_output
- user_message

Suggested verdicts:
- allow
- allow_with_warning
- fence
- block
- require_user_confirmation

Deliverable:
A concrete spec with:
1. Proposed file path.
2. Relationship to existing `agent/content_safety.py` / `agent/content_safety_rules.py` if present.
3. Dataclasses/enums/functions with signatures.
4. Fence format.
5. Surface-specific default policies.
6. First test cases.
7. Recommended first wiring target.
8. Compatibility risks and false-positive traps.

Constraints:
- Do not edit files.
- Do not propose a global sanitizer.
- Do not propose making external memory or downloaded content trusted.
- Keep first implementation slice small.
