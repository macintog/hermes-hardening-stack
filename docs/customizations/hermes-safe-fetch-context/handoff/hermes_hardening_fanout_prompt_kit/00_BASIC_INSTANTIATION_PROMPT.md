Use my connected GitHub repository `macintog/hermes-hardening-stack` as the source of truth. This is a downstream patch-stack repo for Hermes Agent hardening. The goal of this session is to complete the hostile-download prompt-injection hardening methodology in one integrated pass.

Security objective:
Hostile downloaded, extracted, recalled, plugin-provided, skill-provided, browser-provided, OCR/PDF/document/transcript-derived, gateway-attachment-derived, or other tool-derived content may be used only as untrusted evidence. It must not authorize side effects, credentialed actions, persistence, secret access, outbound messages, tool execution, code execution, config changes, cron/memory writes, or downstream tool arguments unless there is trusted, scoped user/system/developer authorization.

Process:
1. Read the repo root README, `patches/hermes-safe-fetch-context/series`, `manifest.yaml`, `base.ref`, all five patch files, all docs under `docs/customizations/hermes-safe-fetch-context/`, the verifier script, and verification logs if present.
2. Treat the executable stack as canonical. The current stack is five patches: 0001 context safety, 0002 safe HTTP/gateway downloads, 0003 customization tooling, 0004 provenance/action authority, and 0005 tool-result promotion/action registry. Do not drop 0005.
3. Fan out subagents using the prompts in this package. Use subagents for threat model/invariants, structured taint, tool metadata/action registry, tool-result promotion, safe HTTP/parser risk, persistence/skills/plugins, adversarial tests, docs/manifest/verifier/CI, integration, and red-team review.
4. Integrate the results into a coherent implementation. Prefer updating existing topical patches when feasible; if the change is too large or cross-cutting, add a clearly named new patch and update `series`, `manifest.yaml`, docs, verifier, and refresh commands consistently.
5. Run or update the clean-stack verifier and targeted tests. Add tests when a security invariant lacks deterministic coverage.
6. Produce final outputs: changed files or patch bundle, updated docs, verification summary, risk register, and any residual issues.

Hard requirements:
- Do not present regex prompt-injection detection or textual fences as the security boundary.
- Carry non-textual taint/provenance through the agent loop, or implement the closest viable deterministic equivalent.
- When untrusted content influenced a turn, side-effecting tools require trusted scoped authorization.
- Tool metadata must be explicit and fail closed for unknown side effects.
- All model-visible string tool outputs should be untrusted by default unless the registry explicitly marks them as trusted internal control output.
- Persisted data derived from untrusted content must remain tainted when recalled.
- Skill/plugin execution, inline shell expansion, memory writes, cron changes, outbound messages, browser credentialed actions, and secret access must be gated.
- Update docs/playbooks so a future maintainer cannot silently drop any mandatory hardening phase.

Operate in one session. Avoid asking for clarification unless a write action requires external credentials or approval. Make a best effort and clearly label anything not completed.
