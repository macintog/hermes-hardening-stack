Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: docs and rebase playbook synchronization

## Task

Make the human-facing docs safe for maintainers. The docs must agree with the executable five-patch stack and must not allow accidental loss of `0005`.

## Files to edit or review

- `docs/customizations/hermes-safe-fetch-context/README.md`
- `docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md`
- `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
- `docs/customizations/hermes-safe-fetch-context/INTENT.md`
- `docs/customizations/hermes-safe-fetch-context/HANDOFF_PROMPT.md` if present
- root `README.md` if needed

## Required content

- Describe the hardening as a five-phase stack:
  1. context scanning/fencing;
  2. safe HTTP ingress;
  3. patch-stack maintenance tooling;
  4. provenance/action authority;
  5. tool-result promotion/action registry.
- Remove stale WeCom wording if manifest/patch/test coverage includes WeCom.
- Add `0005` to all patch lists and refresh commands.
- Add `tests/security/test_tool_result_promotion.py` to targeted test commands.
- Add a patch `0005` section to `SURFACE_MAP.md` with files/functions/surfaces:
  - `agent/context_safety.py::classify_tool_result_surface`
  - `agent/context_safety.py::render_model_visible_tool_result`
  - `model_tools.py` tool result promotion points
  - `run_agent.py` message append/promotion points
  - `agent/action_authority.py` tool registry/action classification
  - `tests/security/test_tool_result_promotion.py`
- Explain that docs are explanatory and `series`/`manifest.yaml`/verifier are canonical.

## Tests/checks

Recommend or implement drift checks in the verifier that parse the playbook and fail if:

- any `series` patch is absent from the playbook patch list;
- manifest-required tests are absent from the playbook targeted test command;
- the playbook refresh section writes an incomplete `series`.
