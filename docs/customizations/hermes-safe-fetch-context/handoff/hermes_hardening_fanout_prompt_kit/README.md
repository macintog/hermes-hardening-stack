# Hermes hostile-download prompt-injection hardening fan-out kit

This package is a prompt kit for a fresh Hermes / GPT-5.5-medium session that can use subagents and the connected GitHub repository `macintog/hermes-hardening-stack`.

The goal is to complete the hardening methodology, not merely fix documentation drift. The desired security outcome is:

> Hostile downloaded or tool-derived content may be analyzed as evidence, but it cannot authorize side effects, credentialed actions, persistence, secret access, tool execution, code execution, or downstream tool arguments without trusted, scoped user/system/developer authorization.

Use the files in this package as follows:

1. Paste `00_BASIC_INSTANTIATION_PROMPT.md` into a fresh Hermes / GPT-5.5-medium session.
2. Have the orchestrator read `01_ORCHESTRATOR_PROMPT.md`.
3. Fan out the prompts in `subagent_prompts/` to subagents.
4. Merge outputs using `templates/subagent_report_template.md` and `templates/risk_register_template.md`.
5. Run the implementation, verification, and red-team review phases before producing the final patch-stack/docs/test output.

The kit assumes the current patch stack is five patches:

- `0001-context-safety-core.patch`
- `0002-safe-http-gateway-download-hardening.patch`
- `0003-customization-maintenance-tool.patch`
- `0004-provenance-action-authority-hardening.patch`
- `0005-tool-result-promotion-action-registry.patch`

Do not let any subagent or playbook path drop patch `0005`.

## Source-of-truth files to read first

From `macintog/hermes-hardening-stack`:

- `README.md`
- `patches/hermes-safe-fetch-context/series`
- `patches/hermes-safe-fetch-context/manifest.yaml`
- `patches/hermes-safe-fetch-context/base.ref`
- all patch files in `patches/hermes-safe-fetch-context/`
- `docs/customizations/hermes-safe-fetch-context/README.md`
- `docs/customizations/hermes-safe-fetch-context/INTENT.md`
- `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
- `docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md`
- `scripts/verify-hermes-safe-fetch-context-stack.sh`
- `verification-output/*.log`, if present

## Desired final deliverables from the fresh session

The fresh session should produce, at minimum:

- updated patch stack and/or a new patch with consistent `series` and `manifest.yaml`;
- updated docs: README, intent, surface map, rebase playbook, hardening inventory;
- new or updated tests for structured taint, tool metadata, promotion policy, persistence taint, safe fetch edge cases, and end-to-end hostile-download hijack scenarios;
- updated verifier and CI/drift checks;
- a final risk register that clearly separates fixed issues from residual risks;
- a final zip or patch bundle suitable for review.

## Non-negotiable security stance

Prompt-injection detection and textual fencing are useful but are not security boundaries. The security boundary must be deterministic policy at promotion, persistence, and tool-dispatch boundaries. Unknown or unclassified tool behavior should fail closed for side effects, especially after untrusted content has influenced the turn.
