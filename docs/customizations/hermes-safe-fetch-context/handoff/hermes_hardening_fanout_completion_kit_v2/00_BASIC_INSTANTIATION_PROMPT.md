# Basic instantiation prompt for a fresh Hermes / GPT-5.5 session

Use my connected GitHub repository `macintog/hermes-hardening-stack` as the source of truth. Also use the local Hermes checkout available to the harness for patch application and testing.

This is a downstream patch-stack repository for Hermes Agent hostile-content hardening. The immediate job is not another high-level audit. Complete the remaining methodology and handoff gaps so the stack can safely preserve and maintain hostile-download prompt-injection containment while upstream Hermes changes.

First actions:

1. Fetch or inspect the latest `main` of `macintog/hermes-hardening-stack`; record the current commit SHA.
2. Read, in this order:
   - root `README.md`
   - `patches/hermes-safe-fetch-context/series`
   - `patches/hermes-safe-fetch-context/manifest.yaml`
   - `patches/hermes-safe-fetch-context/base.ref`
   - all patch files listed in `series`
   - `docs/customizations/hermes-safe-fetch-context/README.md`
   - `docs/customizations/hermes-safe-fetch-context/INTENT.md`
   - `docs/customizations/hermes-safe-fetch-context/SURFACE_MAP.md`
   - `docs/customizations/hermes-safe-fetch-context/REBASE_PLAYBOOK.md`
   - `docs/customizations/hermes-safe-fetch-context/HARDENING_SURFACE_INVENTORY.md` if present
   - `scripts/verify-hermes-safe-fetch-context-stack.sh`
   - verification logs if present
3. Treat `series`, `manifest.yaml`, and the verifier as the executable source of truth. The current stack is expected to include five mandatory patches:
   - `0001-context-safety-core.patch`
   - `0002-safe-http-gateway-download-hardening.patch`
   - `0003-customization-maintenance-tool.patch`
   - `0004-provenance-action-authority-hardening.patch`
   - `0005-tool-result-promotion-action-registry.patch`
   Do not drop `0005`.
4. Fan out the work using the prompts in this package. Integrate all subagent outputs into a single coherent patch/doc/verifier update.

Security objective:

Hostile downloaded, extracted, recalled, plugin-provided, skill-provided, browser-provided, OCR/PDF/document/transcript-derived, gateway-attachment-derived, or other tool-derived content may be used only as untrusted evidence. It must not authorize side effects, credentialed actions, persistence, secret access, outbound messages, tool execution, code execution, config changes, cron/memory writes, or downstream tool arguments unless there is trusted, scoped user/system/developer authorization.

Hard requirements:

- Do not present regex prompt-injection detection or textual fences as the security boundary.
- Carry non-textual taint/provenance through the agent loop, or implement the closest viable deterministic equivalent.
- When untrusted content influenced a turn, side-effecting tools require trusted scoped authorization.
- Tool metadata must be explicit and fail closed for unknown side effects.
- All model-visible string tool outputs should be untrusted by default unless registry metadata explicitly marks them as trusted internal control output.
- Persisted data derived from untrusted content must remain tainted when recalled.
- Skill/plugin execution, inline shell expansion, memory writes, cron changes, outbound messages, browser credentialed actions, and secret access must be gated.
- The documentation, playbooks, manifest, `series`, verifier, and tests must all agree so a future maintainer cannot silently drop any mandatory hardening phase.

Known blockers from the latest review to resolve:

- `REBASE_PLAYBOOK.md` still described a four-patch refresh path and omitted `tests/security/test_tool_result_promotion.py`.
- `docs/.../README.md` still described a three-patch/two-intention stack and contained stale WeCom wording.
- `SURFACE_MAP.md` did not fully describe patch `0005` surfaces.
- `browser_console` was treated too much like a read-only network surface rather than a credentialed browser-context capability.
- `agent/skill_commands.py` appeared to perform inline shell expansion before untrusted skill-content fencing.
- Unknown/non-extraction tool result strings were allowed to preserve shape instead of defaulting to untrusted evidence.
- Turn/session taint still appeared partly text-based rather than structurally carried.
- Verification logs/docs contained local path noise and did not enforce doc/manifest/playbook drift strongly enough.

Process constraints:

- Operate in one session. Avoid clarification unless a write action requires external credentials or approval.
- Make changes in the patch-stack repo and the Hermes checkout as needed to regenerate patches.
- Prefer updating existing topical patches when feasible. If the implementation becomes too large or cross-cutting, add a new clearly named patch and update `series`, `manifest.yaml`, docs, verifier, and refresh commands consistently.
- Run the clean-stack verifier against the recorded base and, if feasible, against `origin/main`.
- Add or update deterministic tests for every security invariant touched.
- Produce final outputs as a zip file containing changed files or patch bundle, updated docs, verification summary, risk register, and residual issues.

Acceptance bar:

The final state must be safe as a maintainer handoff artifact, not merely a passing patch replay. A future maintainer following the docs should preserve all mandatory hardening phases, including tool-result promotion and action-registry hardening.
