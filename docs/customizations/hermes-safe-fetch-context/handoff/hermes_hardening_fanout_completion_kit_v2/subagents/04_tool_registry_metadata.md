Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: tool registry metadata and fail-closed action classification

## Task

Replace or strengthen hard-coded/name-based action classification with explicit tool metadata where feasible.

## Read/search

- `agent/action_authority.py`
- `model_tools.py`
- `toolsets.py`
- tool registration/provider files
- tests in `tests/security/test_action_authority.py`

## Required metadata concepts

For every model-callable tool, identify or add metadata for:

- action class;
- side-effecting vs read-only;
- credential use;
- network behavior;
- persistence behavior;
- filesystem behavior;
- output trust level;
- confirmation requirement;
- whether untrusted turn taint blocks or requires confirmation.

## Fail-closed rule

Unknown side-effecting tools must not silently proceed after untrusted content influenced the turn. Unknown output trust must default to untrusted evidence.

## Output

- Registry coverage report: classified, unknown, ambiguous.
- Changes needed to make metadata mandatory.
- Tests for unknown tool fail-closed behavior.
