# Subagent 01: Plan and Task Graph

You are a planning subagent for Hermes safe-fetch and context-promotion hardening.

Repo:
`/Users/ryand/.hermes/hermes-agent`

Project docs:
- `docs/customizations/hermes-safe-fetch-context/README.md`
- `docs/customizations/hermes-safe-fetch-context/MASTER_THREAD_PROMPT.md`
- `docs/customizations/hermes-safe-fetch-context/DELEGATION_MATRIX.md`

Prior related project:
prior related project notes, if available locally

Mission:
Read the recommendation and produce a concrete execution graph. This is read-only. Do not modify files.

Focus:
- Break the work into implementation phases.
- Identify task dependencies.
- Identify which tasks are safe to run in parallel and which must be sequential.
- Identify the smallest safe first implementation slice.
- Preserve the central constraint: harden ingress and context-promotion boundaries without globally sanitizing tool results or breaking tool schemas.

Deliverable:
A concise report with:
1. Ordered task graph.
2. Dependencies between tasks.
3. Exact files likely touched per task.
4. Recommended first implementation slice.
5. Review gates after each slice.
6. Targeted verification commands likely needed.
7. Risks or ambiguities the master thread must resolve.

Constraints:
- Do not edit files.
- Do not propose making LLM Guard a required dependency.
- Do not propose a global sanitizer for all tool outputs.
- Do not propose touching unrelated repo changes.
- Keep the plan minimal and reversible.
