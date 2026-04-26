# Workstream map

| Workstream | Primary subagent | Scope | Main files likely touched | Must produce |
|---|---|---|---|---|
| Repo snapshot and drift | S00 | Current patch/docs/verifier consistency | patch repo docs, manifest, series | gap list and drift fixes |
| Threat model and invariants | S01 | Formal hostile-download model | docs, tests, surface inventory | invariant spec and acceptance criteria |
| Structured taint and authorization grants | S02 | Non-textual taint from ingress to tool dispatch | `agent/artifact_provenance.py`, `agent/action_authority.py`, `run_agent.py`, `model_tools.py` | taint model, grant model, tests |
| Tool registry metadata | S03 | Explicit tool action/output metadata, fail-closed unknowns | `tools/registry.py`, `toolsets.py`, `model_tools.py`, action authority | metadata schema, coverage tests |
| Tool-result promotion | S04 | Default untrusted promotion for model-visible tool strings | `agent/context_safety.py`, `model_tools.py`, `run_agent.py` | promotion policy and tests |
| Safe HTTP/parser/extractor risk | S05 | SSRF, redirect, DNS, proxy, size, parser limits | `tools/safe_http.py`, gateway/platforms, extraction tools | edge tests and policy fixes |
| Persistence/skills/plugins | S06 | Memory, cron, skills, plugin hooks, inline shell expansion | `agent/memory_manager.py`, `cron/*`, `tools/skills_*`, `agent/skill_commands.py`, plugin surfaces | durable taint and execution review |
| Adversarial E2E tests | S07 | Hostile-document-to-tool-call containment | `tests/security/*` | scenario tests where deterministic gate blocks |
| Docs/manifest/verifier/CI | S08 | Maintenance safety | docs, `manifest.yaml`, verifier, Actions | drift-proof handoff docs |
| Red-team review | S09 | Attack the final implementation | all changed files | bypasses, residual risks, fixes |
| Integration/patch refresh | S10 | Merge, refresh, verify | patch repo and Hermes checkout | final coherent patch stack |

## Recommended one-session order

1. Snapshot and analysis fan-out.
2. Integrate recommendations into a single implementation plan.
3. Implement P0 controls first: structured taint, fail-closed metadata, default tool-result taint, scoped authorization, persistence taint, docs/playbook drift.
4. Add E2E tests before final polish.
5. Refresh patch stack and run verifier.
6. Red-team final state.
