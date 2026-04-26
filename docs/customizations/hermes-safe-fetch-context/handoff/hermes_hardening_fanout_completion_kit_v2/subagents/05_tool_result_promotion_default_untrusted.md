Use `macintog/hermes-hardening-stack` as source of truth and inspect the local Hermes checkout where needed. Do not assume stale review notes are correct if the latest repo differs. Return your findings using `templates/subagent_report.md`.

Focus on implementable changes, deterministic tests, and exact file/function names. Do not produce generic advice.

# Subagent: tool-result promotion default-untrusted policy

## Task

Strengthen model-visible tool-result promotion so string outputs default to untrusted evidence unless explicit metadata marks them trusted internal control output.

## Read/search

- `agent/context_safety.py`
- `model_tools.py`
- `run_agent.py`
- `tests/security/test_tool_result_promotion.py`
- all places where tool results are appended to model messages

## Current concern

Targeted name-based fencing for web/PDF/OCR/transcript/attachment-like tools is useful but incomplete. A new tool can return hostile natural-language text without matching known names.

## Required behavior

- All model-visible string tool result content is untrusted by default.
- Trusted internal control output requires explicit registry metadata.
- Existing structured tool outputs should preserve machine-readable shape where necessary, but any human-readable text shown to the model should be fenced/tainted.
- Tool outputs should carry provenance/surface metadata where possible.

## Tests

Add tests for:

- unknown tool string output is fenced as untrusted;
- known extraction output is fenced;
- trusted internal status/control output can remain unfenced only with explicit metadata;
- non-string binary/path metadata does not accidentally become trusted instruction text.
