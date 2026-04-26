Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: structured turn/session taint

## Task

Design and implement, or specify exact implementable changes for, non-textual taint/provenance carried through the agent loop.

## Read/search

- `agent/action_authority.py`
- `agent/artifact_provenance.py`
- `agent/context_safety.py`
- `model_tools.py`
- `run_agent.py`
- message/tool-call dispatch paths
- tests in `tests/security/`

## Required security property

If a turn has seen untrusted content, side-effecting tools require trusted scoped authorization even if generated tool arguments no longer contain textual `<untrusted-context>` tags or obvious injection phrases.

## Preferred shape

Introduce or adapt a structure like:

```python
@dataclass(frozen=True)
class TurnSecurityContext:
    untrusted_context_seen: bool
    untrusted_surfaces: frozenset[ContextSurface]
    provenance_ids: tuple[str, ...]
    source_summary: tuple[str, ...]
```

Then wire it into action-authority evaluation.

## Implementation constraints

- Preserve backwards compatibility where possible.
- Keep existing text-based `prior_untrusted_context` as a fallback if needed, but do not make it the canonical signal.
- Add tests showing paraphrased hostile tool arguments are blocked because turn taint is set.

## Output

- Proposed code changes by file/function.
- Tests to add/update.
- Residual risks if full structural taint cannot be completed in one session.
