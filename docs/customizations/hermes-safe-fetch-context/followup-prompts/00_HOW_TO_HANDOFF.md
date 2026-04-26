# Hermes / GPT-5.5 handoff instructions

## Purpose

This prompt bundle turns the audit feedback into executable Hermes workstreams. It is designed for a Hermes/GPT-5.5 main thread that can delegate to subagents and operate on both:

- Hermes source checkout: `~/.hermes/hermes-agent`
- downstream patch-stack repo: `$HOME/.config/hermes-agent-patches`

The goal is not merely to improve scanner wording. The goal is to implement and validate a hard security invariant:

> Downloaded, retrieved, gateway-supplied, recalled, cron-supplied, skill-supplied, plugin-supplied, or otherwise external content may be evidence, but it must never be sufficient authority for side-effecting tool calls.

## Where to put these files

Recommended location inside the patch-stack repo:

```bash
mkdir -p "$HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/followup-prompts/subagents"
cp -R ./hermes_security_hardening_handoff/* \
  "$HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/followup-prompts/"
```

If Hermes cannot read that location, paste the contents of `01_MASTER_EXECUTION_PROMPT.md` directly into a fresh Hermes/GPT-5.5 thread and tell it where the rest of the files are.

## Exact prompt to paste into Hermes/GPT-5.5

```text
You are running inside Hermes with access to the local Hermes checkout and the downstream hardening patch-stack repo.

Read and execute this master prompt:
$HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/followup-prompts/01_MASTER_EXECUTION_PROMPT.md

Use the subagent prompt files under:
$HOME/.config/hermes-agent-patches/docs/customizations/hermes-safe-fetch-context/followup-prompts/subagents/

Do not summarize the task back to me. Begin with the hygiene gate, then delegate each workstream to a fresh subagent. Do not pause for approval between slices unless actual user intervention is required for credentials, authorization, a hidden product/security tradeoff, or unrelated local work at risk.

Primary objective:
Prevent prompt injection from potentially hostile downloads, retrieved content, gateway attachments, skill/plugin content, memory context, cron context, and @-referenced context by implementing provenance/taint propagation, hard context-promotion boundaries, and deterministic action-authority gating.
```

## Execution pattern expected from Hermes

Hermes should work in this order:

1. Run the hygiene gate from the master prompt.
2. Verify the existing patch stack and docs before changing behavior.
3. Delegate `subagents/01_SCOPE_SECURITY_MODEL.md` and record the security model.
4. Delegate `subagents/02_SURFACE_RECONNAISSANCE.md` and update the surface map.
5. Implement the safe-fetch completeness work only where gaps remain.
6. Implement artifact provenance and taint propagation.
7. Harden all context-promotion surfaces.
8. Implement deterministic action-authority gating before side-effecting tools.
9. Harden skill/plugin/hub behavior.
10. Add adversarial end-to-end tests proving hostile content cannot cause side effects.
11. Refresh and validate the patch stack from a clean upstream worktree.

## Expected final Hermes output

The final answer from Hermes should include:

- changed files grouped by workstream
- security invariant implemented in code
- test commands run and pass/fail results
- patch-stack refresh status
- remaining known risks, if any
- exact surfaces intentionally left out, with justification

## Important constraints

- Do not treat prompt fencing as a hard boundary.
- Do not rely solely on regex scanning.
- Do not make LLM Guard or any new heavy dependency mandatory unless explicitly justified.
- Do not touch unrelated local work, especially unrelated frontend lockfile changes.
- Do not use `npm install` without explicit user authorization.
- Do not commit unless the user explicitly asks.
