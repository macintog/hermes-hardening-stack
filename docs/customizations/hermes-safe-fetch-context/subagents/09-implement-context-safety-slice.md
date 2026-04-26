# Subagent 09: Implement Context Safety Slice

You are an implementation subagent for the first context-promotion hardening slice.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `/Users/ryand/playground/hermes-safe-fetch-context/RECOMMENDATION.md`
- `/Users/ryand/playground/hermes-safe-fetch-context/DELEGATION_MATRIX.md`
- context safety design spec from the master thread or `subagents/08-context-safety-design-spec.md`

Mission:
Implement the minimal `agent/context_safety.py` slice and tests. Wire exactly one promotion surface only if the master thread explicitly asks for wiring in this task.

Expected initial files:
- Create: `agent/context_safety.py`
- Create: `tests/agent/test_context_safety.py`

Possible one-surface wiring targets, if approved:
- `agent/prompt_builder.py` context file scanning, preserving existing blocked marker behavior
- `tools/cronjob_tools.py` cron prompt scanning, preserving existing error string behavior

Required behavior:
- structured finding/result types
- source/provenance surface enum or equivalent
- verdict enum or equivalent
- invisible Unicode detection
- high-confidence injection/exfiltration detection
- benign near-miss tests
- untrusted-context fence renderer
- nested fence/tag spoofing stripped or neutralized
- long text head/tail or chunk scan, if in scope for this slice

TDD steps:
1. Write failing tests first.
2. Run targeted tests and confirm failure.
3. Implement minimal module.
4. Run targeted tests and confirm pass.
5. If wiring one surface, add/adjust targeted wrapper tests and verify pass.

Constraints:
- Do not globally mutate tool outputs.
- Do not alter provider tool-call/result formats.
- Do not wire multiple surfaces in the first slice.
- Do not overblock benign developer/security prose.
- Do not create broad filename trust exemptions.
- Do not install dependencies.

Deliverable:
- Files changed.
- Tests added/updated.
- Commands run and results.
- Any behavior changes explicitly listed.
